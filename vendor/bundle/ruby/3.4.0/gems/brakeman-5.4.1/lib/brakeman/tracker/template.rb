require 'brakeman/tracker/collection'

module Brakeman
  class Template < Brakeman::Collection
    attr_accessor :type
    attr_reader :render_path
    attr_writer :src

    def initialize name, called_from, file_name, tracker
      super name, nil, file_name, nil, tracker
      @render_path = called_from
      @outputs = []
    end

    def add_output exp
      @outputs << exp
    end

    def each_output
      @outputs.each do |o|
        yield o
      end
    end

    def rendered_from_controller?
      if @render_path
        @render_path.rendered_from_controller?
      else
        false
      end
    end
  end
end
