# frozen_string_literal: true
class CatalogController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog
  before_action :setup_negative_captcha, only: [:email]

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10,
      :"hl" => true,
      :"hl.fl" => "title_t geographic_subject_t temporal_subject_t collection_t ",
      :"hl.simple.pre" => "<span class='label label-warning'>",
      :"hl.simple.post" => "</span>",
      :"hl.fragsize" => 200,
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
     #  qt: 'document',
     ## These are hard-coded in the blacklight 'document' requestHandler
     # fl: '*',
     # rows: 1,
     # q: '{!term f=id v=$id}'
      :"hl" => true,
      :"hl.fragsize" => 0,
      :"hl.preserveMulti" => true,
      :"hl.fl" => "file_name_t collection_t series_title_t genre_t subject_topic_t geographic_subject_t temporal_subject_t title_t extent_t creation_production_credits_t conservation_t copyright_status_t date_created_t creator_t note_license_t note_rights_t subseries_title_t language_t",
      :"hl.simple.pre" => "<span class='label label-warning'>",
      :"hl.simple.post" => "</span>",
      :"hl.alternateField" => "dd"
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'
    #config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    config.show.title_field = 'title_display'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    config.add_facet_field 'collection_t', label: 'Collection', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'series_facet', label: 'Series', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'genre_facet', label: 'Genre', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'geographic_subject_facet', label: 'Location', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'temporal_subject_facet', label: 'Time Period', limit: 20, index_range: 'A'..'Z'

#    config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
#       :years_5 => { label: 'within 5 Years', fq: "pub_date:[#{Time.zone.now.year - 5 } TO *]" },
#       :years_10 => { label: 'within 10 Years', fq: "pub_date:[#{Time.zone.now.year - 10 } TO *]" },
#       :years_25 => { label: 'within 25 Years', fq: "pub_date:[#{Time.zone.now.year - 25 } TO *]" }
#    }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results and bookmarks) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_t', label: 'Description', highlight: true, solr_params: { :"hl.alternateField" => "dd" }
    config.add_index_field 'geographic_subject_t', label: 'Location', highlight: true, solr_params: { :"hl.alternateField" => "dd", :"hl.highlightAlternate" => true }
    config.add_index_field 'temporal_subject_t', label: 'Time Period', highlight: true, solr_params: { :"hl.alternateField" => "dd", :"hl.highlightAlternate" => true }
    config.add_index_field 'collection_t', label: 'Collection', highlight: true, solr_params: { :"hl.alternateField" => "dd", :"hl.highlightAlternate" => true }

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_t', label: 'Description', highlight: true
    config.add_show_field 'extent_t', label: 'Physical Description', highlight: true
    config.add_show_field 'creation_production_credits_t', label: 'Photographer', highlight: true
    config.add_show_field 'creator_t', label: 'Author', highlight: true
    config.add_show_field 'date_created_t', label: 'Date Created', highlight: true
    config.add_show_field 'language_t', label: 'Language', highlight: true
    config.add_show_field 'collection_t', label: 'Collection', highlight: true
    config.add_show_field 'series_title_t', label: 'Series', highlight: true
    config.add_show_field 'subseries_title_t', label: 'Subseries', highlight: true
    config.add_show_field 'geographic_subject_t', label: 'Location', highlight: true
    config.add_show_field 'temporal_subject_t', label: 'Time Period', highlight: true
    config.add_show_field 'subject_topic_t', label: 'Topic', highlight: true
    config.add_show_field 'genre_t', label: 'Genre', highlight: true
    config.add_show_field 'conservation_t', label: 'Conservation Note', highlight: true
    config.add_show_field 'copyright_status_t', label: 'Copyright Status', highlight: true
    config.add_show_field 'note_license_t', label: 'Creative Commons License', highlight: true
    config.add_show_field 'note_rights_t', label: 'Rights Statement', highlight: true
    config.add_show_field 'file_name_t', label: 'Local ID', highlight: true
    config.add_show_field 'project_history_t', label: 'Project History'
    config.add_show_field 'notes_funding_t', label: 'Funding Agency'
    # config.add_show_field 'resource_preview_t', label: 'Image preview url'
    config.add_show_field 'resource_url_t', label: 'Resource url'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    # config.add_search_field('author') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #   field.solr_local_parameters = {
    #     qf: '$author_qf',
    #     pf: '$author_pf'
    #   }
    # end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
      }
    end


    # config.add_search_field('biographical') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'biographical' }
    #   field.solr_local_parameters = {
    #     qf: '$biographical_qf',
    #     pf: '$biographical_pf'
    #   }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_sort asc', label: 'Relevance'
    config.add_sort_field 'collection_sort asc, title_sort asc', label: 'Collection'
    config.add_sort_field 'date_created_sort asc, title_sort asc', label: 'Date Created'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = false
    # config.autocomplete_path = 'suggest'

    config.add_field_configuration_to_solr_request!

  end

  # Override to add highlighing to show
  def show
    @response, @document = fetch params[:id], {
      :"hl.q" => current_search_session.try(:query_params).try(:[], "q"),
      :df => blacklight_config.try(:default_document_solr_params).try(:[], :"hl.fl")
    }
    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

  # override from blacklight 6.12 to handle captcha
  def email
    @response, @documents = action_documents

    if request.post? && validate_email_params
      email_action(@documents)
      flash[:success] ||= I18n.t("blacklight.email.success", default: nil)

      respond_to do |format|
        format.html do
          return render "email_success", layout: false if request.xhr?
          redirect_to action_success_redirect_path
        end
      end
    else
      respond_to do |format|
        format.html do
          return render layout: false if request.xhr?
          # Otherwise draw the full page
        end
      end
    end
  end

  private
  def setup_negative_captcha
    @captcha = NegativeCaptcha.new(
      # A secret key entered in environment.rb. 'rake secret' will give you a good one.
      secret: ENV["NEGATIVE_CAPTCHA_SECRET"],
      spinner: request.remote_ip,
      # Whatever fields are in your form
      fields: [:to, :message],
      # If you wish to override the default CSS styles (position: absolute; left: -2000px;) used to position the fields off-screen
      # css: "display: none",
      params: params
    )
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email_action documents
    mail = RecordMailer.email_record(documents, {:to => @captcha.values[:to], :message => @captcha.values[:message]}, url_options)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  def validate_email_params
    if !@captcha.valid?
      flash[:error] = @captcha.message
    elsif @captcha.values[:to].blank?
      flash[:error] = I18n.t('blacklight.email.errors.to.blank')
    elsif !@captcha.values[:to].match(Blacklight::Engine.config.email_regexp)
      flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => @captcha.values[:to])
    end

    flash[:error].blank?
  end
end
