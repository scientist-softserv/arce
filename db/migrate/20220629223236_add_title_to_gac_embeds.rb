class AddTitleToGacEmbeds < ActiveRecord::Migration[5.1]
  def change
    add_column :gac_embeds, :title, :string
  end
end
