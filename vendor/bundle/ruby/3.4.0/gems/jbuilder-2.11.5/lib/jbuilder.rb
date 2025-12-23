require 'active_support'
require 'jbuilder/jbuilder'
require 'jbuilder/blank'
require 'jbuilder/key_formatter'
require 'jbuilder/errors'
require 'json'
require 'ostruct'
require 'active_support/core_ext/hash/deep_merge'

class Jbuilder
  @@key_formatter = nil
  @@ignore_nil    = false
  @@deep_format_keys = false

  def initialize(options = {})
    @attributes = {}

    @key_formatter = options.fetch(:key_formatter){ @@key_formatter ? @@key_formatter.clone : nil}
    @ignore_nil = options.fetch(:ignore_nil, @@ignore_nil)
    @deep_format_keys = options.fetch(:deep_format_keys, @@deep_format_keys)

    yield self if ::Kernel.block_given?
  end

  # Yields a builder and automatically turns the result into a JSON string
  def self.encode(*args, &block)
    new(*args, &block).target!
  end

  BLANK = Blank.new
  NON_ENUMERABLES = [ ::Struct, ::OpenStruct ].to_set

  def set!(key, value = BLANK, *args, &block)
    result = if ::Kernel.block_given?
      if !_blank?(value)
        # json.comments @post.comments { |comment| ... }
        # { "comments": [ { ... }, { ... } ] }
        _scope{ array! value, &block }
      else
        # json.comments { ... }
        # { "comments": ... }
        _merge_block(key){ yield self }
      end
    elsif args.empty?
      if ::Jbuilder === value
        # json.age 32
        # json.person another_jbuilder
        # { "age": 32, "person": { ...  }
        _format_keys(value.attributes!)
      else
        # json.age 32
        # { "age": 32 }
        _format_keys(value)
      end
    elsif _is_collection?(value)
      # json.comments @post.comments, :content, :created_at
      # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
      _scope{ array! value, *args }
    else
      # json.author @post.creator, :name, :email_address
      # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
      _merge_block(key){ extract! value, *args }
    end

    _set_value key, result
  end

  def method_missing(*args, &block)
    if ::Kernel.block_given?
      set!(*args, &block)
    else
      set!(*args)
    end
  end

  # Specifies formatting to be applied to the key. Passing in a name of a function
  # will cause that function to be called on the key.  So :upcase will upper case
  # the key.  You can also pass in lambdas for more complex transformations.
  #
  # Example:
  #
  #   json.key_format! :upcase
  #   json.author do
  #     json.name "David"
  #     json.age 32
  #   end
  #
  #   { "AUTHOR": { "NAME": "David", "AGE": 32 } }
  #
  # You can pass parameters to the method using a hash pair.
  #
  #   json.key_format! camelize: :lower
  #   json.first_name "David"
  #
  #   { "firstName": "David" }
  #
  # Lambdas can also be used.
  #
  #   json.key_format! ->(key){ "_" + key }
  #   json.first_name "David"
  #
  #   { "_first_name": "David" }
  #
  def key_format!(*args)
    @key_formatter = KeyFormatter.new(*args)
  end

  # Same as the instance method key_format! except sets the default.
  def self.key_format(*args)
    @@key_formatter = KeyFormatter.new(*args)
  end

  # If you want to skip adding nil values to your JSON hash. This is useful
  # for JSON clients that don't deal well with nil values, and would prefer
  # not to receive keys which have null values.
  #
  # Example:
  #   json.ignore_nil! false
  #   json.id User.new.id
  #
  #   { "id": null }
  #
  #   json.ignore_nil!
  #   json.id User.new.id
  #
  #   {}
  #
  def ignore_nil!(value = true)
    @ignore_nil = value
  end

  # Same as instance method ignore_nil! except sets the default.
  def self.ignore_nil(value = true)
    @@ignore_nil = value
  end

  # Deeply apply key format to nested hashes and arrays passed to
  # methods like set!, merge! or array!.
  #
  # Example:
  #
  #   json.key_format! camelize: :lower
  #   json.settings({some_value: "abc"})
  #
  #   { "settings": { "some_value": "abc" }}
  #
  #   json.key_format! camelize: :lower
  #   json.deep_format_keys!
  #   json.settings({some_value: "abc"})
  #
  #   { "settings": { "someValue": "abc" }}
  #
  def deep_format_keys!(value = true)
    @deep_format_keys = value
  end

  # Same as instance method deep_format_keys! except sets the default.
  def self.deep_format_keys(value = true)
    @@deep_format_keys = value
  end

  # Turns the current element into an array and yields a builder to add a hash.
  #
  # Example:
  #
  #   json.comments do
  #     json.child! { json.content "hello" }
  #     json.child! { json.content "world" }
  #   end
  #
  #   { "comments": [ { "content": "hello" }, { "content": "world" } ]}
  #
  # More commonly, you'd use the combined iterator, though:
  #
  #   json.comments(@post.comments) do |comment|
  #     json.content comment.formatted_content
  #   end
  def child!
    @attributes = [] unless ::Array === @attributes
    @attributes << _scope{ yield self }
  end

  # Turns the current element into an array and iterates over the passed collection, adding each iteration as
  # an element of the resulting array.
  #
  # Example:
  #
  #   json.array!(@people) do |person|
  #     json.name person.name
  #     json.age calculate_age(person.birthday)
  #   end
  #
  #   [ { "name": David", "age": 32 }, { "name": Jamie", "age": 31 } ]
  #
  # You can use the call syntax instead of an explicit extract! call:
  #
  #   json.(@people) { |person| ... }
  #
  # It's generally only needed to use this method for top-level arrays. If you have named arrays, you can do:
  #
  #   json.people(@people) do |person|
  #     json.name person.name
  #     json.age calculate_age(person.birthday)
  #   end
  #
  #   { "people": [ { "name": David", "age": 32 }, { "name": Jamie", "age": 31 } ] }
  #
  # If you omit the block then you can set the top level array directly:
  #
  #   json.array! [1, 2, 3]
  #
  #   [1,2,3]
  def array!(collection = [], *attributes, &block)
    array = if collection.nil?
      []
    elsif ::Kernel.block_given?
      _map_collection(collection, &block)
    elsif attributes.any?
      _map_collection(collection) { |element| extract! element, *attributes }
    else
      _format_keys(collection.to_a)
    end

    @attributes = _merge_values(@attributes, array)
  end

  # Extracts the mentioned attributes or hash elements from the passed object and turns them into attributes of the JSON.
  #
  # Example:
  #
  #   @person = Struct.new(:name, :age).new('David', 32)
  #
  #   or you can utilize a Hash
  #
  #   @person = { name: 'David', age: 32 }
  #
  #   json.extract! @person, :name, :age
  #
  #   { "name": David", "age": 32 }, { "name": Jamie", "age": 31 }
  #
  # You can also use the call syntax instead of an explicit extract! call:
  #
  #   json.(@person, :name, :age)
  def extract!(object, *attributes)
    if ::Hash === object
      _extract_hash_values(object, attributes)
    else
      _extract_method_values(object, attributes)
    end
  end

  def call(object, *attributes, &block)
    if ::Kernel.block_given?
      array! object, &block
    else
      extract! object, *attributes
    end
  end

  # Returns the nil JSON.
  def nil!
    @attributes = nil
  end

  alias_method :null!, :nil!

  # Returns the attributes of the current builder.
  def attributes!
    @attributes
  end

  # Merges hash, array, or Jbuilder instance into current builder.
  def merge!(object)
    hash_or_array = ::Jbuilder === object ? object.attributes! : object
    @attributes = _merge_values(@attributes, _format_keys(hash_or_array))
  end

  # Encodes the current builder as JSON.
  def target!
    @attributes.to_json
  end

  private

  def _extract_hash_values(object, attributes)
    attributes.each{ |key| _set_value key, _format_keys(object.fetch(key)) }
  end

  def _extract_method_values(object, attributes)
    attributes.each{ |key| _set_value key, _format_keys(object.public_send(key)) }
  end

  def _merge_block(key)
    current_value = _blank? ? BLANK : @attributes.fetch(_key(key), BLANK)
    raise NullError.build(key) if current_value.nil?
    new_value = _scope{ yield self }
    _merge_values(current_value, new_value)
  end

  def _merge_values(current_value, updates)
    if _blank?(updates)
      current_value
    elsif _blank?(current_value) || updates.nil? || current_value.empty? && ::Array === updates
      updates
    elsif ::Array === current_value && ::Array === updates
      current_value + updates
    elsif ::Hash === current_value && ::Hash === updates
      current_value.deep_merge(updates)
    else
      raise MergeError.build(current_value, updates)
    end
  end

  def _key(key)
    @key_formatter ? @key_formatter.format(key) : key.to_s
  end

  def _format_keys(hash_or_array)
    return hash_or_array unless @deep_format_keys

    if ::Array === hash_or_array
      hash_or_array.map { |value| _format_keys(value) }
    elsif ::Hash === hash_or_array
      ::Hash[hash_or_array.collect { |k, v| [_key(k), _format_keys(v)] }]
    else
      hash_or_array
    end
  end

  def _set_value(key, value)
    raise NullError.build(key) if @attributes.nil?
    raise ArrayError.build(key) if ::Array === @attributes
    return if @ignore_nil && value.nil? or _blank?(value)
    @attributes = {} if _blank?
    @attributes[_key(key)] = value
  end

  def _map_collection(collection)
    collection.map do |element|
      _scope{ yield element }
    end - [BLANK]
  end

  def _scope
    parent_attributes, parent_formatter, parent_deep_format_keys = @attributes, @key_formatter, @deep_format_keys
    @attributes = BLANK
    yield
    @attributes
  ensure
    @attributes, @key_formatter, @deep_format_keys = parent_attributes, parent_formatter, parent_deep_format_keys
  end

  def _is_collection?(object)
    _object_respond_to?(object, :map, :count) && NON_ENUMERABLES.none?{ |klass| klass === object }
  end

  def _blank?(value=@attributes)
    BLANK == value
  end

  def _object_respond_to?(object, *methods)
    methods.all?{ |m| object.respond_to?(m) }
  end
end

require 'jbuilder/railtie' if defined?(Rails)
