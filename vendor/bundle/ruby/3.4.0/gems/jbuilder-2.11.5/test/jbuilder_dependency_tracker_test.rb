require 'test_helper'
require 'jbuilder/dependency_tracker'


class FakeTemplate
    attr_reader :source, :handler
    def initialize(source, handler = :jbuilder)
      @source, @handler = source, handler
    end
end


class JbuilderDependencyTrackerTest < ActiveSupport::TestCase
    def make_tracker(name, source)
      template = FakeTemplate.new(source)
      Jbuilder::DependencyTracker.new(name, template)
    end

    def track_dependencies(source)
      make_tracker('jbuilder_template', source).dependencies
    end

    test 'detects dependency via direct partial! call' do
      dependencies = track_dependencies <<-RUBY
        json.partial! 'path/to/partial', foo: bar
        json.partial! 'path/to/another/partial', :fizz => buzz
      RUBY

      assert_equal %w[path/to/partial path/to/another/partial], dependencies
    end

    test 'detects dependency via direct partial! call with parens' do
      dependencies = track_dependencies <<-RUBY
        json.partial!("path/to/partial")
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'detects partial with options (1.9 style)' do
      dependencies = track_dependencies <<-RUBY
        json.partial! hello: 'world', partial: 'path/to/partial', foo: :bar
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'detects partial with options (1.8 style)' do
      dependencies = track_dependencies <<-RUBY
        json.partial! :hello => 'world', :partial => 'path/to/partial', :foo => :bar
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'detects partial in indirect collection calls' do
      dependencies = track_dependencies <<-RUBY
        json.comments @post.comments, partial: 'comments/comment', as: :comment
      RUBY

      assert_equal %w[comments/comment], dependencies
    end

    test 'detects explicit dependency' do
      dependencies = track_dependencies <<-RUBY
        # Template Dependency: path/to/partial
        json.foo 'bar'
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end
end
