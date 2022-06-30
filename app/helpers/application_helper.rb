# frozen_string_literal: true

module ApplicationHelper
  def split_multiple(options = {})
    render 'shared/multiple', value: options[:value].uniq
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

  def link_to_add_gac_fields(name, form, association)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render("gac_embed_fields", form: builder)
    end
    link_to(name, '#', class: "add_fields", data: { id: id, fields: fields.gsub("/n", "") })
  end
end
