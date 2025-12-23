module Neighbor
  class Railtie < Rails::Railtie
    generators do
      # rails generate model Item embedding:vector{3}
      if defined?(Rails::Generators::GeneratedAttribute)
        Rails::Generators::GeneratedAttribute.singleton_class.prepend(Neighbor::GeneratedAttribute)
      end
    end
  end

  module GeneratedAttribute
    def parse_type_and_options(type, *, **)
      if type =~ /\A(vector)\{(\d+)\}\z/
        return $1, limit: $2.to_i
      end
      super
    end
  end
end
