# frozen_string_literal: true

require 'rainbow'

module Rainbow
  module Ext
    module String
      module InstanceMethods
        def foreground(*color)
          Rainbow(self).foreground(*color)
        end

        alias color foreground
        alias colour foreground

        def background(*color)
          Rainbow(self).background(*color)
        end

        def reset
          Rainbow(self).reset
        end

        def bright
          Rainbow(self).bright
        end

        def faint
          Rainbow(self).faint
        end

        def italic
          Rainbow(self).italic
        end

        def underline
          Rainbow(self).underline
        end

        def blink
          Rainbow(self).blink
        end

        def inverse
          Rainbow(self).inverse
        end

        def hide
          Rainbow(self).hide
        end

        def cross_out
          Rainbow(self).cross_out
        end

        alias strike cross_out
      end
    end
  end
end

class String
  include Rainbow::Ext::String::InstanceMethods
end
