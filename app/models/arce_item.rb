require 'nokogiri'
require 'net/http'

class ArceItem
  attr_accessor :attributes, :new_record, :should_process_pdf_transcripts

  def initialize(attr={})
    if attr.is_a?(Hash)
      @attributes = attr.with_indifferent_access
    else
      @attributes = attr
    end
  end

  def self.client(args)
    url = args[:url] || "https://dl.library.ucla.edu/oai2/"
    OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'rexml', metadata_prefix: 'mods'
  end

  def self.fetch(args)
    set = args[:set] || "luxor_1"
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
          new_record_ids << history.id
        rescue => exception
          Raven.capture_exception(exception)
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
      #verify there is no limit argument which would allow deletion of all records after the limit
      if args[:limit] == 20000000
        remove_deleted_records(new_record_ids)
      end
      return total
    rescue => exception
      Raven.capture_exception(exception)
    ensure
      remove_import_tmp_file
    end
  end

  def self.import_single(id)
    record = self.get(identifier: id)&.record
    history = process_record(record)
    history.index_record
    return history
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
      record.metadata.children.each do |child|
        next if child.class == REXML::Text
        child.elements.each do |element|
          if element.name == 'title'
            title_text = element.text.to_s.strip
            if title_text.size > 0
              history.attributes["title_display"] ||= title_text
              history.attributes["title_t"] ||= []
              if !history.attributes["title_t"].include?(title_text)
                history.attributes["title_t"] << title_text
              end
            end
          end

          if element.name == 'subject'
            history.attributes["subject_topic_facet"] ||= []
            history.attributes["subject_topic_facet"] << element.text
            history.attributes["subject_t"] ||= []
            history.attributes["subject_t"] << element.text
          end

          if element.name == 'description'
            history.attributes["description_t"] ||= []
            history.attributes["description_t"] << element.text
          end

          if element.name == 'date'
            history.attributes["date_display"] = [element.text]
            history.attributes["date_t"] ||= []
            history.attributes["date_t"] << element.text
          end

          if element.name == 'type'
            history.attributes["type_of_resource_display"] = element.text
            history.attributes["type_of_resource_t"] ||= []
            history.attributes["type_of_resource_t"] << element.text
            history.attributes["type_of_resource_facet"] ||= []
            history.attributes["type_of_resource_facet"] << element.text
          end

          if element.name == 'format'
            history.attributes["extent_display"] = element.text
            history.attributes['extent_t'] = []
            history.attributes['extent_t'] << element.text
          end

          if element.name == 'identifier'
            history.attributes["identifier_display"] = [element.text]
            history.attributes["identifier_t"] ||= []
            history.attributes["identifier_t"] << element.text
          end

          if element.name == 'relation'
            history.attributes["relation_display"] = [element.text]
            history.attributes["relation_t"] ||= []
            history.attributes["relation_t"] << element.text
          end

          if element.name == 'coverage'
            history.attributes["coverage_display"] = [element.text]
            history.attributes["coverage_t"] ||= []
            history.attributes["coverage_t"] << element.text
          end

          if element.name == 'rights'
            history.attributes["rights_display"] = [element.text]
            history.attributes["rights_t"] ||= []
            history.attributes["rights_t"] << element.text
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
    return @all_ids if @all_ids.present?
    @all_ids ||= []
    SolrService.all_records do |record|
      @all_ids << record["id"]
    end
    @all_ids
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
    url = args[:url] || "http://digital2.library.ucla.edu/dldataprovider/oai2_0.do"
    set = args[:set] || "oralhistory"
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
