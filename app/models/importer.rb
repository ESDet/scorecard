class Importer

  PK = 'bcode'
  TABLE_NAME = 'schools'

  NEW14 = ["academic_focus", "instructional_model", "staff_resources", "arts_visual", "arts_media", "arts_music", "arts_performing_written", "transportation_options", "special_ed_level", "special_ed_programs", "boys_sports", "girls_sports", "dual_enrollment", "ell_level", "ell_languages", "dual_enrollment_institutio", "family_supports", "facilities", "parent_supports", "dress_code", "schedule", "student_leadership_opportu", "student_development_progra", "college_prep", "skills_training", "before_after_care", "bullying_policy", "immersion", "special_tracks", "early_childhood_programs", "extra_learning_resources", "foreign_language", "facebook_url", "school_url", "parent_involvement", "application_process", "admissions_url", "application_fee", "application_fee_amount", "applications_received", "students_accepted", "feeder_school", "destination_school", "student_clubs", "student_clubs_dance", "student_clubs_language", "student_clubs_other"]

  def self.ensure_column(key, ty=:string)
    School.reset_column_information
    if !School.column_names.include? key.to_s
      puts "Adding column #{key} as #{ty}"
      School.connection.add_column(TABLE_NAME, key, ty, {})
      School.reset_column_information
    end
  end

  def self.update_relations
    # Calculate and store the "k12" and "others" columns for the schools (assumes they have all been loaded and geolocated)
    # so that we don't calculate on every search / geojsonification
    School.find_each do |s|
      k12 = (School.where(:bcode => s.bcode).count > 1)
      s.update_attribute(:k12, k12)
      others = School.where(:centroid => s.centroid).
        where('id <> ?', s.id).
        select('id, name, address, school_type, grades_served, bcode, slug')
      s.update_attribute(:others, others.empty? ? nil :
        others.collect { |o| { :id => o.id, :name => o.name, :slug => o.slug, :grades => o.grades_served } })
    end
  end

  # grades is a String, kind = :k8 or :hs
  def self.filter_grades_served(grades, kind)
    gs = grades.split(',').collect { |i| i.squish }
    valid = (kind == :k8) ? %w[KF 1 2 3 4 5 6 7 8] : %w[9 10 11 12]
    (gs & valid).join(', ')
  end

  def self.get_profiles
    p = Portal.new
    field_re = /^field_(.*)$/

    vocabs = {
      :types       => 3,
      :status      => 2,
      :govs        => 7,
      :operators   => 10,
      :authorizers => 11
    }

    vocabs.each do |key, vid|
      dict = p.show_vocabulary vid
      dict = Hash[dict.collect { |t| [t['tid'], t['name']] }]
      vocabs[key] = dict
    end

    #ap vocabs

    puts "Getting schools..."
    schools = p.show_vocabulary 4
    schools.each do |s|
      tid = s['tid']
      name = s['name']
      bcode = s['field_bcode']
      #puts "Doing #{name} (#{bcode})..."
      next if bcode.nil?

      # First the basic stuff
      ensure_column :basic, :text
      basic = {}
      ['email', 'school_scorecard_status', 'school_status', 'loc_email', 'scorecard_display'].each do |f|
        val = s["field_#{f}"]
        val = if val
          if val.is_a?(Hash)
            val['name']
          elsif val.is_a?(Array)
            val.first['name']
          else
            val
          end
        end
        basic[f.to_sym] = val
      end

      # Don't store the ones to not display
      if basic[:scorecard_display] == false
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
        if val.is_a?(Hash)
          val = val['tid']
        elsif val.is_a?(Array)
          val = val.first['tid']
        end
        #puts "#{field} tid=#{val} and looked-up = #{dict[val]}"
        basic[field] = dict[val]
      end

      # Address
      addr = s['field_address']
      basic[:address] = addr
      basic[:links] = s['field_links'].empty? ? nil : s['field_links']['und'].collect { |l| l['url'] }
      address = addr['thoroughfare']
      address2 = "#{addr['locality']}, #{addr['administrative_area']} #{addr['postal_code']}"

      # Geography
      if geo = s['field_geo']
        #puts "Found geographic position: #{geo.inspect}"
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
        #:universal_newline => true,       # Always break lines with \n
        :UNIVERSAL_NEWLINE_DECORATOR => true,
      }
      if profile.is_a?(Hash)
        h = {}
        profile.each do |k,v|
          next unless (m = k.match field_re)
          key = m[1]
          next if v.empty? or v['und'].empty?
          val = if v['und'].is_a?(Array)
            (v['und'].size == 1) ? v['und'].first.andand['value'] : v['und'].collect { |i| i['value'] }.join(', ')
          elsif v['und'].is_a?(Hash)
            v['und'].first[1]['name']
          end
          val = val.encode Encoding.find('ASCII'), encoding_options unless val.nil?
          #puts "  #{key} = #{val.inspect}"
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
        if attrs[:grades_served]
          k8a = attrs.merge({
            :school_type => 'K8',
            :name => "#{attrs[:name]} (K8)",
            :grades_served => filter_grades_served(attrs[:grades_served], :k8)
          })
          hsa = attrs.merge({
            :school_type => 'HS',
            :name => "#{attrs[:name]} (HS)",
            :grades_served => filter_grades_served(attrs[:grades_served], :hs)
          })
        end
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
    elsif base == 'fiveessentials' or base == 'esd_site_visit'
      key_re = /^(.*)$/
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
        schools = School.where(:bcode => bcode)
        schools.each do |s|
          #puts "bcode #{bcode} - #{s.name}"
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

        id = r['id'].gsub(/[^0-9]/, '')
        license = r['licensenumber']
        h = {
          :bcode        => id,
          :name         => r['businessname'].gsub('&#039;', "'").gsub('&amp;', '&'),
          :school_type  => 'EC',
          :points       => r['gscpts'].to_i,
          :address      => r['address'],
          :address2     => "#{r['city']}, MI #{r['zipcode']}",
          :zip          => r['zipcode'],
          :earlychild   => OpenStruct.new(r),
          :centroid     => loc,
        }
        s = School.find_by_bcode(license)
        s ||= School.find_by_bcode(id)
        if s
          #puts "Found id/license #{id} - #{h[:name]}"
          s.update_attributes(h)
        else
          #puts "Creating lic# #{h[:bcode]} - #{h[:name]}"
          s = School.create(h)
          h
        end
      end
    end while !results.empty?
  end

  def self.get_ecs
    dataset = 'ecs'
    ensure_column dataset, :text

    p = Portal.new
    per = 1000
    results = []
    ofs = 0
    begin
      results = p.get_dataset dataset, nil, {
        :limit => per,
        :offset => ofs,
        :flatten_fields => 1,
        :includes => "most_recent_ec_state_rating,ec_profile"
      }
      ofs += per

      results['data'] = [] if results['data'].nil?

      results['data'].each do |r|

        if !(rating_links = r['links']['most_recent_ec_state_rating']).empty?
          state_rating_id = rating_links['linkage']['id']
          if state_rating_id
            state_rating_info = results['included'].select do |l|
              l['type'] == 'ec_state_ratings' && l['id'] == state_rating_id
            end.first
          end
        end

        if profile_links = r['links']['ec_profile']
          profile_id = profile_links['linkage']['id']
          profile = results['included'].select do |l|
            l['type'] == 'ec_profiles' && l['id'] == profile_id
          end.first
        end

        published_rating = state_rating_info['PublishedRating'] if state_rating_info

        geo = r['field_geo'] if r['field_geo']
        loc = RGeo::Geographic.spherical_factory.point(geo['lon'].to_f, geo['lat'].to_f) if geo

        r['publishedrating'] = published_rating.to_i if published_rating

        id = state_rating_info['esd_ec_id'] if state_rating_info
        license = r['field_state_license_id']

        address = r['field_address']
        points = state_rating_info['ptsTotal'].to_i if state_rating_info
        name = profile['title'].gsub('&#039;', "'").gsub('&amp;', '&') if profile

        h = { }
        h[:bcode]       = id if id
        h[:name]        = name if name
        h[:school_type] = 'EC'
        h[:points]      = points if points
        h[:address]     = address['thoroughfare'] if address['thoroughfare']
        h[:address2]    = "#{address['locality']}, MI #{address['postal_code']}" if address[:locality] && address[:postal_code]
        h[:zip]         = address['postal_code'] if address['postal_code']
        r = r.merge(state_rating_info) if state_rating_info
        r = r.merge(profile) if profile
        h[:ecs]         = OpenStruct.new(r)
        h[:centroid]    = loc if loc
        s = School.find_by_bcode(license)
        s ||= School.find_by_bcode(id)
        if s
          #puts "Found id/license #{id} - #{h[:name]}"
          s.update_attributes(h)
        else
          #puts "Creating lic# #{h[:bcode]} - #{h[:name]}"
          s = School.create(h)
          h
        end
      end
    end while !results['data'].empty?
    School.where(school_type: 'EC').
      select do |s|
        s.esd_el_2015.instance_values["table"].empty?
    end.each(&:delete)
  end


  def self.get_el(year)
    dataset = "esd_el_#{year}"
    ensure_column dataset, :text

    p = Portal.new
    per = 1000
    results = []
    ofs = 0
    begin
      results = p.get_dataset dataset, nil, { :limit => per, :offset => ofs }
      ofs += per

      results.each do |r|
        # To join with the earlychild records, whic have a bcode like this
        pid = r['program_id'].gsub(/[^0-9]/, '')
        r['program_name'] = CGI.unescapeHTML(r['program_name']) if r['program_name']

        if s = School.find_by_bcode(pid)
          #puts "Updating school with id #{pid}"
          s.update_attribute(dataset, OpenStruct.new(r))
          s.update_attribute :name, r['program_name'] if r['program_name']
        else
          #puts "No school found with bcode #{pid}"
        end

      end
    end while !results.empty?
  end

end
