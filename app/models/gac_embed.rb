# frozen_string_literal: true

class GacEmbed < ApplicationRecord
  belongs_to :collection, optional: true
  validates :embed, presence: true
  validates :collection, presence: true
end
