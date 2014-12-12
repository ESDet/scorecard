namespace :bedrock do

  src_dir = '../bedrock'
  dst_dir = '.'

  task :copy_assets => :environment do |t|
    desc "Copies bedrock assets to application public"
    system "mkdir #{dst_dir}/public/leaflet"
    system "mkdir #{dst_dir}/public/leaflet/images"
    
    FileList["#{src_dir}/public/javascripts/*", "#{src_dir}/public/stylesheets/*",
             "#{src_dir}/public/leaflet/*.*",   "#{src_dir}/public/leaflet/images/*.*"].each do |source|
      target = source.sub(src_dir, dst_dir)
      cp source, target, :verbose => true
    end
  end  
  
  task :clean_assets => :environment do |t|
    desc "Remove bedrock assets from application public dir"

    FileList["#{src_dir}/public/javascripts/*", "#{src_dir}/public/stylesheets/*",
             "#{src_dir}/public/leaflet/*.*",   "#{src_dir}/public/leaflet/images/*.*"].each do |source|
      target = source.sub(src_dir, dst_dir)
      rm target, :verbose => true
    end
    system "rmdir #{dst_dir}/public/leaflet/images"
    system "rmdir #{dst_dir}/public/leaflet"
  end
end
