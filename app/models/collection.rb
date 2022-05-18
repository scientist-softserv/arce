# frozen_string_literal: true

class Collection < ApplicationRecord
  validates :title, presence: true
end
