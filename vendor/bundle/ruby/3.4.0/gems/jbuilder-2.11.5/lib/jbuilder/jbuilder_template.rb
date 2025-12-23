require 'jbuilder/jbuilder'
require 'jbuilder/collection_renderer'
require 'action_dispatch/http/mime_type'
require 'active_support/cache'

class JbuilderTemplate < Jbuilder
  class << self
    attr_accessor :template_lookup_options
  end

  self.template_lookup_options = { handlers: [:jbuilder] }

  def initialize(context, *args)
    @context = context
    @cached_root = nil
    super(*args)
  end

  # Generates JSON using the template specified with the `:partial` option. For example, the code below will render
  # the file `views/comments/_comments.json.jbuilder`, and set a local variable comments with all this message's
  # comments, which can be used inside the partial.
  #
  # Example:
  #
  #   json.partial! 'comments/comments', comments: @message.comments
  #
  # There are multiple ways to generate a collection of elements as JSON, as ilustrated below:
  #
  # Example:
  #
  #   json.array! @posts, partial: 'posts/post', as: :post
  #
  #   # or:
  #   json.partial! 'posts/post', collection: @posts, as: :post
  #
  #   # or:
  #   json.partial! partial: 'posts/post', collection: @posts, as: :post
  #
  #   # or:
  #   json.comments @post.comments, partial: 'comments/comment', as: :comment
  #
  # Aside from that, the `:cached` options is available on Rails >= 6.0. This will cache the rendered results
  # effectively using the multi fetch feature.
  #
  # Example:
  #
  #   json.array! @posts, partial: "posts/post", as: :post, cached: true
  #
  #   json.comments @post.comments, partial: "comments/comment", as: :comment, cached: true
  #
  def partial!(*args)
    if args.one? && _is_active_model?(args.first)
      _render_active_model_partial args.first
    else
      _render_explicit_partial(*args)
    end
  end

  # Caches the json constructed within the block passed. Has the same signature as the `cache` helper
  # method in `ActionView::Helpers::CacheHelper` and so can be used in the same way.
  #
  # Example:
  #
  #   json.cache! ['v1', @person], expires_in: 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache!(key=nil, options={})
    if @context.controller.perform_caching
      value = _cache_fragment_for(key, options) do
        _scope { yield self }
      end

      merge! value
    else
      yield
    end
  end

  # Caches the json structure at the root using a string rather than the hash structure. This is considerably
  # faster, but the drawback is that it only works, as the name hints, at the root. So you cannot
  # use this approach to cache deeper inside the hierarchy, like in partials or such. Continue to use #cache! there.
  #
  # Example:
  #
  #   json.cache_root! @person do
  #     json.extract! @person, :name, :age
  #   end
  #
  #   # json.extra 'This will not work either, the root must be exclusive'
  def cache_root!(key=nil, options={})
    if @context.controller.perform_caching
      raise "cache_root! can't be used after JSON structures have been defined" if @attributes.present?

      @cached_root = _cache_fragment_for([ :root, key ], options) { yield; target! }
    else
      yield
    end
  end

  # Conditionally caches the json depending in the condition given as first parameter. Has the same
  # signature as the `cache` helper method in `ActionView::Helpers::CacheHelper` and so can be used in
  # the same way.
  #
  # Example:
  #
  #   json.cache_if! !admin?, @person, expires_in: 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache_if!(condition, *args, &block)
    condition ? cache!(*args, &block) : yield
  end

  def target!
    @cached_root || super
  end

  def array!(collection = [], *args)
    options = args.first

    if args.one? && _partial_options?(options)
      partial! options.merge(collection: collection)
    else
      super
    end
  end

  def set!(name, object = BLANK, *args)
    options = args.first

    if args.one? && _partial_options?(options)
      _set_inline_partial name, object, options
    else
      super
    end
  end

  private

  def _render_partial_with_options(options)
    options.reverse_merge! locals: options.except(:partial, :as, :collection, :cached)
    options.reverse_merge! ::JbuilderTemplate.template_lookup_options
    as = options[:as]

    if as && options.key?(:collection) && CollectionRenderer.supported?
      collection = options.delete(:collection) || []
      partial = options.delete(:partial)
      options[:locals].merge!(json: self)

      if options.has_key?(:layout)
        raise ::NotImplementedError, "The `:layout' option is not supported in collection rendering."
      end

      if options.has_key?(:spacer_template)
        raise ::NotImplementedError, "The `:spacer_template' option is not supported in collection rendering."
      end

      results = CollectionRenderer
        .new(@context.lookup_context, options) { |&block| _scope(&block) }
        .render_collection_with_partial(collection, partial, @context, nil)

      array! if results.respond_to?(:body) && results.body.nil?
    elsif as && options.key?(:collection) && !CollectionRenderer.supported?
      # For Rails <= 5.2:
      as = as.to_sym
      collection = options.delete(:collection)
      locals = options.delete(:locals)
      array! collection do |member|
        member_locals = locals.clone
        member_locals.merge! collection: collection
        member_locals.merge! as => member
        _render_partial options.merge(locals: member_locals)
      end
    else
      _render_partial options
    end
  end

  def _render_partial(options)
    options[:locals].merge! json: self
    @context.render options
  end

  def _cache_fragment_for(key, options, &block)
    key = _cache_key(key, options)
    _read_fragment_cache(key, options) || _write_fragment_cache(key, options, &block)
  end

  def _read_fragment_cache(key, options = nil)
    @context.controller.instrument_fragment_cache :read_fragment, key do
      ::Rails.cache.read(key, options)
    end
  end

  def _write_fragment_cache(key, options = nil)
    @context.controller.instrument_fragment_cache :write_fragment, key do
      yield.tap do |value|
        ::Rails.cache.write(key, value, options)
      end
    end
  end

  def _cache_key(key, options)
    name_options = options.slice(:skip_digest, :virtual_path)
    key = _fragment_name_with_digest(key, name_options)

    if @context.respond_to?(:combined_fragment_cache_key)
      key = @context.combined_fragment_cache_key(key)
    else
      key = url_for(key).split('://', 2).last if ::Hash === key
    end

    ::ActiveSupport::Cache.expand_cache_key(key, :jbuilder)
  end

  def _fragment_name_with_digest(key, options)
    if @context.respond_to?(:cache_fragment_name)
      @context.cache_fragment_name(key, **options)
    else
      key
    end
  end

  def _partial_options?(options)
    ::Hash === options && options.key?(:as) && options.key?(:partial)
  end

  def _is_active_model?(object)
    object.class.respond_to?(:model_name) && object.respond_to?(:to_partial_path)
  end

  def _set_inline_partial(name, object, options)
    value = if object.nil?
      []
    elsif _is_collection?(object)
      _scope{ _render_partial_with_options options.merge(collection: object) }
    else
      locals = ::Hash[options[:as], object]
      _scope{ _render_partial_with_options options.merge(locals: locals) }
    end

    set! name, value
  end

  def _render_explicit_partial(name_or_options, locals = {})
    case name_or_options
    when ::Hash
      # partial! partial: 'name', foo: 'bar'
      options = name_or_options
    else
      # partial! 'name', locals: {foo: 'bar'}
      if locals.one? && (locals.keys.first == :locals)
        options = locals.merge(partial: name_or_options)
      else
        options = { partial: name_or_options, locals: locals }
      end
      # partial! 'name', foo: 'bar'
      as = locals.delete(:as)
      options[:as] = as if as.present?
      options[:collection] = locals[:collection] if locals.key?(:collection)
    end

    _render_partial_with_options options
  end

  def _render_active_model_partial(object)
    @context.render object, json: self
  end
end

class JbuilderHandler
  cattr_accessor :default_format
  self.default_format = :json

  def self.call(template, source = nil)
    source ||= template.source
    # this juggling is required to keep line numbers right in the error
    %{__already_defined = defined?(json); json||=JbuilderTemplate.new(self); #{source}
      json.target! unless (__already_defined && __already_defined != "method")}
  end
end
