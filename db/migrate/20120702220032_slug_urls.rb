class SlugUrls < ActiveRecord::Migration
  def self.up
    add_column :schools, :slug, :string
    School.find_each do |s|
      s.set_slug
      puts "Setting #{s.name} to #{s.slug}"
      s.save
    end
  end

  def self.down
    remove_column :schools, :slug
  end
end
