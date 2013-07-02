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
  
  def ensure_column(key)
    if !School.column_names.include? key
      puts "Adding column #{key}"
      School.connection.add_column(TABLE_NAME, key, :string, {})
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
      end
      School.reset_column_information
      s = School.find_or_create_by_bcode(h['bcode'])
      s.update_attributes(h)
    end
  end
  
  def get_meap
    p = Portal.new
    meap = p.get_dataset 'meap_2012'
    meap.each do |data|
      h = {}
      bcode = data['bcode']
      data.each do |key, val|
        puts "bcode #{data['bcode']}"
        puts "  #{key} = #{val}"
        ensure_column key
        h[key] = val
      end
      School.reset_column_information
      s = School.find_or_create_by_bcode(bcode)
      s.update_attributes(h)
    end
  end  
  
  def get_esd_k8
    p = Portal.new
    result = p.get_dataset 'esd_k8_2013'
    result.each do |data|
      
    end
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
    get_meap
    puts "Done!"
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

