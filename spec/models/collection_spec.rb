# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  it "validates the title" do
    collection = Collection.create
    p collection.errors[:title]
    expect(collection.errors[:title]).not_to be_empty
  end
end
