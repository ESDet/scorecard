namespace :import do

  
  task :all => :environment do |t, args|
    Importer.get_schema
    Importer.get_profiles
    Importer.get_scores 'meap_2012'
    Importer.get_scores 'esd_k8_2013'
    Importer.get_scores 'esd_hs_2013'
  end
  
  desc "Create school table schema from feed"
  task :schema => :environment do |t, args|
    Importer.get_schema
    puts "Done"
  end

  desc "Pull data from feed, but don't redo schema"
  task :data => :environment do |t, args|
    puts "Getting data..."
    Importer.get_profiles
    Importer.get_scores 'esd_k8_2013'
    Importer.get_scores 'esd_hs_2013'
    Importer.get_scores 'meap_2012'
    Importer.get_scores 'meap_2011'
    Importer.get_scores 'meap_2010'
    Importer.get_scores 'meap_2009'        
    puts "Done!"
  end

  task :profiles => :environment do |t, args|
    puts "Fetching profiles"
    Importer.get_profiles
  end
  task :meap => :environment do |t, args|
    puts "Fetching MEAP"
    Importer.get_scores('meap_2012')
    Importer.get_scores('meap_2011')
    Importer.get_scores('meap_2010')
  end
  task :k8 => :environment do |t, args|
    puts "Fetching K8"
    Importer.get_scores('esd_k8_2013')
  end
  task :hs => :environment do |t, args|
    puts "Fetching HS"
    Importer.get_scores('esd_hs_2013')
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

