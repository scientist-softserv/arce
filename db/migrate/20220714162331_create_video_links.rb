class CreateVideoLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :video_links do |t|
      t.string :title
      t.text :link
      t.integer :collection_id
      t.timestamps
    end
  end
end
