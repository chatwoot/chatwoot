# frozen_string_literal: true

module Zeitwerk
  class Error < StandardError
  end

  class ReloadingDisabledError < Error
    def initialize
      super("can't reload, please call loader.enable_reloading before setup")
    end
  end

  class NameError < ::NameError
  end

  class SetupRequired < Error
    def initialize
      super("please, finish your configuration and call Zeitwerk::Loader#setup once all is ready")
    end
  end
end
