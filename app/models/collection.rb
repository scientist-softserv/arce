# frozen_string_literal: true

class Collection < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  mount_uploader :image, ImageUploader

  validates :title, presence: true
end
