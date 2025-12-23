dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')
require 'pp'
config = YAML.load(File.read(File.join(ENV['HOME'], '.delicious')))

class Delicious
  include HTTParty
  base_uri 'https://api.del.icio.us/v1'

  def initialize(u, p)
    @auth = { username: u, password: p }
  end

  # query params that filter the posts are:
  #   tag (optional). Filter by this tag.
  #   dt (optional). Filter by this date (CCYY-MM-DDThh:mm:ssZ).
  #   url (optional). Filter by this url.
  #   ie: posts(query: {tag: 'ruby'})
  def posts(options = {})
    options.merge!({ basic_auth: @auth })
    self.class.get('/posts/get', options)
  end

  # query params that filter the posts are:
  #   tag (optional). Filter by this tag.
  #   count (optional). Number of items to retrieve (Default:15, Maximum:100).
  def recent(options = {})
    options.merge!({ basic_auth: @auth })
    self.class.get('/posts/recent', options)
  end
end

delicious = Delicious.new(config['username'], config['password'])
pp delicious.posts(query: { tag: 'ruby' })
pp delicious.recent

delicious.recent['posts']['post'].each { |post| puts post['href'] }
