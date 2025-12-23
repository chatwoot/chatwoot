# frozen_string_literal: true

require_relative 'presenter'
require_relative 'global'

module Rainbow
  refine String do
    Presenter.instance_methods(false).each do |method_name|
      define_method(method_name) do |*args|
        ::Rainbow.global.wrap(self).send(method_name, *args)
      end
    end
  end
end
