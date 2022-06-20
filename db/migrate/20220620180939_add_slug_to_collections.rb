class AddSlugToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :slug, :string
    add_index :collections, :slug, unique: true
  end
end
