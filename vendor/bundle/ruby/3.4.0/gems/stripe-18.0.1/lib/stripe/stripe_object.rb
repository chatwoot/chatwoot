# frozen_string_literal: true

module Stripe
  class StripeObject
    include Enumerable

    attr_reader :last_response

    @@permanent_attributes = Set.new([:id]) # rubocop:disable Style/ClassVars

    # The default :id method is deprecated and isn't useful to us
    undef :id if method_defined?(:id)

    # Sets the given parameter name to one which is known to be an additive
    # object.
    #
    # Additive objects are subobjects in the API that don't have the same
    # semantics as most subobjects, which are fully replaced when they're set.
    # This is best illustrated by example. The `source` parameter sent when
    # updating a subscription is *not* additive; if we set it:
    #
    #     source[object]=card&source[number]=123
    #
    # We expect the old `source` object to have been overwritten completely. If
    # the previous source had an `address_state` key associated with it and we
    # didn't send one this time, that value of `address_state` is gone.
    #
    # By contrast, additive objects are those that will have new data added to
    # them while keeping any existing data in place. The only known case of its
    # use is for `metadata`, but it could in theory be more general. As an
    # example, say we have a `metadata` object that looks like this on the
    # server side:
    #
    #     metadata = { old: "old_value" }
    #
    # If we update the object with `metadata[new]=new_value`, the server side
    # object now has *both* fields:
    #
    #     metadata = { old: "old_value", new: "new_value" }
    #
    # This is okay in itself because usually users will want to treat it as
    # additive:
    #
    #     obj.metadata[:new] = "new_value"
    #     obj.save
    #
    # However, in other cases, they may want to replace the entire existing
    # contents:
    #
    #     obj.metadata = { new: "new_value" }
    #     obj.save
    #
    # This is where things get a little bit tricky because in order to clear
    # any old keys that may have existed, we actually have to send an explicit
    # empty string to the server. So the operation above would have to send
    # this form to get the intended behavior:
    #
    #     metadata[old]=&metadata[new]=new_value
    #
    # This method allows us to track which parameters are considered additive,
    # and lets us behave correctly where appropriate when serializing
    # parameters to be sent.
    def self.additive_object_param(name)
      @additive_params ||= Set.new
      @additive_params << name
    end

    # Returns whether the given name is an additive object parameter. See
    # `.additive_object_param` for details.
    def self.additive_object_param?(name)
      @additive_params ||= Set.new
      @additive_params.include?(name)
    end

    def initialize(id = nil, opts = {}, api_mode = :v1, requestor = nil)
      @api_mode = api_mode
      id, @retrieve_params = Util.normalize_id(id)
      @opts = Util.normalize_opts(opts)
      @original_values = {}
      @values = {}
      # This really belongs in APIResource, but not putting it there allows us
      # to have a unified inspect method
      @unsaved_values = Set.new
      @transient_values = Set.new
      @values[:id] = id if id
      @id = id
      @last_response = nil
      @requestor = requestor || APIRequestor.active_requestor
    end

    def self.construct_from(values, opts = {}, last_response = nil, api_mode = :v1, requestor = nil)
      values = Stripe::Util.symbolize_names(values)

      # work around protected #initialize_from for now
      new(values[:id]).send(:initialize_from, values, opts, last_response, api_mode: api_mode, requestor: requestor)
    end

    # Determines the equality of two Stripe objects. Stripe objects are
    # considered to be equal if they have the same set of values and each one
    # of those values is the same.
    def ==(other)
      other.is_a?(StripeObject) &&
        @values == other.instance_variable_get(:@values)
    end

    # Hash equality. As with `#==`, we consider two equivalent Stripe objects
    # equal.
    def eql?(other)
      # Defer to the implementation on `#==`.
      self == other
    end

    # As with equality in `#==` and `#eql?`, we hash two Stripe objects to the
    # same value if they're equivalent objects.
    def hash
      @values.hash
    end

    # Indicates whether or not the resource has been deleted on the server.
    # Note that some, but not all, resources can indicate whether they have
    # been deleted.
    def deleted?
      @values.fetch(:deleted, false)
    end

    def to_s(*_args)
      JSON.pretty_generate(to_hash)
    end

    def inspect
      id_string = respond_to?(:id) && !id.nil? ? " id=#{id}" : ""
      "#<#{self.class}:0x#{object_id.to_s(16)}#{id_string}> JSON: " +
        JSON.pretty_generate(@values)
    end

    # Mass assigns attributes on the model.
    #
    # This is a version of +update_attributes+ that takes some extra options
    # for internal use.
    #
    # ==== Attributes
    #
    # * +values+ - Hash of values to use to update the current attributes of
    #   the object. If you are on ruby 2.7 or higher make sure to wrap in curly
    #   braces to be ruby 3 compatible.
    # * +opts+ - Options for +StripeObject+ like an API key that will be reused
    #   on subsequent API calls.
    #
    # ==== Options
    #
    # * +:dirty+ - Whether values should be initiated as "dirty" (unsaved) and
    #   which applies only to new StripeObjects being initiated under this
    #   StripeObject. Defaults to true.
    def update_attributes(values, opts = {}, dirty: true)
      values.each do |k, v|
        add_accessors([k], values) unless metaclass.method_defined?(k.to_sym)
        @values[k] = convert_value_with_inner_types(k, v, opts)
        dirty_value!(@values[k]) if dirty
        @unsaved_values.add(k)
      end
    end

    private def convert_value_with_inner_types(key, value, opts)
      inner_class = _get_inner_class_type(key)

      if inner_class
        Util.convert_to_stripe_object(value, opts, api_mode: @api_mode, requestor: @requestor, klass: inner_class)
      else
        Util.convert_to_stripe_object(value, opts, api_mode: @api_mode, requestor: @requestor)
      end
    end

    def [](key)
      key_sym = key.to_sym
      return @values[key_sym] if @values.key?(key_sym)

      # super specific one-off case to help users debug this property disappearing
      # see also: https://go/j/DEVSDK-2835
      if is_a?(Invoice) && key_sym == :payment_intent
        raise KeyError,
              "The 'payment_intent' attribute is no longer available on Invoice objects. " \
              "See the docs for more details: https://docs.stripe.com/changelog/basil/2025-03-31/" \
              "add-support-for-multiple-partial-payments-on-invoices#why-is-this-a-breaking-change"
      end

      nil
    end

    def []=(key, value)
      send(:"#{key}=", value)
    end

    def keys
      @values.keys
    end

    def values
      @values.values
    end

    def to_json(*_opts)
      # TODO: pass opts to JSON.generate?
      JSON.generate(@values)
    end

    def as_json(*opts)
      @values.as_json(*opts)
    end

    def to_hash
      maybe_to_hash = lambda do |value|
        return nil if value.nil?

        value.respond_to?(:to_hash) ? value.to_hash : value
      end

      @values.transform_values do |value|
        case value
        when Array
          value.map(&maybe_to_hash)
        else
          maybe_to_hash.call(value)
        end
      end
    end

    def each(&blk)
      @values.each(&blk)
    end

    # Sets all keys within the StripeObject as unsaved so that they will be
    # included with an update when #serialize_params is called. This method is
    # also recursive, so any StripeObjects contained as values or which are
    # values in a tenant array are also marked as dirty.
    def dirty!
      @unsaved_values = Set.new(@values.keys)
      @values.each_value do |v|
        dirty_value!(v)
      end
    end

    # Implements custom encoding for Ruby's Marshal. The data produced by this
    # method should be comprehendable by #marshal_load.
    #
    # This allows us to remove certain features that cannot or should not be
    # serialized.
    def marshal_dump
      # The APIRequestor instance in @opts is not serializable and is not
      # really a property of the StripeObject, so we exclude it when
      # dumping
      opts = @opts.clone

      # TODO: (major) Remove the :client option. This is not explicitly supported as a user-specified option.
      opts.delete(:client)
      [@values, opts]
    end

    # Implements custom decoding for Ruby's Marshal. Consumes data that's
    # produced by #marshal_dump.
    def marshal_load(data, api_mode: :v1)
      values, opts = data
      initialize(values[:id], api_mode: api_mode)
      initialize_from(values, opts, api_mode: api_mode, requestor: @requestor)
    end

    def serialize_params(options = {})
      update_hash = {}

      @values.each do |k, v|
        # There are a few reasons that we may want to add in a parameter for
        # update:
        #
        #   1. The `force` option has been set.
        #   2. We know that it was modified.
        #   3. Its value is a StripeObject. A StripeObject may contain modified
        #      values within in that its parent StripeObject doesn't know about.
        #
        unsaved = @unsaved_values.include?(k)
        next unless options[:force] || unsaved || v.is_a?(StripeObject)

        update_hash[k.to_sym] = serialize_params_value(
          @values[k], @original_values[k], unsaved, options[:force], key: k
        )
      end

      # a `nil` that makes it out of `#serialize_params_value` signals an empty
      # value that we shouldn't appear in the serialized form of the object
      update_hash.compact!

      update_hash
    end

    # A protected field is one that doesn't get an accessor assigned to it
    # (i.e. `obj.public = ...`) and one which is not allowed to be updated via
    # the class level `Model.update(id, { ... })`.
    def self.protected_fields
      []
    end

    # When designing APIs, we now make a conscious effort server-side to avoid
    # naming fields after important built-ins in various languages (e.g. class,
    # method, etc.).
    #
    # However, a long time ago we made the mistake (either consciously or by
    # accident) of initializing our `metadata` fields as instances of
    # `StripeObject`, and metadata can have a wide range of different keys
    # defined in it. This is somewhat a convenient in that it allows users to
    # access data like `obj.metadata.my_field`, but is almost certainly not
    # worth the cost.
    #
    # Naming metadata fields bad things like `class` causes `initialize_from`
    # to produce strange results, so we ban known offenders here.
    #
    # In a future major version we should consider leaving `metadata` as a hash
    # and forcing people to access it with `obj.metadata[:my_field]` because
    # the potential for trouble is just too high. For now, reserve names.
    RESERVED_FIELD_NAMES = [
      :class,
    ].freeze

    protected def metaclass
      class << self; self; end
    end

    protected def remove_accessors(keys)
      # not available in the #instance_eval below
      protected_fields = self.class.protected_fields
      obj = self # capture self to use inside instance_eval

      metaclass.instance_eval do
        keys.each do |k|
          next if RESERVED_FIELD_NAMES.include?(k)
          next if protected_fields.include?(k)
          next if @@permanent_attributes.include?(k)

          # Remove methods for the accessor's reader and writer.
          [k, :"#{k}=", :"#{k}?"].each do |method_name|
            next unless method_defined?(method_name)

            begin
              remove_method(method_name)
            rescue NameError
              # In some cases there can be a method that's detected with
              # `method_defined?`, but which cannot be removed with
              # `remove_method`, even though it's on the same class. The only
              # case so far that we've noticed this is when a class is
              # reopened for monkey patching:
              #
              #     https://github.com/stripe/stripe-ruby/issues/749
              #
              # Here we swallow that error and issue a warning so at least
              # the program doesn't crash.
              warn("WARNING: Unable to remove method `#{method_name}`; " \
                   "if custom, please consider renaming to a name that doesn't " \
                   "collide with an API property name.")
            end
          end

          # Also remove instance variables so that static attr_readers (if any exist)
          # will return nil instead of stale data or data of the wrong type
          ivar_name = :"@#{k}"
          obj.remove_instance_variable(ivar_name) if obj.instance_variable_defined?(ivar_name)
        end
      end
    end

    protected def add_accessors(keys, values) # rubocop:todo Metrics/PerceivedComplexity
      # not available in the #instance_eval below
      protected_fields = self.class.protected_fields

      metaclass.instance_eval do
        keys.each do |k|
          next if RESERVED_FIELD_NAMES.include?(k)
          next if protected_fields.include?(k)
          next if @@permanent_attributes.include?(k)

          if k == :method
            # Object#method is a built-in Ruby method that accepts a symbol
            # and returns the corresponding Method object. Because the API may
            # also use `method` as a field name, we check the arity of *args
            # to decide whether to act as a getter or call the parent method.
            define_method(k) { |*args| args.empty? ? @values[k] : super(*args) }
          else
            define_method(k) { @values[k] }
          end

          define_method(:"#{k}=") do |v|
            if v == ""
              raise ArgumentError, "You cannot set #{k} to an empty string. " \
                                   "We interpret empty strings as nil in requests. " \
                                   "You may set (object).#{k} = nil to delete the property."
            end
            @values[k] = Util.convert_to_stripe_object(v, @opts, api_mode: @api_mode, requestor: @requestor)
            dirty_value!(@values[k])
            @unsaved_values.add(k)
          end

          define_method(:"#{k}?") { @values[k] } if [FalseClass, TrueClass].include?(values[k].class)
        end
      end

      keys.each do |k|
        if Util.valid_variable_name?(k)
          instance_variable_set(:"@#{k}", values[k])
        else
          Util.log_info(<<~LOG
            The variable name '#{k}' is not a valid Ruby variable name.
            Use ["#{k}"] to access this field, skipping instance variable instantiation...
          LOG
                       )

        end
      end
    end

    # Disabling the cop because it's confused by the fact that the methods are
    # protected, but we do define `#respond_to_missing?` just below. Hopefully
    # this is fixed in more recent Rubocop versions.
    protected def method_missing(name, *args)
      # TODO: only allow setting in updateable classes.
      if name.to_s.end_with?("=")
        attr = name.to_s[0...-1].to_sym

        # Pull out the assigned value. This is only used in the case of a
        # boolean value to add a question mark accessor (i.e. `foo?`) for
        # convenience.
        val = args.first

        # the second argument is only required when adding boolean accessors
        add_accessors([attr], attr => val)

        begin
          mth = method(name)
        rescue NameError
          raise NoMethodError,
                "Cannot set #{attr} on this object. HINT: you can't set: " \
                "#{@@permanent_attributes.to_a.join(', ')}"
        end
        return mth.call(args[0])
      elsif @values.key?(name)
        return @values[name]
      end

      begin
        super
      rescue NoMethodError => e
        # super specific one-off case to help users debug this property disappearing
        # see also: https://go/j/DEVSDK-2835
        if is_a?(Invoice) && name == :payment_intent
          raise NoMethodError,
                "The 'payment_intent' attribute is no longer available on Invoice objects. " \
                "See the docs for more details: https://docs.stripe.com/changelog/basil/2025-03-31/" \
                "add-support-for-multiple-partial-payments-on-invoices#why-is-this-a-breaking-change"
        end

        # If we notice the accessed name of our set of transient values we can
        # give the user a slightly more helpful error message. If not, just
        # raise right away.
        raise unless @transient_values.include?(name)

        raise NoMethodError,
              e.message + ".  HINT: The '#{name}' attribute was set in the " \
                          "past, however.  It was then wiped when refreshing the object " \
                          "with the result returned by Stripe's API, probably as a " \
                          "result of a save().  The attributes currently available on " \
                          "this object are: #{@values.keys.join(', ')}"
      end
    end
    protected def respond_to_missing?(symbol, include_private = false)
      (@values && @values.key?(symbol)) || super
    end

    # Re-initializes the object based on a hash of values (usually one that's
    # come back from an API call). Adds or removes value accessors as necessary
    # and updates the state of internal data.
    #
    # Protected on purpose! Please do not expose.
    #
    # ==== Options
    #
    # * +:values:+ Hash used to update accessors and values.
    # * +:opts:+ Options for StripeObject like an API key.
    # * +:partial:+ Indicates that the re-initialization should not attempt to
    #   remove accessors.
    protected def initialize_from(values, opts, last_response = nil, api_mode:, requestor: nil)
      @api_mode = api_mode
      @last_response = last_response
      @requestor = requestor

      @opts = Util.normalize_opts(opts)

      # the `#send` is here so that we can keep this method private
      @original_values = self.class.send(:deep_copy, values, api_mode: api_mode)

      removed = Set.new(@values.keys - values.keys)
      added = Set.new(values.keys - @values.keys)

      # Wipe old state before setting new.  This is useful for e.g. updating a
      # customer, where there is no persistent card parameter.  Mark those
      # values which don't persist as transient

      remove_accessors(removed)
      add_accessors(added, values)

      removed.each do |k|
        @values.delete(k)
        @transient_values.add(k)
        @unsaved_values.delete(k)
      end

      update_attributes(values, opts, dirty: false)
      values.each_key do |k|
        @transient_values.delete(k)
        @unsaved_values.delete(k)
      end

      self
    end

    # Should only be for v2 events and lists, for now.
    protected def _request(method:, path:, base_address:, params: {}, opts: {})
      req_opts = RequestOptions.extract_opts_from_hash(opts)
      req_opts = RequestOptions.combine_opts(@opts, req_opts)
      @requestor.execute_request(
        method,
        path,
        base_address,
        params: params,
        opts: req_opts
      )
    end

    # rubocop:todo Metrics/PerceivedComplexity
    protected def serialize_params_value(value, original, unsaved, force, # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
                                         key: nil)
      if value.nil?
        ""

      # The logic here is that essentially any object embedded in another
      # object that had a `type` is actually an API resource of a different
      # type that's been included in the response. These other resources must
      # be updated from their proper endpoints, and therefore they are not
      # included when serializing even if they've been modified.
      #
      # There are _some_ known exceptions though.
      #
      # For example, if the value is unsaved (meaning the user has set it), and
      # it looks like the API resource is persisted with an ID, then we include
      # the object so that parameters are serialized with a reference to its
      # ID.
      #
      # Another example is that on save API calls it's sometimes desirable to
      # update a customer's default source by setting a new card (or other)
      # object with `#source=` and then saving the customer. The
      # `#save_with_parent` flag to override the default behavior allows us to
      # handle these exceptions.
      #
      # We throw an error if a property was set explicitly but we can't do
      # anything with it because the integration is probably not working as the
      # user intended it to.
      elsif value.is_a?(APIResource) && !value.save_with_parent
        if !unsaved
          nil
        elsif value.respond_to?(:id) && !value.id.nil?
          value
        else
          raise ArgumentError, "Cannot save property `#{key}` containing " \
                               "an API resource. It doesn't appear to be persisted and is " \
                               "not marked as `save_with_parent`."
        end

      elsif value.is_a?(Array)
        update = value.map { |v| serialize_params_value(v, nil, true, force) }

        # This prevents an array that's unchanged from being resent.
        update if update != serialize_params_value(original, nil, true, force)

      # Handle a Hash for now, but in the long run we should be able to
      # eliminate all places where hashes are stored as values internally by
      # making sure any time one is set, we convert it to a StripeObject. This
      # will simplify our model by making data within an object more
      # consistent.
      #
      # For now, you can still run into a hash if someone appends one to an
      # existing array being held by a StripeObject. This could happen for
      # example by appending a new hash onto `additional_owners` for an
      # account.
      elsif value.is_a?(Hash)
        Util.convert_to_stripe_object(value, @opts, api_mode: @api_mode, requestor: @requestor).serialize_params

      elsif value.is_a?(StripeObject)
        update = value.serialize_params(force: force)

        # If the entire object was replaced and this is an additive object,
        # then we need blank each field of the old object that held a value
        # because otherwise the update to the keys of the object will be
        # additive instead of a full replacement. The new serialized values
        # will override any of these empty values.
        if original && unsaved && key && self.class.additive_object_param?(key)
          update = empty_values(original).merge(update)
        end

        update

      else
        value
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # Produces a deep copy of the given object including support for arrays,
    # hashes, and StripeObjects.
    private_class_method def self.deep_copy(obj, api_mode:)
      case obj
      when Array
        obj.map { |e| deep_copy(e, api_mode: api_mode) }
      when Hash
        obj.each_with_object({}) do |(k, v), copy|
          copy[k] = deep_copy(v, api_mode: api_mode)
          copy
        end
      when StripeObject
        obj.class.construct_from(
          deep_copy(obj.instance_variable_get(:@values), api_mode: api_mode),
          RequestOptions.copyable(obj.instance_variable_get(:@opts)),
          nil,
          api_mode,
          obj.instance_variable_get(:@requestor)
        )
      else
        obj
      end
    end

    private def dirty_value!(value)
      case value
      when Array
        value.map { |v| dirty_value!(v) }
      when StripeObject
        value.dirty!
      end
    end

    # Returns a hash of empty values for all the values that are in the given
    # StripeObject.
    private def empty_values(obj)
      values = case obj
               when Hash         then obj
               when StripeObject then obj.instance_variable_get(:@values)
               else
                 raise ArgumentError,
                       "#empty_values got unexpected object type: " \
                       "#{obj.class.name}"
               end

      values.each_with_object({}) do |(k, _), update|
        update[k] = ""
      end
    end

    # Instance methods to get inner class types
    def _get_inner_class_type(field_name)
      self.class.inner_class_types[field_name.to_sym]
    end

    # Class methods for inner class types, similar to Python's implementation
    def self.inner_class_types
      @inner_class_types ||= {}
    end

    def self.field_remappings
      @field_remappings ||= {}
    end
  end
end
