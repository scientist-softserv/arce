module ApplicationHelper
  def split_multiple(options={})
    render 'shared/multiple', value: options[:value].uniq
  end

  def from_helper(attr, document)
    if document._source.present? && document._source[attr].present?
      document._source[attr].map do |child|
        JSON.parse(child)
      end
    end
  end

  def type_of_resource(document)
    document._source["type_of_resource_t"][0]
  end

  def resource_is_pdf?(document)
    document['resource_url_t'][0].include? '.pdf'
  end

  def external_link(options = {})
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

    link_to options[:value].first, options[:value].first, target: '_blank'
  end
end
