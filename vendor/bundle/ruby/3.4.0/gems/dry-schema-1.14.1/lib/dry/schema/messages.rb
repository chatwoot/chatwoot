# frozen_string_literal: true

module Dry
  module Schema
    # An API for configuring message backends
    #
    # @api private
    module Messages
      BACKENDS = {
        i18n: "I18n",
        yaml: "YAML"
      }.freeze

      module_function

      public def setup(config)
        backend_class = BACKENDS.fetch(config.backend) do
          raise "+#{config.backend}+ is not a valid messages identifier"
        end

        namespace = config.namespace
        options = config.to_h.select { |k, _| Abstract.setting_names.include?(k) }

        messages = Messages.const_get(backend_class).build(options)

        return messages.namespaced(namespace) if namespace

        messages
      end
    end
  end
end
