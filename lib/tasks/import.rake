namespace :import do
  user = "inchbot@makeloveland.com"
  pass = "jNbu2&4M"
  #ss_key      = '0Al6LPbGeSiAJdGFySUF4ZjVvOWcxamp4TGR3NnFQM3c'  # first phase
  #ss_key_2012 = '0Apj1pa-R5UZ0dDlMNjFqVHRqX1EzbWlxVWRuV2NlWnc'  # 2013 updates with 2012 data
  ss_key      = '0Al6LPbGeSiAJdFFDVTVpc3BDX3pYUHdBZ19qY2ZOSEE'  # 2013 combined sheet

  PK = 'BCODE_TEMPLATE'
  TABLE_NAME = 'schools'
  TYPES = {
    'Text'        => :text,
    'Double'      => :double,
    'Percentage'  => :float,
  }


  def get_schema(ws)
    conn = ActiveRecord::Base.connection
    begin; conn.drop_table TABLE_NAME; rescue; end
    conn.create_table TABLE_NAME
    
    conn.add_column(TABLE_NAME, 'centroid', :point)
    conn.add_column(TABLE_NAME, 'slug', :string)
    
    num_rows = ws.num_rows
    num_cols = ws.num_cols
    puts "Found #{num_rows} rows, #{num_cols} columns"
    (2..num_rows).each do |r|
      key = ws[r, 5].squish
      ty = TYPES[ws[r, 10] || 'Text']
      next if key.blank? or ty.blank?
      puts "Key #{key} is #{ty.to_s}"
      begin
        conn.add_column(TABLE_NAME, key, ty, {})
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end
    conn.add_index(TABLE_NAME, PK, :length => 10)
  end
  
  def add_schema_2012(ws)
    conn = ActiveRecord::Base.connection
    num_rows = ws.num_rows
    num_cols = ws.num_cols
    puts "Found #{num_rows} rows, #{num_cols} columns"
    (1..num_rows).each do |r|
      key = ws[r, 1]
      ty = TYPES[ws[r, 2] || 'Text']
      next if key.blank? or ty.blank?
      puts "Key #{key} is #{ty.to_s}"
      begin
        conn.add_column(TABLE_NAME, key, ty, {}) unless key == PK
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end
  end


  def get_data(ws)
    column_names = School.column_names
    num_rows = ws.num_rows
    num_cols = ws.num_cols
    key_row = ws.rows[0]
    name_col = 4
    ws.rows[1..num_rows].each do |row|
      puts row[name_col]
      h = {}
      (0...num_cols).each do |x|
        key = key_row[x].squish
        next if key.blank?
        val = row[x]
        val = nil if val.blank? or val == 'N/A' or val == '*'
        val = -5 if val == '< 5%'
        #puts "   #{key} = #{val}"
        h[key] = val
      end
      h.slice! *column_names
      s = School.find_or_create_by_BCODE_TEMPLATE(h[PK])
      s.update_attributes(h)
    end
  end  
  
  
  def add_data_2012(sheet)
    column_names = School.column_names
    num_rows = sheet.num_rows
    num_cols = sheet.num_cols
    key_row = sheet.rows[0]
    pk_col = 0
    sheet.rows[1..num_rows].each do |row|
      key = row[pk_col]
      school = School.find_by_BCODE_TEMPLATE(key)
      if school.nil?
        puts "Couldn't find a school with key #{key}!"
        next
      end
      puts school.SCHOOL_NAME_2011
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
      school.update_attributes(h)
    end
  end
  
  
  
  
  desc "Create school table schema from spreadsheet"
  task :schema => :environment do |t, args|
    session = GoogleDrive.login(user, pass)
    puts "Creating schema from original sheet"
    sheets = session.spreadsheet_by_key(ss_key).worksheets
    get_schema(sheets.first)
    
    #puts "Merging 2012 updates"
    #sheets_2012 = session.spreadsheet_by_key(ss_key_2012).worksheets
    #add_schema_2012(sheets_2012.first)
    
    puts "Done"
  end

  desc "Pull data from sheet, but don't redo schema"
  task :data => :environment do |t, args|
    session = GoogleDrive.login(user, pass)
    puts "Getting original data"
    sheets = session.spreadsheet_by_key(ss_key).worksheets
    get_data(sheets[3])
    
    #puts "Merging 2012 updates"
    #sheets_2012 = session.spreadsheet_by_key(ss_key_2012).worksheets
    #add_data_2012(sheets_2012[1])

    puts "Done"
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

