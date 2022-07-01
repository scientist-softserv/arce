# frozen_string_literal: true

class GacEmbed < ApplicationRecord
  belongs_to :collection, inverse_of: :gac_embeds
  validates :embed, presence: { message: "Google Arts and Culture items must have an embed link" }
  validates :collection, presence: true
end
