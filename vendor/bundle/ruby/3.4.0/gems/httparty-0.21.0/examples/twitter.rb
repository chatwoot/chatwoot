dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')
require 'pp'
config = YAML.load(File.read(File.join(ENV['HOME'], '.twitter')))

class Twitter
  include HTTParty
  base_uri 'twitter.com'

  def initialize(u, p)
    @auth = {username: u, password: p}
  end

  # which can be :friends, :user or :public
  # options[:query] can be things like since, since_id, count, etc.
  def timeline(which = :friends, options = {})
    options.merge!({ basic_auth: @auth })
    self.class.get("/statuses/#{which}_timeline.json", options)
  end

  def post(text)
    options = { query: { status: text }, basic_auth: @auth }
    self.class.post('/statuses/update.json', options)
  end
end

twitter = Twitter.new(config['email'], config['password'])
pp twitter.timeline
# pp twitter.timeline(:friends, query: {since_id: 868482746})
# pp twitter.timeline(:friends, query: 'since_id=868482746')
# pp twitter.post('this is a test of 0.2.0')
