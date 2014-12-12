class CreateLayersTable < ActiveRecord::Migration
  def self.up
    create_table :layers do |t|
      t.string :name,         :null => false
      t.text   :description
      t.string :table,        :null => false
      t.string :shape_column
      t.string :index
      t.date   :published
      t.text   :properties
      t.string :base_layer_id
    end    
  end

  def self.down
    drop_table :layers
  end
end

