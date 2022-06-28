# frozen_string_literal: true

class Collection < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_many :gac_embeds, dependent: :destroy
  accepts_nested_attributes_for :gac_embeds, allow_destroy: true, reject_if: ->(attrs) { attrs['embed'].blank? }

  mount_uploader :image, ImageUploader

  validates :title, presence: true
end
