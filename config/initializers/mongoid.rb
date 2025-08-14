Mongoid.configure do |config|
  config.load!(Rails.root.join('config', 'mongoid.yml'), :development) if Rails.env.development?
  config.load!(Rails.root.join('config', 'mongoid.yml'), :test) if Rails.env.test?
  config.load!(Rails.root.join('config', 'mongoid.yml'), :production) if Rails.env.production?
end
