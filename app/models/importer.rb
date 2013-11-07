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

    vocabs = {
      :types       => 3,
      :status      => 2,
      :govs        => 7,
      :operators   => 10,
      :authorizers => 11,
    }
    
    vocabs.each do |key, vid|
      dict = p.show_vocabulary vid
      dict = Hash[dict.collect { |t| [t['tid'], t['name']] }]
      vocabs[key] = dict
    end
      
    ap vocabs
    
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
      ['email', 'school_scorecard_status', 'school_status', 'loc_email', 'scorecard_display'].each do |f|
        val = s["field_#{f}"]
        if val.empty?
          val = nil
        else
          val = val['und'].andand.first.andand['value']
        end
        basic[f.to_sym] = val
      end
      
      # Don't store the ones to not display
      if basic[:scorecard_display].to_i == 0
        existing = School.find_by_bcode(bcode)
        existing.andand.destroy
        next
      end
      
      lookups = {
        'school_type' => :types,
        'school_status' => :status,
        'governance' => :govs,
        'operator' => :operators,
        'authorizer' => :authorizers,
      }
      
      lookups.each do |field, vocab|
        dict = vocabs[vocab]
        val = s["field_#{field}"]
        next if val.blank?
        val = val['und'].andand.first.andand['tid']
        puts "#{field} tid=#{val} and looked-up = #{dict[val]}"
        basic[field] = dict[val]
      end
      
      # Address
      addr = s['field_address']['und'].first
      basic[:address] = addr
      basic[:links] = s['field_links'].empty? ? nil : s['field_links']['und'].collect { |l| l['url'] }
      address = addr['thoroughfare']
      address2 = "#{addr['locality']}, #{addr['administrative_area']} #{addr['postal_code']}"
      basic[:address]

      # Geography
      if geo = s['field_geo'].andand['und'].andand.first
        puts "Found geographic position: #{geo.inspect}"
        centroid = RGeo::Geographic.spherical_factory.point(geo['lon'].to_f, geo['lat'].to_f)
      elsif !addr['thoroughfare'].blank?
        geo = Bedrock::Geocoder.bing_geocode({
          :address => addr['thoroughfare'],
          :city    => addr['locality'],
          :state   => addr['administrative_area'],
          :zip     => addr['postal_code']
        })
        centroid = RGeo::Geographic.spherical_factory.point(geo.andand[:location].andand[:lon] || 0, geo.andand[:location].andand[:lat] || 0)
      end

      # Ze attributes
      attrs = {
        :tid          => tid,
        :bcode        => bcode,
        :name         => name, 
        :basic        => OpenStruct.new(basic),
        :school_type  => basic['school_type'],
        :address      => address,
        :address2     => address2,
        :zip          => addr['postal_code'],
        :centroid     => centroid
      }

      # And the extended profile stuff
      ensure_column :profile, :text
      profile = p.get_related tid
      encoding_options = {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :universal_newline => true       # Always break lines with \n
      }
      if profile.is_a?(Hash)
        h = {}
        profile.each do |k,v|
          next unless (m = k.match field_re)
          key = m[1]
          next if v.empty? or v['und'].empty?
          val = (v['und'].size == 1) ? v['und'].first.andand['value'] : v['und'].collect { |i| i['value'] }.join(', ')
          val = val.encode Encoding.find('ASCII'), encoding_options unless val.nil?
          puts "  #{key} = #{val.inspect}"
          h[key] = val
        end
        attrs.merge!({:profile => OpenStruct.new(h), :grades_served => h['grades_served']})
      end
      
      # Now apply these to 1 or 2 schools
      if attrs[:school_type] == 'K12'
        # Make two schools (or update them)
        if School.where(:bcode => bcode).count == 1
          # Migrate from old version
          School.delete_all(:bcode => bcode)
        end
        k8a = attrs.merge({ :school_type => 'K8', :name => "#{attrs[:name]} (K8)" })
        hsa = attrs.merge({ :school_type => 'HS', :name => "#{attrs[:name]} (HS)" })
        if School.where(:bcode => bcode).count == 2
          # Ok update them both
          School.where(:bcode => bcode, :school_type => 'K8').first.update_attributes(k8a)
          School.where(:bcode => bcode, :school_type => 'HS').first.update_attributes(hsa)
        else
          School.create(k8a)
          School.create(hsa)
        end
      else
        school = School.find_or_create_by_bcode(bcode)
        school.attributes = attrs
        school.save
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
    elsif base == 'fiveessentials'
      key_re = /^(.*)$/
      bcode_key = 'bcode'
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
        schools = School.where(:bcode => bcode)
        schools.each do |s|
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
  end  
  
  
  def self.get_earlychild
    dataset = 'earlychild'
    ensure_column dataset, :text

    p = Portal.new
    per = 1000
    results = []
    ofs = 0
    begin
      results = p.get_dataset dataset, nil, { :limit => per, :offset => ofs }
      ofs += per
      
      results.each do |r|
        next if r['publishedrating'].to_i < 3 
        loc = RGeo::Geographic.spherical_factory.point(r['lon'].to_f, r['lat'].to_f)
        r['publishedrating'] = r['publishedrating'].to_i
        
        h = {
          :bcode        => r['licensenumber'],
          :name         => r['businessname'].gsub('&#039;', "'").gsub('&amp;', '&'),
          :school_type  => 'EC',
          :points       => r['gscpts'].to_i,
          :address      => r['address'],
          :address2     => "#{r['city']}, MI #{r['zipcode']}",
          :zip          => r['zipcode'],
          :earlychild   => OpenStruct.new(r),
          :centroid     => loc,
        }
        if s = School.find_by_bcode(h[:bcode])
          puts "Found license #{h[:bcode]} - #{h[:name]}"
          s.update_attributes(h)
        else
          puts "Creating lic# #{h[:bcode]} - #{h[:name]}"
          s = School.create(h)
          h
        end
      end
    end while !results.empty?
  end
  
end