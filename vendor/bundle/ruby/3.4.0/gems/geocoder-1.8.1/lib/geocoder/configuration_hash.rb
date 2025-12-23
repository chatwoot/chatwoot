module Geocoder
  class ConfigurationHash < Hash
    def method_missing(meth, *args, &block)
      has_key?(meth) ? self[meth] : super
    end

    def respond_to_missing?(meth, include_private = false)
      has_key?(meth) || super
    end
  end
end
