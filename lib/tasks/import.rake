namespace :import do

  PK = 'bcode'
  TABLE_NAME = 'schools'


  def get_schema
    conn = ActiveRecord::Base.connection
    begin; conn.drop_table TABLE_NAME; rescue; end
    conn.create_table TABLE_NAME
    
    conn.add_column(TABLE_NAME, 'centroid', :point)
    conn.add_column(TABLE_NAME, 'slug', :string)
    
    keys = ['bcode', 'tid', 'name']
    keys.each do |key|
      begin
        conn.add_column(TABLE_NAME, key, :string, {})
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end
    conn.add_index(TABLE_NAME, PK, :length => 10)
  end
  
  def ensure_column(key, ty=:string)
    if !School.column_names.include? key
      puts "Adding column #{key}"
      School.connection.add_column(TABLE_NAME, key, ty, {})
    end
  end

  def get_profiles
    p = Portal.new
    field_re = /^field_(.*)$/
    schools = p.show_vocabulary 4
    schools.each do |s|
      tid = s['tid']
      name = s['name']
      puts "Doing #{name}.."
      profile = p.get_related tid
      h = { 'tid' => tid, 'name' => name }
      if profile.is_a?(Hash)
        profile.each do |k,v|
          m = k.match field_re
          next unless m
          key = m[1]
          ensure_column key
          next if v.empty? or v['und'].empty?
          if v['und'].size == 1
            val = v['und'].first.andand['value']
          else
            val = v['und'].collect { |i| i['value'] }.join(', ')
          end
          puts "  #{key} = #{val.inspect}"
          h[key] = val
        end
        School.reset_column_information
        s = School.find_or_create_by_bcode(h['bcode'])
        s.update_attributes(h)
      end
    end
  end
  
  def get_scores(dataset)
    p = Portal.new
    if dataset == 'meap_2012'
      key_re = /^meap_2012_(.*)$/
      bcode_key = 'bcode'
    elsif dataset == 'esd_k8_2013' || dataset == 'esd_hs_2013'
      key_re = /^(.*)$/
      bcode_key = 'buildingcode'
    end
    ensure_column dataset, :text
    scores = p.get_dataset dataset
    scores.each do |data|
      h = {}
      bcode = data[bcode_key].gsub(/[^0-9]/, '')
      puts "bcode #{bcode}"
      data.each do |key, val|
        next unless m = key.match(key_re)
        key2 = m[1]
        puts "  #{key2} = #{val}"
        h[key2] = val
      end
      School.reset_column_information
      s = School.find_or_create_by_bcode(bcode)
      s.update_attribute(dataset, OpenStruct.new(h))
    end
  end  
    
  
  task :all => :environment do |t, args|
    get_schema
    get_profiles
    get_scores 'meap_2012'
    get_scores 'esd_k8_2013'
    get_scores 'esd_hs_2013'
  end
  
  desc "Create school table schema from feed"
  task :schema => :environment do |t, args|
    get_schema
    puts "Done"
  end

  desc "Pull data from feed, but don't redo schema"
  task :data => :environment do |t, args|
    puts "Getting data..."
    get_profiles
    get_scores 'meap_2012'
    get_scores 'esd_k8_2013'
    get_scores 'esd_hs_2013'
    puts "Done!"
  end

  task :profiles => :environment do |t, args|
    puts "Fetching profiles"
    get_profiles
  end
  task :meap => :environment do |t, args|
    puts "Fetching MEAP"
    get_scores('meap_2012')
  end
  task :k8 => :environment do |t, args|
    puts "Fetching K8"
    get_scores('esd_k8_2013')
  end
  task :hs => :environment do |t, args|
    puts "Fetching HS"
    get_scores('esd_hs_2013')
  end
  
  

  desc "Locate unlocated schools"
  task :geocode => :environment do |t, args|
    schools = School.where('AsText(centroid) = "POINT(0 0)"')
    schools.each do |s|
      puts s.name
      s.centroid = nil
      s.save
    end
  end

  
  desc "Load up tips from data_source_exp"
  task :tips => :environment do |t, args|
    session = GoogleDrive.login(user, pass)
    sheets = session.spreadsheet_by_key(ss_key).worksheets
    ws = sheets[4]
    num_rows = ws.num_rows
    num_cols = ws.num_cols
    Tip.delete_all
    ws.rows[1..num_rows].each do |row|
      puts row[0]
      puts row[1]
      puts "-----"
      Tip.create(:name => row[0], :body => row[1])
    end
  end
  
  
end  

