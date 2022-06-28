class CreateGacEmbeds < ActiveRecord::Migration[5.1]
  def change
    create_table :gac_embeds do |t|
      t.text :embed

      t.timestamps
    end
  end
end
