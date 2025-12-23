module Hashie
  module Extensions
    # SRP: This extension will fail an error whenever a key is accessed
    #   that does not exist in the hash.
    #
    #   EXAMPLE:
    #
    #     class StrictKeyAccessHash < Hash
    #       include Hashie::Extensions::StrictKeyAccess
    #     end
    #
    #     >> hash = StrictKeyAccessHash[foo: "bar"]
    #     => {:foo=>"bar"}
    #     >> hash[:foo]
    #     => "bar"
    #     >> hash[:cow]
    #       KeyError: key not found: :cow
    #
    # NOTE: For googlers coming from Python to Ruby, this extension makes a Hash
    # behave more like a "Dictionary".
    #
    module StrictKeyAccess
      class DefaultError < StandardError
        def initialize
          super('Setting or using a default with Hashie::Extensions::StrictKeyAccess'\
                ' does not make sense'
          )
        end
      end

      # NOTE: Defaults don't make any sense with a StrictKeyAccess.
      # NOTE: When key lookup fails a KeyError is raised.
      #
      # Normal:
      #
      #     >> a = Hash.new(123)
      #     => {}
      #     >> a["noes"]
      #     => 123
      #
      # With StrictKeyAccess:
      #
      #     >> a = StrictKeyAccessHash.new(123)
      #     => {}
      #     >> a["noes"]
      #       KeyError: key not found: "noes"
      #
      def [](key)
        fetch(key)
      end

      def default(_ = nil)
        raise DefaultError
      end

      def default=(_)
        raise DefaultError
      end

      def default_proc
        raise DefaultError
      end

      def default_proc=(_)
        raise DefaultError
      end

      def key(value)
        super.tap do |result|
          if result.nil? && (!key?(result) || self[result] != value)
            raise KeyError, "key not found with value of #{value.inspect}"
          end
        end
      end
    end
  end
end
