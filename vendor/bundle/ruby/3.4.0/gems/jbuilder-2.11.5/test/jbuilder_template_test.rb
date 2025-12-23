require "test_helper"
require "action_view/testing/resolvers"

class JbuilderTemplateTest < ActiveSupport::TestCase
  POST_PARTIAL = <<-JBUILDER
    json.extract! post, :id, :body
    json.author do
      first_name, last_name = post.author_name.split(nil, 2)
      json.first_name first_name
      json.last_name last_name
    end
  JBUILDER

  COLLECTION_PARTIAL = <<-JBUILDER
    json.extract! collection, :id, :name
  JBUILDER

  RACER_PARTIAL = <<-JBUILDER
    json.extract! racer, :id, :name
  JBUILDER

  PARTIALS = {
    "_partial.json.jbuilder"      => "json.content content",
    "_post.json.jbuilder"         => POST_PARTIAL,
    "racers/_racer.json.jbuilder" => RACER_PARTIAL,
    "_collection.json.jbuilder"   => COLLECTION_PARTIAL,

    # Ensure we find only Jbuilder partials from within Jbuilder templates.
    "_post.html.erb" => "Hello world!"
  }

  AUTHORS = [ "David Heinemeier Hansson", "Pavel Pravosud" ].cycle
  POSTS   = (1..10).collect { |i| Post.new(i, "Post ##{i}", AUTHORS.next) }

  setup { Rails.cache.clear }

  test "basic template" do
    result = render('json.content "hello"')
    assert_equal "hello", result["content"]
  end

  test "partial by name with top-level locals" do
    result = render('json.partial! "partial", content: "hello"')
    assert_equal "hello", result["content"]
  end

  test "partial by name with nested locals" do
    result = render('json.partial! "partial", locals: { content: "hello" }')
    assert_equal "hello", result["content"]
  end

  test "partial by options containing nested locals" do
    result = render('json.partial! partial: "partial", locals: { content: "hello" }')
    assert_equal "hello", result["content"]
  end

  test "partial by options containing top-level locals" do
    result = render('json.partial! partial: "partial", content: "hello"')
    assert_equal "hello", result["content"]
  end

  test "partial for Active Model" do
    result = render('json.partial! @racer', racer: Racer.new(123, "Chris Harris"))
    assert_equal 123, result["id"]
    assert_equal "Chris Harris", result["name"]
  end

  test "partial collection by name with symbol local" do
    result = render('json.partial! "post", collection: @posts, as: :post', posts: POSTS)
    assert_equal 10, result.count
    assert_equal "Post #5", result[4]["body"]
    assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
    assert_equal "Pavel", result[5]["author"]["first_name"]
  end

  test "partial collection by name with string local" do
    result = render('json.partial! "post", collection: @posts, as: "post"', posts: POSTS)
    assert_equal 10, result.count
    assert_equal "Post #5", result[4]["body"]
    assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
    assert_equal "Pavel", result[5]["author"]["first_name"]
  end

  test "partial collection by options" do
    result = render('json.partial! partial: "post", collection: @posts, as: :post', posts: POSTS)
    assert_equal 10, result.count
    assert_equal "Post #5", result[4]["body"]
    assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
    assert_equal "Pavel", result[5]["author"]["first_name"]
  end

  test "nil partial collection by name" do
    assert_equal [], render('json.partial! "post", collection: @posts, as: :post', posts: nil)
  end

  test "nil partial collection by options" do
    assert_equal [], render('json.partial! partial: "post", collection: @posts, as: :post', posts: nil)
  end

  test "array of partials" do
    result = render('json.array! @posts, partial: "post", as: :post', posts: POSTS)
    assert_equal 10, result.count
    assert_equal "Post #5", result[4]["body"]
    assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
    assert_equal "Pavel", result[5]["author"]["first_name"]
  end

  test "empty array of partials from nil collection" do
    assert_equal [], render('json.array! @posts, partial: "post", as: :post', posts: nil)
  end

  test "array of partials under key" do
    result = render('json.posts @posts, partial: "post", as: :post', posts: POSTS)
    assert_equal 10, result["posts"].count
    assert_equal "Post #5", result["posts"][4]["body"]
    assert_equal "Heinemeier Hansson", result["posts"][2]["author"]["last_name"]
    assert_equal "Pavel", result["posts"][5]["author"]["first_name"]
  end

  test "empty array of partials under key from nil collection" do
    result = render('json.posts @posts, partial: "post", as: :post', posts: nil)
    assert_equal [], result["posts"]
  end

  test "object fragment caching" do
    render(<<-JBUILDER)
      json.cache! "cache-key" do
        json.name "Hit"
      end
    JBUILDER

    hit = render('json.cache! "cache-key" do; end')
    assert_equal "Hit", hit["name"]
  end

  test "conditional object fragment caching" do
    render(<<-JBUILDER)
      json.cache_if! true, "cache-key" do
        json.a "Hit"
      end

      json.cache_if! false, "cache-key" do
        json.b "Hit"
      end
    JBUILDER

    result = render(<<-JBUILDER)
      json.cache_if! true, "cache-key" do
        json.a "Miss"
      end

      json.cache_if! false, "cache-key" do
        json.b "Miss"
      end
    JBUILDER

    assert_equal "Hit", result["a"]
    assert_equal "Miss", result["b"]
  end

  test "object fragment caching with expiry" do
    travel_to Time.iso8601("2018-05-12T11:29:00-04:00")

    render <<-JBUILDER
      json.cache! "cache-key", expires_in: 1.minute do
        json.name "Hit"
      end
    JBUILDER

    travel 30.seconds

    result = render(<<-JBUILDER)
      json.cache! "cache-key", expires_in: 1.minute do
        json.name "Miss"
      end
    JBUILDER

    assert_equal "Hit", result["name"]

    travel 31.seconds

    result = render(<<-JBUILDER)
      json.cache! "cache-key", expires_in: 1.minute do
        json.name "Miss"
      end
    JBUILDER

    assert_equal "Miss", result["name"]
  end

  test "object root caching" do
    render <<-JBUILDER
      json.cache_root! "cache-key" do
        json.name "Hit"
      end
    JBUILDER

    assert_equal JSON.dump(name: "Hit"), Rails.cache.read("jbuilder/root/cache-key")

    result = render(<<-JBUILDER)
      json.cache_root! "cache-key" do
        json.name "Miss"
      end
    JBUILDER

    assert_equal "Hit", result["name"]
  end

  test "array fragment caching" do
    render <<-JBUILDER
      json.cache! "cache-key" do
        json.array! %w[ a b c ]
      end
    JBUILDER

    assert_equal %w[ a b c ], render('json.cache! "cache-key" do; end')
  end

  test "array root caching" do
    render <<-JBUILDER
      json.cache_root! "cache-key" do
        json.array! %w[ a b c ]
      end
    JBUILDER

    assert_equal JSON.dump(%w[ a b c ]), Rails.cache.read("jbuilder/root/cache-key")

    assert_equal %w[ a b c ], render(<<-JBUILDER)
      json.cache_root! "cache-key" do
        json.array! %w[ d e f ]
      end
    JBUILDER
  end

  test "failing to cache root after JSON structures have been defined" do
    assert_raises ActionView::Template::Error, "cache_root! can't be used after JSON structures have been defined" do
      render <<-JBUILDER
        json.name "Kaboom"
        json.cache_root! "cache-key" do
          json.name "Miss"
        end
      JBUILDER
    end
  end

  test "empty fragment caching" do
    render 'json.cache! "nothing" do; end'

    result = nil

    assert_nothing_raised do
      result = render(<<-JBUILDER)
        json.foo "bar"
        json.cache! "nothing" do; end
      JBUILDER
    end

    assert_equal "bar", result["foo"]
  end

  test "cache instrumentation" do
    payloads = {}

    ActiveSupport::Notifications.subscribe("read_fragment.action_controller") { |*args| payloads[:read] = args.last }
    ActiveSupport::Notifications.subscribe("write_fragment.action_controller") { |*args| payloads[:write] = args.last }

    render <<-JBUILDER
      json.cache! "cache-key" do
        json.name "Cache"
      end
    JBUILDER

    assert_equal "jbuilder/cache-key", payloads[:read][:key]
    assert_equal "jbuilder/cache-key", payloads[:write][:key]
  end

  test "camelized keys" do
    result = render(<<-JBUILDER)
      json.key_format! camelize: [:lower]
      json.first_name "David"
    JBUILDER

    assert_equal "David", result["firstName"]
  end

  if JbuilderTemplate::CollectionRenderer.supported?
    test "returns an empty array for an empty collection" do
      result = render('json.array! @posts, partial: "post", as: :post, cached: true', posts: [])

      # Do not use #assert_empty as it is important to ensure that the type of the JSON result is an array.
      assert_equal [], result
    end

    test "works with an enumerable object" do
      enumerable_class = Class.new do
        include Enumerable
        alias length count # Rails 6.1 requires this.

        def each(&block)
          [].each(&block)
        end
      end

      result = render('json.array! @posts, partial: "post", as: :post, cached: true', posts: enumerable_class.new)

      # Do not use #assert_empty as it is important to ensure that the type of the JSON result is an array.
      assert_equal [], result
    end

    test "supports the cached: true option" do
      result = render('json.array! @posts, partial: "post", as: :post, cached: true', posts: POSTS)

      assert_equal 10, result.count
      assert_equal "Post #5", result[4]["body"]
      assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
      assert_equal "Pavel", result[5]["author"]["first_name"]

      expected = {
        "id" => 1,
        "body" => "Post #1",
        "author" => {
          "first_name" => "David",
          "last_name" => "Heinemeier Hansson"
        }
      }

      assert_equal expected, Rails.cache.read("post-1")

      result = render('json.array! @posts, partial: "post", as: :post, cached: true', posts: POSTS)

      assert_equal 10, result.count
      assert_equal "Post #5", result[4]["body"]
      assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
      assert_equal "Pavel", result[5]["author"]["first_name"]
    end

    test "supports the cached: ->() {} option" do
      result = render('json.array! @posts, partial: "post", as: :post, cached: ->(post) { [post, "foo"] }', posts: POSTS)

      assert_equal 10, result.count
      assert_equal "Post #5", result[4]["body"]
      assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
      assert_equal "Pavel", result[5]["author"]["first_name"]

      expected = {
        "id" => 1,
        "body" => "Post #1",
        "author" => {
          "first_name" => "David",
          "last_name" => "Heinemeier Hansson"
        }
      }

      assert_equal expected, Rails.cache.read("post-1/foo")

      result = render('json.array! @posts, partial: "post", as: :post, cached: ->(post) { [post, "foo"] }', posts: POSTS)

      assert_equal 10, result.count
      assert_equal "Post #5", result[4]["body"]
      assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
      assert_equal "Pavel", result[5]["author"]["first_name"]
    end

    test "raises an error on a render call with the :layout option" do
      error = assert_raises NotImplementedError do
        render('json.array! @posts, partial: "post", as: :post, layout: "layout"', posts: POSTS)
      end

      assert_equal "The `:layout' option is not supported in collection rendering.", error.message
    end

    test "raises an error on a render call with the :spacer_template option" do
      error = assert_raises NotImplementedError do
        render('json.array! @posts, partial: "post", as: :post, spacer_template: "template"', posts: POSTS)
      end

      assert_equal "The `:spacer_template' option is not supported in collection rendering.", error.message
    end
  end

  private
    def render(*args)
      JSON.load render_without_parsing(*args)
    end

    def render_without_parsing(source, assigns = {})
      view = build_view(fixtures: PARTIALS.merge("source.json.jbuilder" => source), assigns: assigns)
      view.render(template: "source")
    end

    def build_view(options = {})
      resolver = ActionView::FixtureResolver.new(options.fetch(:fixtures))
      lookup_context = ActionView::LookupContext.new([ resolver ], {}, [""])
      controller = ActionView::TestCase::TestController.new

      # TODO: Use with_empty_template_cache unconditionally after dropping support for Rails <6.0.
      view = if ActionView::Base.respond_to?(:with_empty_template_cache)
        ActionView::Base.with_empty_template_cache.new(lookup_context, options.fetch(:assigns, {}), controller)
      else
        ActionView::Base.new(lookup_context, options.fetch(:assigns, {}), controller)
      end

      def view.view_cache_dependencies; []; end
      def view.combined_fragment_cache_key(key) [ key ] end
      def view.cache_fragment_name(key, *) key end
      def view.fragment_name_with_digest(key) key end

      view
    end
end
