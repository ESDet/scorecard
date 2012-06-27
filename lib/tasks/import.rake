namespace :import do

  def get_schema(ws)
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
    
    num_rows = ws.num_rows
    num_cols = ws.num_cols
    puts "Found #{num_rows} rows, #{num_cols} columns"
    (2..num_rows).each do |r|
      key = ws[r, 5]
      ty = types[ws[r, 10] || 'Text']
      next if key.blank? or ty.blank?
      puts "Key #{key} is #{ty.to_s}"
      begin
        conn.add_column(table_name, key, ty, {})
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end
  end

  def get_data(sheets)
    column_names = School.column_names
    sheets.each_with_index do |ws,i|
      puts "DOING SHEET #{i}"
      num_rows = ws.num_rows
      num_cols = ws.num_cols
      key_row = ws.rows[0]
      #name_col = key_row.index 'SCHOOL_NAME_2011'
      name_col = 4
      ws.rows[1..num_rows].each do |row|
        puts row[name_col]
        h = {}
        (0...num_cols).each do |x|
          key = key_row[x]
          next if key.blank?
          val = row[x]
          val = nil if val.blank? or val == 'N/A' or val == '*'
          val = -5 if val == '< 5%'
          #puts "   #{key} = #{val}"
          h[key] = val
        end
        h.slice! *column_names
        s = School.find_or_create_by_BCODE_TEMPLATE(h['BCODE_TEMPLATE'])
        s.update_attributes(h)
        #s = School.create(h)
      end
    end
  end  
  
  
  
  
  desc "Create school table schema from spreadsheet"
  task :schema => :environment do |t, args|
    session = GoogleDrive.login("inchbot@makeloveland.com", "jNbu2&4M")
    real_key  = '0Al6LPbGeSiAJdGFySUF4ZjVvOWcxamp4TGR3NnFQM3c' # 25th
    sheets = session.spreadsheet_by_key(real_key).worksheets
    get_schema(sheets.first)
    puts "Done"
  end

  desc "Pull data from sheet, but don't redo schema"
  task :data => :environment do |t, args|
    session = GoogleDrive.login("inchbot@makeloveland.com", "jNbu2&4M")
    real_key  = '0Al6LPbGeSiAJdGFySUF4ZjVvOWcxamp4TGR3NnFQM3c' # 25th
    sheets = session.spreadsheet_by_key(real_key).worksheets
    get_data(sheets[3..3])
    puts "Done"
  end


  desc "Make fake locations"
  task :fake_geocode => :environment do |t, args|
    points = Skool.select('OGR_FID, centroid').collect { |g| g.centroid }.shuffle
    puts "Got points, updating schools.."
    School.all.each_with_index do |s,i|
      puts s.name
      s.update_attribute(:centroid, points[i])
    end
  end
  
  
end  

