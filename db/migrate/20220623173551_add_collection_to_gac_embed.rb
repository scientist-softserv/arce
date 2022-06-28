class AddCollectionToGacEmbed < ActiveRecord::Migration[5.1]
  def change
    add_column :gac_embeds, :collection_id, :integer
  end
end
