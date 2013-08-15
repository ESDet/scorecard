class Importer

  PK = 'bcode'
  TABLE_NAME = 'schools'


  def self.get_schema
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
    conn.add_column(TABLE_NAME, :points, :integer)
    conn.add_column(TABLE_NAME, :centroid, :point)
    conn.add_index(TABLE_NAME, PK, :length => 10)
    conn.add_index(TABLE_NAME, :school_type)
    conn.add_index(TABLE_NAME, :points)
  end
  
  def self.ensure_column(key, ty=:string)
    School.reset_column_information
    if !School.column_names.include? key.to_s
      puts "Adding column #{key}"
      School.connection.add_column(TABLE_NAME, key, ty, {})
      School.reset_column_information
    end
  end

  def self.get_profiles
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
      ['email', 'school_scorecard_status', 'school_status', 'loc_email', 'scorecard_display', 'geo'].each do |f|
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
      if school.address_changed? and !addr['thoroughfare'].blank?
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
  
  def self.get_scores(dataset)
    p = Portal.new
    m = dataset.match(/(.+)_([0-9]+)/)
    base = m[1]
    year = m[2]
    
    if base == 'meap'
      key_re = /^meap_#{year}_(.*)$/
      bcode_key = 'bcode'
    elsif base.include? 'esd' or base == 'act'
      key_re = /^(.*)$/
      bcode_key = 'buildingcode'
    end
    ensure_column dataset, :text
    
    per = 1000
    results = []
    ofs = 0
    begin
      results = p.get_dataset dataset, nil, { :limit => per, :offset => ofs }
      ofs += per
      
      results.each do |r|
        bcode = r[bcode_key].gsub(/[^0-9]/, '')
        if s = School.find_by_bcode(bcode)
          puts "bcode #{bcode} - #{s.name}"
          h = {}
          r.each do |key, val|
            next unless m = key.match(key_re)
            h[m[1]] = val
          end
          s.update_attribute(dataset, OpenStruct.new(h))
        end
      end
    end while !results.empty?
    

    if false    
      # This was working (if slow) for the others
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
    
  end  
  
end