require 'rails_helper'

RSpec.describe 'pages/logo.html.erb', type: :view do

  include Capybara::RSpecMatchers
  
  before :each do
    render :partial => 'logo'
  end

  describe 'logo link' do
    it 'routes to homepage' do
      expect(rendered).to have_selector('a[href="https://www.arce.org/"]')
    end

    it 'has alt text for link' do
      expect(rendered).to have_selector('img[alt="ARCE Homepage"]')
    end

    it 'has expected styling' do
      expect(rendered).to have_selector('img[class="arce-logo"]')
    end
  end
end
