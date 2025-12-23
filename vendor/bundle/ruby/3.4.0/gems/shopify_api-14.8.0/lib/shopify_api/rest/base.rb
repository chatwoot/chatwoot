# typed: strict
# frozen_string_literal: true

require "active_support/inflector"
require "active_support/core_ext/hash/indifferent_access"

module ShopifyAPI
  module Rest
    class Base
      extend T::Sig
      extend T::Helpers
      abstract!

      @headers = T.let(nil, T.nilable(T::Hash[T.any(Symbol, String), String]))
      @has_one = T.let({}, T::Hash[Symbol, T::Class[T.anything]])
      @has_many = T.let({}, T::Hash[Symbol, T::Class[T.anything]])
      @paths = T.let([], T::Array[T::Hash[Symbol, T.any(T::Array[Symbol], String, Symbol)]])
      @custom_prefix = T.let(nil, T.nilable(String))
      @read_only_attributes = T.let([], T.nilable(T::Array[Symbol]))
      @atomic_hash_attributes = T.let([], T::Array[Symbol])
      @aliased_properties = T.let({}, T::Hash[String, String])

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_accessor :original_state

      sig { returns(T.any(Rest::BaseErrors, T.nilable(T::Hash[T.untyped, T.untyped]))) }
      attr_reader :errors

      sig do
        params(
          session: T.nilable(Auth::Session),
          from_hash: T.nilable(T::Hash[Symbol, T.untyped]),
        ).void
      end
      def initialize(session: nil, from_hash: nil)
        @original_state = T.let({}, T::Hash[Symbol, T.untyped])
        @custom_prefix = T.let(nil, T.nilable(String))
        @forced_nils = T.let({}, T::Hash[String, T::Boolean])
        @aliased_properties = T.let({}, T::Hash[String, String])

        session ||= ShopifyAPI::Context.active_session

        client = ShopifyAPI::Clients::Rest::Admin.new(session: session)

        @session = T.let(T.must(session), Auth::Session)
        @client = T.let(client, Clients::Rest::Admin)
        @errors = T.let(Rest::BaseErrors.new, Rest::BaseErrors)

        from_hash&.each do |key, value|
          set_property(key, value)
        end
      end

      class << self
        extend T::Sig

        sig { returns(T.nilable(String)) }
        attr_reader :custom_prefix

        sig { returns(T::Hash[Symbol, T::Class[T.anything]]) }
        attr_reader :has_many

        sig { returns(T::Hash[Symbol, T::Class[T.anything]]) }
        attr_reader :has_one

        sig { returns(T.nilable(T::Array[Symbol])) }
        attr_reader :atomic_hash_attributes

        sig { returns(T.nilable(T::Hash[T.any(Symbol, String), String])) }
        attr_accessor :headers

        sig { params(subclass: T::Class[T.anything]).returns(T.untyped) }
        def inherited(subclass)
          super

          subclass.define_singleton_method(:headers) do
            ShopifyAPI::Rest::Base.headers
          end
        end

        sig do
          params(
            session: T.nilable(Auth::Session),
            ids: T::Hash[Symbol, String],
            params: T::Hash[Symbol, T.untyped],
          ).returns(T::Array[Base])
        end
        def base_find(session: nil, ids: {}, params: {})
          session ||= ShopifyAPI::Context.active_session

          client = ShopifyAPI::Clients::Rest::Admin.new(session: session)

          path = T.must(get_path(http_method: :get, operation: :get, ids: ids))
          response = client.get(path: path, query: params.compact, headers: headers)

          instance_variable_get(:"@prev_page_info").value = response.prev_page_info
          instance_variable_get(:"@next_page_info").value = response.next_page_info

          instance_variable_get(:"@retry_request_after").value = response.retry_request_after
          instance_variable_get(:"@api_call_limit").value = response.api_call_limit

          create_instances_from_response(response: response, session: T.must(session))
        end

        sig { returns(String) }
        def class_name
          T.must(name).demodulize.underscore
        end

        sig { returns(String) }
        def primary_key
          "id"
        end

        sig { returns(String) }
        def json_body_name
          class_name.underscore
        end

        sig { returns(T::Array[String]) }
        def json_response_body_names
          [class_name]
        end

        sig { returns(T.nilable(String)) }
        def prev_page_info
          instance_variable_get(:"@prev_page_info").value
        end

        sig { returns(T.nilable(String)) }
        def next_page_info
          instance_variable_get(:"@next_page_info").value
        end

        sig { returns(T::Boolean) }
        def prev_page?
          !instance_variable_get(:"@prev_page_info").value.nil?
        end

        sig { returns(T::Boolean) }
        def next_page?
          !instance_variable_get(:"@next_page_info").value.nil?
        end

        sig { returns T.nilable(Float) }
        def retry_request_after
          instance_variable_get(:"@retry_request_after").value
        end

        sig { returns T.nilable(T::Hash[String, Integer]) }
        def api_call_limit
          instance_variable_get(:"@api_call_limit").value
        end

        sig { params(attribute: Symbol).returns(T::Boolean) }
        def has_many?(attribute)
          @has_many.include?(attribute)
        end

        sig { params(attribute: Symbol).returns(T::Boolean) }
        def has_one?(attribute)
          @has_one.include?(attribute)
        end

        sig { returns(T.nilable(T::Array[Symbol])) }
        def read_only_attributes
          @read_only_attributes&.map { |a| :"@#{a}" }
        end

        sig do
          params(
            http_method: Symbol,
            operation: Symbol,
            entity: T.nilable(Base),
            ids: T::Hash[Symbol, T.any(Integer, String)],
          ).returns(T.nilable(String))
        end
        def get_path(http_method:, operation:, entity: nil, ids: {})
          match = T.let(nil, T.nilable(String))
          max_ids = T.let(-1, Integer)
          @paths.each do |path|
            next if http_method != path[:http_method] || operation != path[:operation]

            path_ids = T.cast(path[:ids], T::Array[Symbol])

            url_ids = ids.transform_keys(&:to_sym)
            path_ids.each do |id|
              if url_ids[id].nil? && (entity_id = entity&.public_send(id))
                url_ids[id] = entity_id
              end
            end

            url_ids.compact!

            # We haven't found all the required ids or we have a more specific match
            next if !(path_ids - url_ids.keys).empty? || path_ids.length <= max_ids

            max_ids = path_ids.length
            match = T.cast(path[:path], String).gsub(/(<([^>]+)>)/) do
              url_ids[T.unsafe(Regexp.last_match)[2].to_sym]
            end
          end

          custom_prefix ? "#{T.must(custom_prefix).sub(%r{\A/}, "")}/#{match}" : match
        end

        sig do
          params(
            http_method: Symbol,
            operation: Symbol,
          ).returns(T.nilable(T::Array[Symbol]))
        end
        def get_path_ids(http_method:, operation:)
          found_path = @paths.find do |path|
            http_method == path[:http_method] && operation == path[:operation]
          end
          return nil if found_path.nil?

          T.cast(found_path[:ids], T::Array[Symbol])
        end

        sig do
          params(
            http_method: Symbol,
            operation: T.any(String, Symbol),
            session: T.nilable(Auth::Session),
            ids: T::Hash[Symbol, String],
            params: T::Hash[Symbol, T.untyped],
            body: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
            entity: T.untyped,
          ).returns(Clients::HttpResponse)
        end
        def request(http_method:, operation:, session:, ids: {}, params: {}, body: nil, entity: nil)
          client = ShopifyAPI::Clients::Rest::Admin.new(session: session)

          path = get_path(http_method: http_method, operation: operation.to_sym, ids: ids)

          case http_method
          when :get
            client.get(path: T.must(path), query: params.compact, headers: headers)
          when :post
            client.post(path: T.must(path), query: params.compact, body: body || {}, headers: headers)
          when :put
            client.put(path: T.must(path), query: params.compact, body: body || {}, headers: headers)
          when :delete
            client.delete(path: T.must(path), query: params.compact, headers: headers)
          else
            raise Errors::InvalidHttpRequestError, "Invalid HTTP method: #{http_method}"
          end
        end

        sig { params(response: Clients::HttpResponse, session: Auth::Session).returns(T::Array[Base]) }
        def create_instances_from_response(response:, session:)
          objects = []

          body = T.cast(response.body, T::Hash[String, T.untyped]).with_indifferent_access

          response_names = json_response_body_names

          response_names.each do |response_name|
            if body.key?(response_name.pluralize) || (body.key?(response_name) && body[response_name].is_a?(Array))
              (body[response_name.pluralize] || body[response_name]).each do |entry|
                objects << create_instance(data: entry, session: session)
              end
            elsif body.key?(response_name)
              objects << create_instance(data: body[response_name], session: session)
            end
          end

          objects
        end

        sig do
          params(data: T::Hash[String, T.untyped], session: Auth::Session, instance: T.nilable(Base)).returns(Base)
        end
        def create_instance(data:, session:, instance: nil)
          instance ||= new(session: session)
          instance.original_state = {}

          data.each do |attribute, value|
            attr_sym = attribute.to_sym

            if has_many?(attr_sym) && value
              instance.original_state[attr_sym] = []
              attr_list = []
              value.each do |element|
                child = T.unsafe(@has_many[attr_sym]).create_instance(data: element, session: session)
                attr_list << child
                instance.original_state[attr_sym] << child.to_hash(true)
              end
              instance.public_send("#{attribute}=", attr_list)
            elsif has_one?(attr_sym) && value
              # force a hash if core returns values that instantiate objects like "USD"
              data_hash = value.is_a?(Hash) ? value : { attribute.to_s => value }
              child = T.unsafe(@has_one[attr_sym]).create_instance(data: data_hash, session: session)
              instance.public_send("#{attribute}=", child)
              instance.original_state[attr_sym] = child.to_hash(true)
            else
              instance.public_send("#{attribute}=", value)
              instance.original_state[attr_sym] = value
            end
          end

          instance
        end
      end

      sig { params(meth_id: Symbol, val: T.untyped).returns(T.untyped) }
      def method_missing(meth_id, val = nil)
        match = meth_id.id2name.match(/([^=]+)(=)?/)

        var = T.must(T.must(match)[1])

        if T.must(match)[2]
          set_property(var, val)
          @forced_nils[var] = val.nil?
        else
          get_property(var)
        end
      end

      sig { params(meth_id: Symbol, args: T.untyped).void }
      def respond_to_missing?(meth_id, *args)
        str = meth_id.id2name
        match = str.match(/([^=]+)=/)

        match.nil? ? true : super
      end

      sig { params(saving: T::Boolean).returns(T::Hash[String, T.untyped]) }
      def to_hash(saving = false)
        hash = {}
        instance_variables.each do |var|
          next if [
            :"@original_state",
            :"@session",
            :"@client",
            :"@forced_nils",
            :"@errors",
            :"@aliased_properties",
          ].include?(var)
          next if saving && self.class.read_only_attributes&.include?(var)

          var = var.to_s.delete("@")
          attribute = if @aliased_properties.value?(var)
            T.must(@aliased_properties.key(var))
          else
            var
          end.to_sym

          if self.class.has_many?(attribute)
            attribute_class = self.class.has_many[attribute]
            hash[attribute.to_s] = get_property(attribute).map do |element|
              get_element_hash(element, T.unsafe(attribute_class), saving)
            end.to_a if get_property(attribute)
          elsif self.class.has_one?(attribute)
            element_hash = get_element_hash(
              get_property(attribute),
              T.unsafe(self.class.has_one[attribute]),
              saving,
            )
            hash[attribute.to_s] = element_hash if element_hash || @forced_nils[attribute.to_s]
          elsif !get_property(attribute).nil? || @forced_nils[attribute.to_s]
            hash[attribute.to_s] =
              get_property(attribute)
          end
        end
        hash
      end

      sig { params(params: T::Hash[T.untyped, T.untyped]).void }
      def delete(params: {})
        @client.delete(
          path: T.must(self.class.get_path(http_method: :delete, operation: :delete, entity: self)),
          query: params.compact,
          headers: self.class.headers,
        )
      rescue ShopifyAPI::Errors::HttpResponseError => e
        @errors.errors << e
        raise
      end

      sig { void }
      def save!
        save(update_object: true)
      end

      sig { params(update_object: T::Boolean).void }
      def save(update_object: false)
        method = deduce_write_verb

        body = {
          self.class.json_body_name => attributes_to_update.merge(build_required_attributes(http_method: method)),
        }

        response = @client.public_send(
          method,
          body: body,
          path: deduce_write_path(method),
          headers: self.class.headers,
        )

        if update_object
          response_name = self.class.json_response_body_names & response.body.keys
          self.class.create_instance(data: response.body[response_name.first], session: @session, instance: self)
        end
      rescue ShopifyAPI::Errors::HttpResponseError => e
        @errors.errors << e
        raise
      end

      private

      sig { returns(T::Hash[String, String]) }
      def attributes_to_update
        updatable_attributes = original_state.reject do |attribute, _|
          self.class.read_only_attributes&.include?("@#{attribute}".to_sym)
        end

        stringified_updatable_attributes = deep_stringify_keys(updatable_attributes)
        stringified_new_attributes = deep_stringify_keys(to_hash(true))
        ShopifyAPI::Utils::AttributesComparator.compare(
          stringified_updatable_attributes,
          stringified_new_attributes,
          atomic_hash_attributes: self.class.atomic_hash_attributes || [],
        )
      end

      sig { params(http_method: Symbol).returns(T::Hash[String, T.untyped]) }
      def build_required_attributes(http_method:)
        required_attributes = {}

        primary_key_value = send(self.class.primary_key)
        unless primary_key_value.nil?
          required_attributes[self.class.primary_key] = primary_key_value
        end

        path_ids = deduce_path_ids(http_method)
        path_ids&.each do |path_id|
          path_id_value = send(path_id)
          required_attributes[path_id.to_s] = path_id_value unless path_id_value.nil?
        end

        required_attributes
      end

      sig { returns(Symbol) }
      def deduce_write_verb
        send(self.class.primary_key) ? :put : :post
      end

      sig { params(method: Symbol).returns(T.nilable(String)) }
      def deduce_write_path(method)
        path = self.class.get_path(http_method: method, operation: method, entity: self)

        if path.nil?
          method = method == :post ? :put : :post
          path = self.class.get_path(http_method: method, operation: method, entity: self)
        end

        path
      end

      sig { params(method: Symbol).returns(T.nilable(T::Array[Symbol])) }
      def deduce_path_ids(method)
        path_ids = self.class.get_path_ids(http_method: method, operation: method)

        if path_ids.nil?
          method = method == :post ? :put : :post
          path_ids = self.class.get_path_ids(http_method: method, operation: method)
        end

        path_ids
      end

      sig { params(hash: T::Hash[T.any(String, Symbol), T.untyped]).returns(T::Hash[String, String]) }
      def deep_stringify_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          new_key = key.to_s
          new_value = value.is_a?(Hash) ? deep_stringify_keys(value) : value
          result[new_key] = new_value
        end
      end

      sig { params(key: T.any(String, Symbol), val: T.untyped).void }
      def set_property(key, val)
        # Some API fields contain invalid characters, like `?`, which causes issues when setting them as instance
        # variables. To work around that, we're cleaning them up here but keeping track of the properties that were
        # aliased this way. When loading up the property, we can map back from the "invalid" field so that it is
        # transparent to outside callers
        clean_key = key.to_s.gsub(/[\?\s]/, "")
        @aliased_properties[key.to_s] = clean_key if clean_key != key

        instance_variable_set("@#{clean_key}", val)
      end

      sig { params(key: T.any(String, Symbol)).returns(T.untyped) }
      def get_property(key)
        clean_key = @aliased_properties.key?(key.to_s) ? @aliased_properties[key.to_s] : key

        instance_variable_get("@#{clean_key}")
      end

      sig do
        params(
          element: T.nilable(T.any(T::Hash[String, T.untyped], ShopifyAPI::Rest::Base)),
          attribute_class: T::Class[T.anything],
          saving: T::Boolean,
        ).returns(T.nilable(T::Hash[String, T.untyped]))
      end
      def get_element_hash(element, attribute_class, saving)
        return nil if element.nil?
        return element.to_hash(saving) unless element.is_a?(Hash)

        T.unsafe(attribute_class).create_instance(session: @session, data: element).to_hash(saving)
      end
    end
  end
end
