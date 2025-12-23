require 'brakeman/tracker/collection'

module Brakeman
  module ControllerMethods
    attr_accessor :layout

    def initialize_controller
      @options[:before_filters] = []
      @options[:skip_filters] = []
      @layout = nil
      @skip_filter_cache = nil
      @before_filter_cache = nil
    end

    def protect_from_forgery?
      @options[:protect_from_forgery]
    end

    def add_before_filter exp
      @options[:before_filters] << exp
    end

    def prepend_before_filter exp
      @options[:before_filters].unshift exp
    end

    def before_filters
      @options[:before_filters]
    end

    def skip_filter exp
      @options[:skip_filters] << exp
    end

    def skip_filters
      @options[:skip_filters]
    end

    def before_filter_list processor, method
      controller = self
      filters = []

      while controller
        filters = controller.get_before_filters(processor, method) + filters

        controller = tracker.controllers[controller.parent] ||
          tracker.libs[controller.parent]
      end

      remove_skipped_filters processor, filters, method
    end

    def get_skipped_filters processor, method
      filters = []

      if @skip_filter_cache.nil?
        @skip_filter_cache = skip_filters.map do |filter|
          before_filter_to_hash(processor, filter.args)
        end
      end

      @skip_filter_cache.each do |f|
        if filter_includes_method? f, method
          filters.concat f[:methods]
        else
        end
      end

      filters
    end


    def remove_skipped_filters processor, filters, method
      controller = self

      while controller
        filters = filters - controller.get_skipped_filters(processor, method)

        controller = tracker.controllers[controller.parent] ||
          tracker.libs[controller.parent]
      end

      filters
    end

    def get_before_filters processor, method
      filters = []

      if @before_filter_cache.nil?
        @before_filter_cache = []

        before_filters.each do |filter|
          @before_filter_cache << before_filter_to_hash(processor, filter.args)
        end
      end

      @before_filter_cache.each do |f|
        if filter_includes_method? f, method
          filters.concat f[:methods]
        end
      end

      filters
    end

    def before_filter_to_hash processor, args
      filter = {}

      #Process args for the uncommon but possible situation
      #in which some variables are used in the filter.
      args.each do |a|
        if sexp? a
          a = processor.process_default a
        end
      end

      filter[:methods] = []

      args.each do |a|
        filter[:methods] << a[1] if a.node_type == :lit
      end

      if args[-1].node_type == :hash
        option = args[-1][1][1]
        value = args[-1][2]
        case value.node_type
        when :array
          filter[option] = value.sexp_body.map {|v| v[1] }
        when :lit, :str
          filter[option] = value[1]
        else
          Brakeman.debug "[Notice] Unknown before_filter value: #{option} => #{value}"
        end
      else
        filter[:all] = true
      end

      filter
    end

    private

    def filter_includes_method? filter_rule, method_name
       filter_rule[:all] or
       (filter_rule[:only] == method_name) or
       (filter_rule[:only].is_a? Array and filter_rule[:only].include? method_name) or
       (filter_rule[:except].is_a? Symbol and filter_rule[:except] != method_name) or
       (filter_rule[:except].is_a? Array and not filter_rule[:except].include? method_name)
    end
  end

  class Controller < Brakeman::Collection
    include ControllerMethods

    def initialize name, parent, file_name, src, tracker
      super
      initialize_controller
      @collection = tracker.controllers
    end
  end
end
