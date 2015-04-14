# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "bedrock"
  s.author = "ESD"
  s.summary = "Bedrock."
  s.description = "Insert Bedrock description."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.version = "0.2.0"

  s.add_dependency 'andand'
  s.add_dependency 'json'
  s.add_dependency 'rgeo'
  #s.add_dependency 'activerecord-mysqlspatial-adapter'
  s.add_dependency 'activerecord-mysql2spatial-adapter'
  s.add_dependency 'rgeo-geojson'

  s.rubyforge_project = "bedrock"
end
