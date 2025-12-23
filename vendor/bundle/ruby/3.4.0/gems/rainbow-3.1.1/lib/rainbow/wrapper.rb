# frozen_string_literal: true

require_relative 'presenter'
require_relative 'null_presenter'

module Rainbow
  class Wrapper
    attr_accessor :enabled

    def initialize(enabled = true)
      @enabled = enabled
    end

    def wrap(string)
      if enabled
        Presenter.new(string.to_s)
      else
        NullPresenter.new(string.to_s)
      end
    end
  end
end
