require 'brakeman/tracker/collection'
require 'brakeman/tracker/controller'
require 'brakeman/tracker/model'

module Brakeman
  class Library < Brakeman::Collection
    include ControllerMethods
    include ModelMethods

    def initialize name, parent, file_name, src, tracker
      super
      initialize_controller
      initialize_model
      @collection = tracker.libs
    end
  end
end
