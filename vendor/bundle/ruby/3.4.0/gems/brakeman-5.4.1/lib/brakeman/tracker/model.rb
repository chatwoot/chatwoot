require 'brakeman/tracker/collection'

module Brakeman
  module ModelMethods
    attr_reader :associations, :attr_accessible, :role_accessible

    def initialize_model
      @associations = {}
      @role_accessible = []
      @attr_accessible = nil
    end

    def association? method_name
      @associations.each do |name, args|
        args.each do |arg|
          if symbol? arg and arg.value == method_name
            return true
          end
        end
      end

      false
    end

    def unprotected_model?
      @attr_accessible.nil? and !parent_classes_protected? and ancestor?(:"ActiveRecord::Base")
    end

    # go up the chain of parent classes to see if any have attr_accessible
    def parent_classes_protected? seen={}
      seen[self.name] = true

      if @attr_accessible or self.includes.include? :"ActiveModel::ForbiddenAttributesProtection"
        true
      elsif parent = tracker.models[self.parent] and !seen[self.parent]
        parent.parent_classes_protected? seen
      else
        false
      end
    end

    def set_attr_accessible exp = nil
      if exp
        args = []

        exp.each_arg do |e|
          if node_type? e, :lit
            args << e.value
          elsif hash? e
            @role_accessible.concat args
          end
        end

        @attr_accessible ||= []
        @attr_accessible.concat args
      else
        @attr_accessible ||= []
      end
    end

    def set_attr_protected exp
      add_option :attr_protected, exp
    end

    def attr_protected
      @options[:attr_protected]
    end
  end

  class Model < Brakeman::Collection
    include ModelMethods

    ASSOCIATIONS = Set[:belongs_to, :has_one, :has_many, :has_and_belongs_to_many]

    def initialize name, parent, file_name, src, tracker
      super
      initialize_model
      @collection = tracker.models
    end

    def add_option name, exp
      if ASSOCIATIONS.include? name
        @associations[name] ||= []
        @associations[name].concat exp.args
      else
        super name, exp.arglist.line(exp.line)
      end
    end
  end
end
