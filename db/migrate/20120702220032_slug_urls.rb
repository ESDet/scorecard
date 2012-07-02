class SlugUrls < ActiveRecord::Migration
  def self.up
    add_column :schools, :slug, :string
#    School.find_each do |s|
#      s.update_attribute(:slug, nil)
#    end
  end

  def self.down
    remove_column :schools, :slug
  end
end
