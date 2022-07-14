# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  subject { described_class.new(title: "Collection Title") }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without a title" do
    collection = Collection.new(title: nil)
    expect(collection).not_to be_valid
  end

  describe "Associations" do
    it { is_expected.to have_many(:gac_embeds) }
    it { is_expected.to have_many(:video_links) }
  end
end
