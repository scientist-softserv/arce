# frozen_string_literal: true

json.extract! collection,
              :id, :title, :content, :video_embed_link, :arts_and_culture_embed, :private, :created_at, :updated_at
json.url collection_url(collection, format: :json)
