namespace :import do

  PK = 'bcode'
  TABLE_NAME = 'schools'


  def get_schema
    conn = ActiveRecord::Base.connection
    begin; conn.drop_table TABLE_NAME; rescue; end
    conn.create_table TABLE_NAME
    
    keys = [:bcode, :tid, :name, :slug, :address, :address2, :zip, :school_type]
    keys.each do |key|
      begin
        conn.add_column(TABLE_NAME, key, :string, {})
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end
    conn.add_column(TABLE_NAME, :centroid, :point)
    conn.add_index(TABLE_NAME, PK, :length => 10)
    conn.add_index(TABLE_NAME, :grades_served)
    conn.add_index(TABLE_NAME, :school_type)
  end
  
  def ensure_column(key, ty=:string)
    School.reset_column_information
    if !School.column_names.include? key.to_s
      puts "Adding column #{key}"
      School.connection.add_column(TABLE_NAME, key, ty, {})
      School.reset_column_information
    end
  end

  def get_profiles
    p = Portal.new
    field_re = /^field_(.*)$/
    types = p.show_vocabulary 3
    types = Hash[types.collect { |t| [t['tid'], t['name']] }]
    puts "Types: #{types.inspect}"
    schools = p.show_vocabulary 4
    schools.each do |s|
      tid = s['tid']
      name = s['name']
      bcode = s['field_bcode']
      next if bcode.empty?
      bcode = bcode['und'].andand.first.andand['value']
      puts "Doing #{name} (#{bcode})..."
      next if bcode.nil?

      # First the basic stuff
      ensure_column :basic, :text
      basic = {}
      ['email', 'school_scorecard_status', 'school_status', 'loc_email'].each do |f|
        val = s["field_#{f}"]
        if val.empty?
          val = nil
        else
          val = val['und'].andand.first.andand['value']
        end
        basic[f.to_sym] = val
      end
      
      stid = s['field_school_type']
      unless stid.blank?
        stid = stid['und'].andand.first.andand['tid']
        puts "School_type tid: #{stid}, and types[stid] = #{types[stid]}"
        basic['school_type'] = types[stid]
      end
      
      addr = s['field_address']['und'].first
      basic[:address] = addr
      basic[:links] = s['field_links'].empty? ? nil : s['field_links']['und'].collect { |l| l['url'] }
      address = addr['thoroughfare']
      address2 = "#{addr['locality']}, #{addr['administrative_area']} #{addr['postal_code']}"
      school = School.find_or_create_by_bcode(bcode)
      school.attributes = { 'tid' => tid, 'name' => name, :basic => OpenStruct.new(basic), :school_type => types[stid],
        :address => address, :address2 => address2, :zip => addr['postal_code'] }
      if false and school.address_changed? and !addr['thoroughfare'].blank?
        geo = Bedrock::Geocoder.bing_geocode({
          :address => addr['thoroughfare'],
          :city    => addr['locality'],
          :state   => addr['administrative_area'],
          :zip     => addr['postal_code']
        })
        school.centroid = RGeo::Geographic.spherical_factory.point(geo.andand[:location].andand[:lon] || 0, geo.andand[:location].andand[:lat] || 0)
      end
      school.save
      

      # And the extended profile stuff
      ensure_column :profile, :text
      profile = p.get_related tid
      if profile.is_a?(Hash)
        h = {}
        profile.each do |k,v|
          next unless (m = k.match field_re)
          key = m[1]
          next if v.empty? or v['und'].empty?
          val = (v['und'].size == 1) ? v['und'].first.andand['value'] : v['und'].collect { |i| i['value'] }.join(', ')
          puts "  #{key} = #{val.inspect}"
          h[key] = val
        end
        school.update_attributes(:profile => OpenStruct.new(h), :grades_served => h['grades_served'])
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
    
    School.find_each do |s|
      scores = p.get_dataset dataset, s.bcode
      scores.each do |data|
        h = {}
        bcode = data[bcode_key].gsub(/[^0-9]/, '')
        puts "bcode #{bcode}"
        data.each do |key, val|
          next unless m = key.match(key_re)
          key2 = m[1]
          #puts "  #{key2} = #{val}"
          h[key2] = val
        end
        s.update_attribute(dataset, OpenStruct.new(h))
      end
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

