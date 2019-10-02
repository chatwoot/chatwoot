class Plan
  attr_accessor :key, :attributes

  def initialize(key, attributes={})
    @key = key.to_sym
    @attributes = attributes
  end

  def name
    attributes[:name]
  end

  def id
    attributes[:id]
  end

  def price
    attributes[:price]
  end

  def active
    attributes[:active]
  end

  def version
    attributes[:version]
  end

  class << self
    def config
      Hashie::Mash.new(PLAN_CONFIG)
    end

    def default_trial_period
      (config['trial_period'] || 14).days
    end

    def default_pricing_version
      config['default_pricing_version']
    end

    def default_plans
      load_active_plans + load_inactive_plans
    end

    def all_plans
      default_plans
    end

    def active_plans
      all_plans.select { |plan| plan.active }
    end

    def paid_plan
      active_plans.first
    end

    def inactive_plans
      all_plans.reject(&:active)
    end

    def trial_plan
      all_plans.select { |plan| plan.key == :trial }.first
    end

    def plans_of_version(version)
      all_plans.select { |plan| plan.version == version }
    end

    def find_by_key(key)
      key = key.to_sym
      all_plans.select { |plan| plan.key == key }.first.dup
    end

    ##helpers

    def load_active_plans
      result = []
      Plan.config.active.each_pair do |version, plans|
        plans.each_pair do |key, attributes|
          result << Plan.new(key, attributes.merge(active: true, version: version))
        end
      end
      result
    end

    def load_inactive_plans
      result = []
      Plan.config.inactive.each_pair do |version, plans|
        plans.each_pair do |key, attributes|
          result << Plan.new(key, attributes.merge(active: false, version: version))
        end
      end
      result
    end
  end
end
