class CreateStylesTable < ActiveRecord::Migration
  def self.up
    create_table :styles do |t|
      t.string :name,     :null => false
      t.text   :classes,  :null => false
      t.text   :rules,    :null => false
      t.timestamps
    end
    create_table :layers_styles, :id => false do |t|
      t.integer :layer_id, :null => false
      t.integer :style_id, :null => false
    end
  end

  def self.down
    drop_table :styles
    drop_table :layers_styles
  end
end

