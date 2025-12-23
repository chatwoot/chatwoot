module Shoulda
  module Matchers
    module Integrations
      # @private
      module Inclusion
        def include_into(mod, *other_mods, &block)
          mods_to_include = other_mods.dup
          mods_to_extend = other_mods.dup

          if block
            mods_to_include << Module.new(&block)
          end

          mod.__send__(:include, *mods_to_include)
          mod.extend(*mods_to_extend)
        end
      end
    end
  end
end
