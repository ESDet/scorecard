namespace :import do

  
  task :all => :environment do |t, args|
    Importer.get_schema
    Importer.get_profiles
    Importer.get_scores 'esd_k8_2013_r1'
    Importer.get_scores 'esd_hs_2013'
    Importer.get_scores 'meap_2012'
    Importer.get_scores 'meap_2011'
    Importer.get_scores 'meap_2010'
    Importer.get_scores 'meap_2009'
    Importer.get_scores 'act_2013'
    Importer.get_scores 'fiveessentials_2013'
    Importer.get_earlychild
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
    Importer.get_scores 'esd_k8_2013_r1'
    Importer.get_scores 'esd_hs_2013'
    Importer.get_scores 'meap_2012'
    Importer.get_scores 'meap_2011'
    Importer.get_scores 'meap_2010'
    Importer.get_scores 'meap_2009'
    Importer.get_scores 'act_2013'        
    Importer.get_scores 'fiveessentials_2013'
    Importer.get_earlychild
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
    Importer.get_scores 'meap_2009'
  end
  task :k8 => :environment do |t, args|
    puts "Fetching K8"
    Importer.get_scores('esd_k8_2013_r1')
  end
  task :hs => :environment do |t, args|
    puts "Fetching HS"
    Importer.get_scores('esd_hs_2013')
  end
  task :act => :environment do |t, args|
    puts "Fetching ACT"
    Importer.get_scores('act_2013')
  end
  task :fivee => :environment do |t, args|
    puts "Fetching 5Essentials"
    Importer.get_scores('fiveessentials_2013')
  end
  task :earlychild => :environment do |t, args|
    puts "Fetching Early Childhood"
    Importer.get_earlychild
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

  
  
end  

