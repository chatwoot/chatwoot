module Hashie
  module Extensions
    module Mash
      module DefineAccessors
        def self.included(klass)
          klass.class_eval do
            mod = Ext.new
            include mod
          end
        end

        def self.extended(obj)
          included(obj.singleton_class)
        end

        class Ext < Module
          def initialize
            mod = self
            define_method(:method_missing) do |method_name, *args, &block|
              key, suffix = method_name_and_suffix(method_name)
              case suffix
              when '='.freeze
                mod.define_writer(key, method_name)
              when '?'.freeze
                mod.define_predicate(key, method_name)
              when '!'.freeze
                mod.define_initializing_reader(key, method_name)
              when '_'.freeze
                mod.define_underbang_reader(key, method_name)
              else
                mod.define_reader(key, method_name)
              end
              send(method_name, *args, &block)
            end
          end

          def define_reader(key, method_name)
            define_method(method_name) do |&block|
              if key? method_name
                self.[](method_name, &block)
              else
                self.[](key, &block)
              end
            end
          end

          def define_writer(key, method_name)
            define_method(method_name) do |value = nil|
              if key? method_name
                self.[](method_name, &proc)
              else
                assign_property(key, value)
              end
            end
          end

          def define_predicate(key, method_name)
            define_method(method_name) do
              if key? method_name
                self.[](method_name, &proc)
              else
                !!self[key]
              end
            end
          end

          def define_initializing_reader(key, method_name)
            define_method(method_name) do
              if key? method_name
                self.[](method_name, &proc)
              else
                initializing_reader(key)
              end
            end
          end

          def define_underbang_reader(key, method_name)
            define_method(method_name) do
              if key? method_name
                self.[](key, &proc)
              else
                underbang_reader(key)
              end
            end
          end
        end
      end
    end
  end
end
