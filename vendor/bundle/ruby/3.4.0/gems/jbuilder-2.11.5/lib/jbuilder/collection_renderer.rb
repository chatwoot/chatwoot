require 'delegate'
require 'active_support/concern'
require 'action_view'

begin
  require 'action_view/renderer/collection_renderer'
rescue LoadError
  require 'action_view/renderer/partial_renderer'
end

class Jbuilder
  module CollectionRenderable # :nodoc:
    extend ActiveSupport::Concern

    class_methods do
      def supported?
        superclass.private_method_defined?(:build_rendered_template) && self.superclass.private_method_defined?(:build_rendered_collection)
      end
    end

    private

    def build_rendered_template(content, template, layout = nil)
      super(content || json.attributes!, template)
    end

    def build_rendered_collection(templates, _spacer)
      json.merge!(templates.map(&:body))
    end

    def json
      @options[:locals].fetch(:json)
    end

    class ScopedIterator < ::SimpleDelegator # :nodoc:
      include Enumerable

      def initialize(obj, scope)
        super(obj)
        @scope = scope
      end

      # Rails 6.0 support:
      def each
        return enum_for(:each) unless block_given?

        __getobj__.each do |object|
          @scope.call { yield(object) }
        end
      end

      # Rails 6.1 support:
      def each_with_info
        return enum_for(:each_with_info) unless block_given?

        __getobj__.each_with_info do |object, info|
          @scope.call { yield(object, info) }
        end
      end
    end

    private_constant :ScopedIterator
  end

  if defined?(::ActionView::CollectionRenderer)
    # Rails 6.1 support:
    class CollectionRenderer < ::ActionView::CollectionRenderer # :nodoc:
      include CollectionRenderable

      def initialize(lookup_context, options, &scope)
        super(lookup_context, options)
        @scope = scope
      end

      private
        def collection_with_template(view, template, layout, collection)
          super(view, template, layout, ScopedIterator.new(collection, @scope))
        end
    end
  else
    # Rails 6.0 support:
    class CollectionRenderer < ::ActionView::PartialRenderer # :nodoc:
      include CollectionRenderable

      def initialize(lookup_context, options, &scope)
        super(lookup_context)
        @options = options
        @scope = scope
      end

      def render_collection_with_partial(collection, partial, context, block)
        render(context, @options.merge(collection: collection, partial: partial), block)
      end

      private
        def collection_without_template(view)
          @collection = ScopedIterator.new(@collection, @scope)

          super(view)
        end

        def collection_with_template(view, template)
          @collection = ScopedIterator.new(@collection, @scope)

          super(view, template)
        end
    end
  end
end
