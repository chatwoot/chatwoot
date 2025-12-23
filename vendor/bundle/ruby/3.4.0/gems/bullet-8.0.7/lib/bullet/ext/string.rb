# frozen_string_literal: true

module Bullet
  module Ext
    module String
      refine ::String do
        def bullet_class_name
          last_colon = self.rindex(':')
          last_colon ? self[0...last_colon].dup : self.dup
        end
      end
    end
  end
end
