# frozen_string_literal: true

class CustomCoder
  def load(value)
    if value.nil?
      {}
    else
      YAML.load(value)
    end
  end

  def dump(value)
    YAML.dump(value)
  end
end

class Widget < ActiveRecord::Base
  self.primary_key = :w_id

  default_scope -> { where(active: true) }

  if ENV['AR_VERSION'].to_f >= 7.1
    serialize :data, coder: YAML
    serialize :json_data, coder: JSON
    serialize :custom_data, coder: CustomCoder.new
  else
    serialize :data, Hash
    serialize :json_data, JSON
    serialize :custom_data, CustomCoder.new
  end

  serialize :unspecified_data
end
