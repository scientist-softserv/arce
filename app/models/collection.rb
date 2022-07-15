# frozen_string_literal: true

class Collection < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_many :gac_embeds, inverse_of: :collection, dependent: :destroy
  has_many :video_links, inverse_of: :collection, dependent: :destroy

  accepts_nested_attributes_for :gac_embeds, allow_destroy: true, reject_if: ->(attrs) { attrs['embed'].blank? }
  accepts_nested_attributes_for :video_links, allow_destroy: true, reject_if: ->(attrs) { attrs['link'].blank? }

  mount_uploader :image, ImageUploader

  validates :title, presence: true
end
