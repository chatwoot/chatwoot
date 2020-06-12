class Integrations::App
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def id
    params[:id]
  end

  def name
    params[:name]
  end

  def description
    params[:description]
  end

  def logo
    params[:logo]
  end

  def fields
    params[:fields]
  end

  def button
    params[:button]
  end

  def enabled?(account)
    account.hooks.where(app_id: id).exists?
  end

  class << self
    def apps
      Hashie::Mash.new(APPS_CONFIG)
    end

    def all
      apps.values.each_with_object([]) do |app, result|
        result << new(app)
      end
    end

    def find(params)
      all.detect { |app| app.id == params[:id] }
    end
  end
end
