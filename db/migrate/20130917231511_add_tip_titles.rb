class AddTipTitles < ActiveRecord::Migration
  def self.up
    add_column :tips, :title, :string
  end

  def self.down
    remove_column :tips, :title
  end
end
