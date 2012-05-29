namespace :import do

  def get_schema(sheets)
    table_name = 'schools'
    conn = ActiveRecord::Base.connection
    begin; conn.drop_table table_name; rescue; end
    conn.create_table table_name
    types = {
      'Text'        => :text,
      'Double'      => :double,
      'Percentage'  => :float,
    }
    
    conn.add_column(table_name, 'centroid', :point)
    sheets.each do |ws|
      num_rows = ws.num_rows
      num_cols = ws.num_cols
      puts "Found #{num_rows} rows, #{num_cols} columns"
      (1..num_cols).each do |c|
        key = ws[2, c]
        ty = types[ws[5, c]] || 'Text'
        next if ty.blank?
        puts "Key #{key} is #{ty.to_s}"
        begin
          conn.add_column(table_name, key, ty, {})
        rescue => e
          puts e.inspect
          puts e.backtrace
        end
      end
    end
    
  end

  def get_data(sheets)
    sheets.each_with_index do |ws,i|
      puts "DOING SHEET #{i}"
      num_rows = ws.num_rows
      num_cols = ws.num_cols
      key_row = ws.rows[1]
      ws.rows[6..num_rows].each do |row|
        puts "#{row[2]}"
        h = {}
        (0...num_cols).each do |x|
          key = key_row[x]
          next if key.blank?
          val = row[x]
          #puts "   #{key} = #{val}"
          h[key] = val
          id = val if key == School.primary_key
        end
        s = School.find_or_create_by_id(h['SCHOOL_BCODE'])
        s.update_attributes(h)
      end
    end
  end  
  
  
  
  
  desc "Create school table schema from spreadsheet"
  task :sample => :environment do |t, args|
    session = GoogleDrive.login("inchbot@makeloveland.com", "jNbu2&4M")
    sheets = session.spreadsheet_by_key("0Al6LPbGeSiAJdG15aHU5cnI0Sy1obF94LXc5UEZOV2c").worksheets

    get_schema(sheets)
    get_data(sheets)
    puts "Done"
  end
  
  desc "Make fake locations"
  task :geocode => :environment do |t, args|
    points = Skool.select('OGR_FID, centroid').collect { |g| g.centroid }.shuffle
    puts "Got points, updating schools.."
    School.all.each_with_index do |s,i|
      puts s.name
      s.update_attribute(:centroid, points[i])
    end
  end
  
  
end  

