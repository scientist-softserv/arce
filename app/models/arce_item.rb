require 'nokogiri'
require 'net/http'

class ArceItem
  attr_accessor :attributes, :new_record, :should_process_pdf_transcripts

  def initialize(attr={})
    if attr.is_a?(Hash)
      @attributes = attr.with_indifferent_access
    else
      @attributes = attr.to_h.with_indifferent_access
    end
  end

  def self.index_logger
    logger           = ActiveSupport::Logger.new(Rails.root.join('log', "indexing.log"))
    logger.formatter = Logger::Formatter.new
    @@index_logger ||= ActiveSupport::TaggedLogging.new(logger)
  end

  def self.client(args)
    url = args[:url] || "https://dl.library.ucla.edu/oai2/"
    OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'rexml', metadata_prefix: 'mods', verb: 'ListRecords'
  end

  def self.fetch(args)
    set = args[:set] || "arce_1"
    response = client(args).list_records(set: set, metadata_prefix: 'mods')
  end

  def self.get(args)
    response = client(args).get_record(identifier: args[:identifier], metadata_prefix: 'mods', )
  end

  def self.fetch_first_id
    response = self.fetch({progress: false, limit:1})
    response.full&.first&.header&.identifier&.split(':')&.last
  end

  def self.import(args)
    return false if !args[:override] && check_for_tmp_file
    begin
      create_import_tmp_file
      progress = args[:progress] || true
      limit = args[:limit] || 20000000  # essentially no limit
      response = self.fetch(args)
      if progress
        bar = ProgressBar.new(response.doc.elements['//resumptionToken'].attributes['completeListSize'].to_i)
      end
      total = 0
      new_record_ids = []

      response.full.each do |record|
        begin
          history = process_record(record)
          history.index_record
          if history.id
            new_record_ids << history.id
          else
            ArceItem.index_logger.info("ID is nil for #{history.inspect}")
          end
        rescue => exception
          Raven.capture_exception(exception)
          ArceItem.index_logger.error("#{exception.message}\n#{exception.backtrace}")
        end
        if true
          yield(total) if block_given?
        end

        if progress
          bar.increment!
        end
        total += 1
        break if total >= limit
      end
      # Hard commit now that we are done adding items, before we remove anything
      SolrService.commit
      # verify there is no limit argument which would allow deletion of all records after the limit
      if args[:delete]
        remove_deleted_records(new_record_ids)
      end
      return total
    rescue => exception
      Raven.capture_exception(exception)
      ArceItem.index_logger.error("#{exception.message}\n#{exception.backtrace}")
    ensure
      remove_import_tmp_file
    end
  end

  def self.import_single(id)
    record = self.get(identifier: id)&.record
    history = process_record(record)
    history.index_record
    return history
  rescue => exception
    Raven.capture_exception(exception)
    ArceItem.index_logger.error("#{exception.message}\n#{exception.backtrace}")
  end

  def self.process_record(record)
    if record.header.blank? || record.header.identifier.blank?
      return false
    end

    history = ArceItem.find_or_new(record.header.identifier.split(':').last) #Digest::MD5.hexdigest(record.header.identifier).to_i(16))
    history.attributes['id_t'] = record.header.identifier.split(':').last
    if record.header.datestamp
      history.attributes[:timestamp] = Time.parse(record.header.datestamp)
    end
    if record.metadata
      record.metadata.children.each do |batch|
        next if batch.class == REXML::Text
        batch.children.each do |child|
          next if child.class == REXML::Text
          if child.attributes['displayLabel']  == 'File name'
            file_name = child.text
            history.attributes['file_name_t'] ||= []
            if !history.attributes['file_name_t'].include?(file_name)
              history.attributes['file_name_t'] << file_name
            end
          end
          if child.name == 'identifier'
            if child.attributes['type'] == 'local'
              if child.attributes['displayLabel'] == "Local ID"
                child.children.each do |ch|
                  next if ch.class == REXML::Text
                  file_name = ch.text
                  history.attributes['file_name_t'] ||= []
                  if !history.attributes['file_name_t'].include?(file_name)
                    history.attributes['file_name_t'] << file_name
                  end
                end
              end
            end
          end
          if child.name == 'relatedItem'
            if child.attributes['type'] == 'host'
              child.children.each do |ch|
                next if ch.class == REXML::Text
                ch.children.each do |c|
                  next if c.class == REXML::Text
                  if c.name == 'title'
                    history.attributes['collection_display'] ||= c.text
                    history.attributes['collection_facet'] ||= c.text
                    history.attributes['collection_sort'] ||= c.text
                    history.attributes['collection_t'] ||= c.text
                  end
                end
              end
            end
            if child.attributes['type'] == 'program'
              child.children.each do |ch|
                next if ch.class == REXML::Text
                ch.children.each do |c|
                  next if c.class == REXML::Text
                  if c.name == 'title'
                    history.attributes['program_title_display'] ||= c.text
                    history.attributes['program_title_t'] ||= c.text
                  end
                end
              end
            end
            if child.attributes['type'] == 'series'
              child.children.each do |ch|
                next if ch.class == REXML::Text
                ch.children.each do |c|
                  next if c.class == REXML::Text
                  if c.name == 'title'
                    history.attributes['series_title_display'] ||= c.text
                    history.attributes['series_facet'] ||= c.text
                    history.attributes['series_title_t'] ||= c.text
                  end
                end
              end
            end
            # subseries is not in feed yet, may need updating
            # relatedItem type="subseries"
            if child.attributes['type'] == 'subseries'
              child.children.each do |ch|
                next if ch.class == REXML::Text
                ch.children.each do |c|
                  next if c.class == REXML::Text
                  if c.name == 'title'
                    history.attributes['subseries_title_display'] ||= c.text
                    history.attributes['subseries_title_t'] ||= c.text
                  end
                end
              end
            end
          end
          if child.name == 'typeOfResource'
            type_of_resource = child.text
            history.attributes['type_of_resource_t'] ||= []
            if !history.attributes['type_of_resource_t'].include?(type_of_resource)
              history.attributes['type_of_resource_t'] << type_of_resource
            end
          end
          if child.name == 'genre'
            genre = child.text
            history.attributes['genre_t'] ||= []
            if !history.attributes['genre_t'].include?(genre)
              history.attributes['genre_t'] << genre
            end
            history.attributes['genre_facet'] ||= []
            if !history.attributes['genre_facet'].include?(genre)
              history.attributes['genre_facet'] << genre
            end
          end
          if child.name == 'subject'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              if ch.name == 'topic'
                topic = ch.text.to_s.strip
                next if topic.empty?
                history.attributes['subject_topic_facet'] ||= []
                if !history.attributes['subject_topic_facet'].include?(topic)
                  history.attributes['subject_topic_facet'] << topic
                end
                history.attributes['subject_topic_t'] ||= []
                if !history.attributes['subject_topic_t'].include?(topic)
                  history.attributes['subject_topic_t'] << topic
                end
              end
              if ch.name == 'name'
                topic = ch.text.to_s.strip
                ch.children.each do |c|
                  next if c.class == REXML::Text
                  if c.name == 'namePart'
                    topic = c.text.to_s.strip
                    next if topic.empty?
                    history.attributes['subject_topic_facet'] ||= [] unless history.attributes['subject_topic_facet'].present?
                    if !history.attributes['subject_topic_facet'].include?(topic)
                      history.attributes['subject_topic_facet'] << topic
                    end
                    history.attributes['subject_topic_t'] ||= [] unless history.attributes['subject_topic_t'].present?
                    if !history.attributes['subject_topic_t'].include?(topic)
                      history.attributes['subject_topic_t'] << topic
                    end
                  end
                end
              end
              if ch.name == 'temporal'
                temporal = ch.text
                history.attributes['temporal_subject_t'] ||= []
                if !history.attributes['temporal_subject_t'].include?(temporal)
                  history.attributes['temporal_subject_t'] << temporal
                end
                history.attributes['temporal_subject_facet'] ||= []
                if !history.attributes['temporal_subject_facet'].include?(temporal)
                  history.attributes['temporal_subject_facet'] << temporal
                end
              end
              if ch.name == 'geographic'
                geographic = ch.text
                history.attributes['geographic_subject_t'] ||= []
                if !history.attributes['geographic_subject_t'].include?(geographic)
                  history.attributes['geographic_subject_t'] << ch.text
                end
                history.attributes['geographic_subject_facet'] ||= []
                if !history.attributes['geographic_subject_facet'].include?(geographic)
                  history.attributes['geographic_subject_facet'] << ch.text
                end
              end
            end
          end
          if child.name == 'titleInfo'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              title_text = ch.text.to_s.strip
              a = title_text =~ /\p{Arabic}/
              next if !a.nil?
              history.attributes["title_t"] ||= []
              if !history.attributes["title_t"].include?(title_text)
                history.attributes["title_t"] << title_text
              end
              history.attributes["title_display"] ||= []
              if !history.attributes["title_display"].include?(title_text)
                history.attributes["title_display"] << title_text
              end
            end
          end
          if child.name == 'name'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              if ch.name == 'namePart'
                creator = ch.text.to_s.strip
                next if creator.empty?
                history.attributes['creator_t'] ||= []
                unless history.attributes['creator_t'].include?(creator)
                  history.attributes['creator_t'] << creator
                end
              end
            end
          end
          if child.name == 'physicalDescription'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              extent = ch.text
              history.attributes['extent_t'] ||= []
              if !history.attributes['extent_t'].include?(extent)
                history.attributes['extent_t'] << extent
              end
            end
          end
          if child.name == 'note'
            if child.attributes['type'] == 'statementofresponsibility'
              history.attributes['project_history_t'] = child.text
            end
            if child.attributes['type'] == 'creation_production_credits'
              history.attributes['creation_production_credits_t'] = child.text
            end
            if child.attributes['type'] == 'conservation'
              history.attributes['conservation_t'] = child.text
            end
            if child.attributes['type'] == 'funding'
              history.attributes['note_funding_t'] = child.text
            end
            if child.attributes['type'] == 'related'
              history.attributes['related_t'] = child.text
            end
            if child.attributes['type'] == 'references'
              history.attributes['references_t'] = child.text
            end
          end
          # not in feed yet so this will probably need updating
          if child.name == 'language'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              if ch.name == 'languageTerm' && ch.attributes['type'] == 'text'
                history.attributes['language_t'] = ch.text
              end
            end
          end
          if child.name == 'accessCondition'
            if child.attributes['type'] == 'use and reproduction'
              if child.attributes['displayLabel'] == 'rightsUri'
                history.attributes['rights_t'] = child.text
              else
                history.attributes['note_license_t'] = child.text
              end
            end
            if child.attributes['type'] == 'local rights statements'
              history.attributes['note_rights_t'] = child.text
            end
            child.children.each do |ch|
              next if ch.class == REXML::Text
              history.attributes['copyright_status_t'] = ch.attributes['copyright.status']
              history.attributes['publication_status_t'] = ch.attributes['publication.status']
            end
          end
          if child.name == 'originInfo'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              if ch.attributes.empty? then
                history.attributes['date_created_t'] ||= ch.text
              elsif ch.attributes['point'].present? then
                if ch.attributes['point'] == 'start'
                  history.attributes['date_created_t'] ||= ch.text
                  date = Date.parse(ch.text) rescue nil
                  if date
                    history.attributes['date_created_sort'] ||= date
                  end
                end
              elsif ch.attributes['encoding'].present? then
                history.attributes['date_created_t'] ||= ch.text
                date = Date.parse(ch.text) rescue nil
                if date
                  history.attributes['date_created_sort'] ||= date
                end
              end
            end
          end
          if child.name == 'location'
            child.children.each do |ch|
              next if ch.class == REXML::Text
              if ch.name == 'physicalLocation'
                history.attributes['repository_t'] = ch.text
              end
              if ch.name == 'url'
                if ch.attributes['access'] == 'preview'
                  history.attributes['resource_preview_t'] = ch.text
                end
                if ch.attributes['access'] == 'raw object'
                  history.attributes['resource_url_t'] = ch.text
                end
              end
            end
          end
        end
      end
    end
    return history
  end

  def new_record?
    self.attributes.is_a?(Hash)
  end

  def id
    self.attributes[:id]
  end

  def id=(value)
    self.attributes[:id] = value
  end

  def should_process_pdf_transcripts
    @should_process_pdf_transcripts ||= false
    @should_process_pdf_transcripts && !Delayed::Job.where("handler LIKE ? ", "%job_class: IndexPdfTranscriptJob%#{self.id}%").first
  end

  def to_solr
    attributes
  end

  def index_record
    SolrService.add(self.to_solr)
    #TODO allow for search capturing
    SolrService.commit
  end

  def remove_from_index
    SolrService.delete_by_id(self.id)
    SolrService.commit
  end

  def self.remove_deleted_records(new_record_ids)
    current_records = all_ids
    new_record_ids.each do |id|
      current_records.delete(id)
    end
    if current_records.present?
      current_records.each do |id|
        SolrService.delete_by_id(id)
        SolrService.commit
      end
    end
  end

  def self.all_ids
    @all_ids ||= SolrService.all_ids
  end

  def self.find(id)
    ArceItem.new(SolrDocument.find(id))
  end

  def self.find_or_new(id)
    self.find(id)
  rescue Blacklight::Exceptions::RecordNotFound
    ArceItem.new(id: id)
  end

  def self.generate_transcript(url)
    tmpl = Nokogiri::XSLT(File.read('public/convert.xslt'))
    resp = Net::HTTP.get(URI(url))

    document = Nokogiri::XML(resp)

    tmpl.transform(document).to_xml
  end

  def self.total_records(args = {})
    url = args[:url] || "https://dl.library.ucla.edu/oai2/"
    set = args[:set] || "arce_1"
    client = OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'rexml', metadata_prefix: 'mods'
    response = client.list_records(set: set, metadata_prefix: 'mods')
    response.doc.elements['//resumptionToken'].attributes['completeListSize'].to_i
  end

  def self.create_import_tmp_file
    FileUtils.touch(Rails.root.join('tmp/importer.tmp'))
  end

  def self.remove_import_tmp_file
    FileUtils.rm(Rails.root.join('tmp/importer.tmp'))
  end

  def self.check_for_tmp_file
    File.exist?(File.join('tmp/importer.tmp'))
  end
end
