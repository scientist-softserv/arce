class AddBannerImageToCollection < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :banner_image, :string
  end
end
