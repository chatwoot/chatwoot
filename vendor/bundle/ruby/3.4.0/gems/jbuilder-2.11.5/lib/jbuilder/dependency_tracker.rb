require 'jbuilder/jbuilder'

dependency_tracker = false

begin
  require 'action_view'
  require 'action_view/dependency_tracker'
  dependency_tracker = ::ActionView::DependencyTracker
rescue LoadError
  begin
    require 'cache_digests'
    dependency_tracker = ::CacheDigests::DependencyTracker
  rescue LoadError
  end
end

if dependency_tracker
  class Jbuilder
    module DependencyTrackerMethods
      # Matches:
      #   json.partial! "messages/message"
      #   json.partial!('messages/message')
      #
      DIRECT_RENDERS = /
        \w+\.partial!     # json.partial!
        \(?\s*            # optional parenthesis
        (['"])([^'"]+)\1  # quoted value
      /x

      # Matches:
      #   json.partial! partial: "comments/comment"
      #   json.comments @post.comments, partial: "comments/comment", as: :comment
      #   json.array! @posts, partial: "posts/post", as: :post
      #   = render partial: "account"
      #
      INDIRECT_RENDERS = /
        (?::partial\s*=>|partial:)  # partial: or :partial =>
        \s*                         # optional whitespace
        (['"])([^'"]+)\1            # quoted value
      /x

      def dependencies
        direct_dependencies + indirect_dependencies + explicit_dependencies
      end

      private

      def direct_dependencies
        source.scan(DIRECT_RENDERS).map(&:second)
      end

      def indirect_dependencies
        source.scan(INDIRECT_RENDERS).map(&:second)
      end
    end
  end

  ::Jbuilder::DependencyTracker = Class.new(dependency_tracker::ERBTracker)
  ::Jbuilder::DependencyTracker.send :include, ::Jbuilder::DependencyTrackerMethods
  dependency_tracker.register_tracker :jbuilder, ::Jbuilder::DependencyTracker
end
