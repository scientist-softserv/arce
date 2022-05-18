class RenamePreviewToPrivate < ActiveRecord::Migration[5.1]
  def change
    rename_column :collections, :preview, :private
  end
end
