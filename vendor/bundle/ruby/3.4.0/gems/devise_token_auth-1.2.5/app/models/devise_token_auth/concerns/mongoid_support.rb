module DeviseTokenAuth::Concerns::MongoidSupport
  extend ActiveSupport::Concern

  def as_json(options = {})
    options[:except] = (options[:except] || []) + [:_id]
    hash = super(options)
    hash['id'] = to_param
    hash
  end

  class_methods do
    # It's abstract replacement .find_by
    def dta_find_by(attrs = {})
      find_by(attrs)
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end
end
