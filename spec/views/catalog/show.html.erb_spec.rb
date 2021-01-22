# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/show.html.erb' do
  include BlacklightHelper
  include CatalogHelper

  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.add_show_field 'resource_url_t', label: 'Resource url'
    end
  end
  let(:document) { SolrDocument.new id: 'anen_123', resource_url_t: 'anen_123.pdf' }

  before do
    assign :document, document
    without_partial_double_verification do
      allow(view).to receive(:blacklight_config).and_return blacklight_config
    end
  end

  it 'renders the pdf link' do
    render partial: 'catalog/pdf_link', locals: { document: document }
    expect(rendered).to include('View PDF:')
  end
end
