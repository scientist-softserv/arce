# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VideoLink, type: :model do
  subject { described_class.new(link: "youtube link", title: "title", collection_id: collection.id) }

  let(:collection) { Collection.create!(title: "Test Collection") }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without an embed" do
    video = VideoLink.new(link: nil)
    expect(video).not_to be_valid
  end

  describe "Association" do
    it { is_expected.to belong_to(:collection).without_validating_presence }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:collection) }
  end
end
