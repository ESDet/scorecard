class Portal
  include HTTParty
  default_timeout 30

  BASE = if Rails.env.in?(['staging', 'production'])
    'https://portal.excellentschoolsdetroit.org/api/1.0/'
  else
    'https://ec-scorecard-api-3mhev6qb5ihtc.us.platform.sh/api/1.0/'
  end

  def list_vocabularies
    fetch 'taxonomy_vocabulary.json/'
  end

  def show_vocabulary(vid)
    fetch 'taxonomy_vocabulary/getTree.json/', { vid: vid, load_entities: 1, flatten_fields: 1 }, :post
  end

  def get_related(tid)
    result = fetch 'taxonomy_term/selectNodes.json', { tid: tid }, :post
    result.first
  end

  def get_dataset(view, bcode=nil, opts={})
    data = bcode.nil? ? {} : { 'filters[bcode]' => bcode }
    data.merge!(opts)
    if view =~ /ecs/
      fetch "#{view}.json/", data
    else
      fetch "views/#{view}.json/", data
    end
  end

  def url_for(path)
    "#{BASE}#{path}"
  end

  def fetch(path, data={}, method=:get)
    url = url_for(path)
    query = data.blank? ? "" : "?#{data.to_query}"
    if method == :get
      puts "Getting: #{url + query}"
      response = Portal.get(url + query, verify: false)
    elsif method == :post
      headers = { 'Content-Type' => 'application/json' }
      response = Portal.post(url, { :body => data.to_json, :headers => headers }, verify: false)
    end
    JSON.parse(response.body) if response.body != ""
  end
end
