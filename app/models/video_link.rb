# frozen_string_literal: true

class VideoLink < ApplicationRecord
  belongs_to :collection, inverse_of: :video_links
  validates :link, presence: { message: "Video links must have a link" }
  validates :collection, presence: true
end
