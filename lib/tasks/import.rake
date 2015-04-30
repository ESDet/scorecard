namespace :import do
  desc "Pull data from feed"
  task :data => :environment do |t, args|
    puts "Getting data..."
    Importer.get_profiles
    Importer.get_scores 'esd_k8_2014'
    Importer.get_scores 'esd_hs_2014'
    Importer.get_scores 'meap_2013'
    Importer.get_scores 'meap_2012'
    Importer.get_scores 'meap_2011'
    Importer.get_scores 'meap_2010'
    Importer.get_scores 'meap_2009'
    Importer.get_scores 'act_2014'
    Importer.get_scores 'fiveessentials_2014'
    Importer.get_scores 'esd_site_visit_2014'
    Importer.get_earlychild
    Importer.get_el 2014
    Importer.get_el 2015
    Importer.update_relations
    puts "Done!"
  end

  task :profiles => :environment do |t, args|
    puts "Fetching profiles"
    Importer.get_profiles
  end

  task :k8 => :environment do |t, args|
    puts "Fetching K8"
    Importer.get_scores('esd_k8_2014')
  end

  task :hs => :environment do |t, args|
    puts "Fetching HS"
    Importer.get_scores('esd_hs_2014')
  end

  task :meap => :environment do |t, args|
    puts "Fetching MEAP"
    Importer.get_scores('meap_2013')
    Importer.get_scores('meap_2012')
    Importer.get_scores('meap_2011')
    Importer.get_scores('meap_2010')
    Importer.get_scores('meap_2009')
  end


  task :act => :environment do |t, args|
    puts "Fetching ACT"
    Importer.get_scores('act_2014')
  end

  task :fivee => :environment do |t, args|
    puts "Fetching 5Essentials"
    Importer.get_scores('fiveessentials_2014')
  end

  task :sitevisit => :environment do |t, args|
    puts "Fetching Site Visit"
    Importer.get_scores('esd_site_visit_2014')
  end

  task :earlychild => :environment do |t, args|
    puts "Fetching Early Childhood"
    Importer.get_earlychild
    Importer.get_ecs
    Importer.get_el(2014)
    Importer.get_el(2015)
  end

  task :relations => :environment do
    Importer.update_relations
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

  task :fix_k12 => :environment do
    #School.where("name like '%(HS)' or name like '%(K8)'").find_each do |s|
    School.where(:k12 => 1).find_each do |s|
      puts "Doing #{s.name}"
      s.grades_served = Importer.filter_grades_served(s.grades_served, (s.school_type == 'K8' ? :k8 : :hs))
      s.save
    end
  end
end
