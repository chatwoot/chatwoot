# frozen_string_literal: true

require 'action_view'

module Haml
  class ErubiTemplateHandler < ActionView::Template::Handlers::ERB::Erubi

    def initialize(*args, &blk)
      @newline_pending = 0
      super
    end
  end

  class SafeErubiTemplate < Tilt::ErubiTemplate
    def prepare
      @options.merge! engine_class: Haml::ErubiTemplateHandler
      super
    end
  end
end
