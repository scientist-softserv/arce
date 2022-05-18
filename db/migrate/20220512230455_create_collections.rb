class CreateCollections < ActiveRecord::Migration[5.1]
  def change
    create_table :collections do |t|
      t.string :title
      t.text :content
      t.string :video_embed_link
      t.string :arts_and_culture_embed
      t.boolean :preview

      t.timestamps
    end
  end
end
