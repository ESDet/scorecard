# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130917231511) do

  create_table "districts", :options => "ENGINE=MyISAM DEFAULT CHARSET=utf8", :primary_key => "OGR_FID", :force => true do |t|
    t.spatial "SHAPE",      :limit => {:type=>"geometry"}, :null => false
    t.float   "area",       :limit => 20
    t.float   "perimeter",  :limit => 20
    t.float   "sn26_d00_"
    t.float   "sn26_d00_i"
    t.string  "state",      :limit => 2
    t.string  "sd_u",       :limit => 5
    t.string  "name",       :limit => 90
    t.string  "lsad",       :limit => 2
    t.string  "lsad_trans", :limit => 50
  end

  add_index "districts", ["OGR_FID"], :name => "OGR_FID", :unique => true
  add_index "districts", ["SHAPE"], :name => "SHAPE", :spatial => true

  create_table "geometry_columns", :options => "ENGINE=MyISAM DEFAULT CHARSET=utf8", :id => false, :force => true do |t|
    t.string  "F_TABLE_CATALOG",   :limit => 256
    t.string  "F_TABLE_SCHEMA",    :limit => 256
    t.string  "F_TABLE_NAME",      :limit => 256, :null => false
    t.string  "F_GEOMETRY_COLUMN", :limit => 256, :null => false
    t.integer "COORD_DIMENSION"
    t.integer "SRID"
    t.string  "TYPE",              :limit => 256, :null => false
  end

  create_table "schools", :options => "ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8", :force => true do |t|
    t.string  "bcode"
    t.string  "tid"
    t.string  "grade"
    t.string  "name"
    t.string  "school_type"
    t.string  "grades_served"
    t.integer "points"
    t.string  "address"
    t.string  "address2"
    t.string  "zip"
    t.spatial "centroid",            :limit => {:type=>"point"}
    t.string  "slug"
    t.boolean "k12"
    t.text    "basic"
    t.text    "profile"
    t.text    "esd_k8_2013"
    t.text    "esd_hs_2013"
    t.text    "meap_2012"
    t.text    "meap_2011"
    t.text    "meap_2010"
    t.text    "meap_2009"
    t.text    "act_2013"
    t.text    "fiveessentials_2013"
    t.text    "earlychild"
    t.text    "esd_k8_2013_r1"
    t.text    "esd_el_2014"
    t.text    "esd_k8_2014"
    t.text    "esd_hs_2014"
    t.text    "meap_2013"
    t.text    "act_2014"
    t.text    "fiveessentials_2014"
    t.text    "esd_site_visit_2014"
    t.text    "others"
  end

  add_index "schools", ["bcode"], :name => "index_schools_on_bcode", :length => {"bcode"=>10}
  add_index "schools", ["grades_served"], :name => "index_schools_on_grades_served"
  add_index "schools", ["school_type"], :name => "index_schools_on_school_type"

  create_table "spatial_ref_sys", :options => "ENGINE=MyISAM DEFAULT CHARSET=utf8", :id => false, :force => true do |t|
    t.integer "SRID",                      :null => false
    t.string  "AUTH_NAME", :limit => 256
    t.integer "AUTH_SRID"
    t.string  "SRTEXT",    :limit => 2048
  end

  create_table "tips", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
