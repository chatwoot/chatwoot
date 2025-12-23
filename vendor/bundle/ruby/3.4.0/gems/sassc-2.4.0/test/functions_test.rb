# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

module SassC
  class FunctionsTest < MiniTest::Test
    include FixtureHelper

    def setup
      @real_stderr, $stderr = $stderr, StringIO.new
    end

    def teardown
      $stderr = @real_stderr
    end

    def test_functions_may_return_sass_string_type
      assert_sass <<-SCSS, <<-CSS
        div { url: url(sass_return_path("foo.svg")); }
      SCSS
        div { url: url("foo.svg"); }
      CSS
    end

    def test_functions_work_with_varying_quotes_and_string_types
      assert_sass <<-SCSS, <<-CSS
        div {
           url: url(asset-path("foo.svg"));
           url: url(image-path("foo.png"));
           url: url(video-path("foo.mov"));
           url: url(audio-path("foo.mp3"));
           url: url(font-path("foo.woff"));
           url: url(javascript-path('foo.js'));
           url: url(javascript-path("foo.js"));
           url: url(stylesheet-path("foo.css"));
        }
      SCSS
        div {
          url: url(asset-path("foo.svg"));
          url: url(image-path("foo.png"));
          url: url(video-path("foo.mov"));
          url: url(audio-path("foo.mp3"));
          url: url(font-path("foo.woff"));
          url: url("/js/foo.js");
          url: url("/js/foo.js");
          url: url(/css/foo.css);
        }
      CSS
    end

    def test_function_with_no_return_value
      assert_sass <<-SCSS, <<-CSS
        div {url: url(no-return-path('foo.svg'));}
      SCSS
        div { url: url(); }
      CSS
    end

    def test_function_that_returns_a_color
      assert_sass <<-SCSS, <<-CSS
        div { background: returns-a-color(); }
      SCSS
        div { background: black; }
      CSS
    end

    def test_function_that_returns_a_number
      assert_sass <<-SCSS, <<-CSS
        div { width: returns-a-number(); }
      SCSS
        div { width: -312rem; }
      CSS
    end

    def test_function_that_takes_a_number
      assert_sass <<-SCSS, <<-CSS
        div { display: inspect-number(42.1px); }
      SCSS
        div { display: 42.1px; }
      CSS
    end

    def test_function_that_returns_a_bool
      assert_sass <<-SCSS, <<-CSS
        div { width: returns-a-bool(); }
      SCSS
        div { width: true; }
      CSS
    end

    def test_function_that_takes_a_bool
      assert_sass <<-SCSS, <<-CSS
        div { display: inspect-bool(true)}
      SCSS
        div { display: true; }
      CSS
    end

    def test_function_with_optional_arguments
      assert_sass <<-SCSS, <<-EXPECTED_CSS
        div {
          url: optional_arguments('first');
          url: optional_arguments('second', 'qux');
        }
      SCSS
        div {
          url: "first/bar";
          url: "second/qux";
        }
      EXPECTED_CSS
    end

    def test_functions_may_accept_sass_color_type
      assert_sass <<-SCSS, <<-EXPECTED_CSS
        div { color: nice_color_argument(red); }
      SCSS
        div { color: rgb(255, 0, 0); }
      EXPECTED_CSS
    end

    def test_function_with_unsupported_tag
      skip('What are other unsupported tags?')
      engine = Engine.new("div {url: function_with_unsupported_tag(());}")

      exception = assert_raises(SassC::SyntaxError) do
        engine.render
      end

      assert_match /Sass argument of type sass_list unsupported/, exception.message
      assert_equal "[SassC::FunctionsHandler] Sass argument of type sass_list unsupported", stderr_output
    end

    def test_function_with_error
      engine = Engine.new("div {url: function_that_raises_errors();}")

      exception = assert_raises(SassC::SyntaxError) do
        engine.render
      end

      assert_match /Error: error in C function function_that_raises_errors/, exception.message
      assert_match /Intentional wrong thing happened somewhere inside the custom function/, exception.message
      assert_match /\[SassC::FunctionsHandler\] Intentional wrong thing happened somewhere inside the custom function/, stderr_output
    end

    def test_function_that_returns_a_sass_value
      assert_sass <<-SCSS, <<-CSS
        div { background: returns-sass-value(); }
      SCSS
        div { background: black; }
      CSS
    end

    def test_function_that_returns_a_sass_map
      assert_sass <<-SCSS, <<-CSS
        $my-map: returns-sass-map();
        div { background: map-get( $my-map, color ); }
      SCSS
        div { background: black; }
      CSS
    end

    def test_function_that_takes_a_sass_map
      assert_sass <<-SCSS, <<-CSS
        div { background-color: map-get( inspect-map(( color: black, number: 1.23px, string: "abc", map: ( x: 'y' ))), color ); }
      SCSS
        div { background-color: black; }
      CSS
    end

    def test_function_that_returns_a_sass_list
      assert_sass <<-SCSS, <<-CSS
        $my-list: returns-sass-list();
        div { width: nth( $my-list, 2 ); }
      SCSS
        div { width: 20; }
      CSS
    end

    def test_function_that_takes_a_sass_list
      assert_sass <<-SCSS, <<-CSS
        div { width: nth(inspect-list((10 20 30)), 2); }
      SCSS
        div { width: 20; }
      CSS
    end

    def test_concurrency
      10.times do
        threads = []
        10.times do |i|
          threads << Thread.new(i) do |id|
            out = Engine.new("div { url: inspect_options(); }", {test_key1: 'test_value', test_key2: id}).render
            assert_match /test_key1/, out
            assert_match /test_key2/, out
            assert_match /test_value/, out
            assert_match /#{id}/, out
          end
        end
        threads.each(&:join)
      end
    end

    def test_pass_custom_functions_as_a_parameter
      out = Engine.new("div { url: test-function(); }", {functions: ExternalFunctions}).render
      assert_match /custom_function/, out
    end

    def test_pass_incompatible_type_to_custom_functions
      assert_raises(TypeError) do
        Engine.new("div { url: test-function(); }", {functions: Class.new}).render
      end
    end

    private

    def assert_sass(sass, expected_css)
      engine = Engine.new(sass)
      assert_equal expected_css.strip.gsub!(/\s+/, " "), # poor man's String#squish
                   engine.render.strip.gsub!(/\s+/, " ")
    end

    def stderr_output
      $stderr.string.gsub("\u0000\n", '').chomp
    end

    module Script::Functions

      def javascript_path(path)
        SassC::Script::Value::String.new("/js/#{path.value}", :string)
      end

      def stylesheet_path(path)
        SassC::Script::Value::String.new("/css/#{path.value}", :identifier)
      end

      def no_return_path(path)
        nil
      end

      def sass_return_path(path)
        SassC::Script::Value::String.new("#{path.value}", :string)
      end

      def optional_arguments(path, optional = nil)
        optional ||= SassC::Script::Value::String.new("bar")
        SassC::Script::Value::String.new("#{path.value}/#{optional.value}", :string)
      end

      def function_that_raises_errors
        raise StandardError, "Intentional wrong thing happened somewhere inside the custom function"
      end

      def function_with_unsupported_tag(value)
      end

      def nice_color_argument(color)
        return SassC::Script::Value::String.new(color.to_s, :identifier)
      end

      def returns_a_color
        return SassC::Script::Value::Color.new(red: 0, green: 0, blue: 0)
      end

      def returns_a_number
        return SassC::Script::Value::Number.new(-312,'rem')
      end

      def returns_a_bool
        return SassC::Script::Value::Bool.new(true)
      end

      def inspect_bool ( argument )
        raise StandardError.new "passed value is not a Sass::Script::Value::Bool" unless argument.is_a? SassC::Script::Value::Bool
        return argument
      end

      def inspect_number ( argument )
        raise StandardError.new "passed value is not a Sass::Script::Value::Number" unless argument.is_a? SassC::Script::Value::Number
        return argument
      end

      def inspect_map ( argument )
        argument.to_h.each_pair do |key, value|
          raise StandardError.new "key #{key.inspect} is not a string" unless key.is_a? SassC::Script::Value::String

          valueClass = case key.value
                         when 'string'
                           SassC::Script::Value::String
                         when 'number'
                           SassC::Script::Value::Number
                         when 'color'
                           SassC::Script::Value::Color
                         when 'map'
                           SassC::Script::Value::Map
                       end

          raise StandardError.new "unknown key #{key.inspect}" unless valueClass
          raise StandardError.new "value for #{key.inspect} is not a #{valueClass}" unless value.is_a? valueClass
        end
        return argument
      end

      def inspect_list(argument)
        raise StandardError.new "passed value is not a Sass::Script::Value::List" unless argument.is_a? SassC::Script::Value::List
        return argument
      end

      def inspect_options
        SassC::Script::Value::String.new(self.options.inspect, :string)
      end

      def returns_sass_value
        return SassC::Script::Value::Color.new(red: 0, green: 0, blue: 0)
      end

      def returns_sass_map
        key = SassC::Script::Value::String.new("color", "string")
        value = SassC::Script::Value::Color.new(red: 0, green: 0, blue: 0)
        values = {}
        values[key] = value
        map = SassC::Script::Value::Map.new values
        return map
      end

      def returns_sass_list
        numbers = [10, 20, 30].map { |n| SassC::Script::Value::Number.new(n, '') }
        SassC::Script::Value::List.new(numbers, separator: :space)
      end

    end

    module ExternalFunctions
      def test_function
        SassC::Script::Value::String.new("custom_function", :string)
      end
    end

  end
end
