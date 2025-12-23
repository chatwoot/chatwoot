# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Webhooks
    class Registry
      @registry = T.let({}, T::Hash[String, Registration])
      MANDATORY_TOPICS = T.let([
        "shop/redact",
        "customers/redact",
        "customers/data_request",
      ].freeze, T::Array[String])

      class << self
        extend T::Sig
        sig do
          params(topic: String,
            delivery_method: Symbol,
            path: String,
            handler: T.nilable(T.any(Handler, WebhookHandler)),
            fields: T.nilable(T.any(String, T::Array[String])),
            filter: T.nilable(String),
            metafield_namespaces: T.nilable(T::Array[String])).void
        end
        def add_registration(topic:, delivery_method:, path:, handler: nil, fields: nil, filter: nil,
          metafield_namespaces: nil)
          @registry[topic] = case delivery_method
          when :pub_sub
            Registrations::PubSub.new(topic: topic, path: path, fields: fields,
              metafield_namespaces: metafield_namespaces, filter: filter)
          when :event_bridge
            Registrations::EventBridge.new(topic: topic, path: path, fields: fields,
              metafield_namespaces: metafield_namespaces, filter: filter)
          when :http
            unless handler
              raise Errors::InvalidWebhookRegistrationError, "Cannot create an Http registration without a handler."
            end

            Registrations::Http.new(topic: topic, path: path, handler: handler,
              fields: fields, metafield_namespaces: metafield_namespaces, filter: filter)
          else
            raise Errors::InvalidWebhookRegistrationError,
              "Unsupported delivery method #{delivery_method}. Allowed values: {:http, :pub_sub, :event_bridge}."
          end
        end

        sig { void }
        def clear
          @registry.clear
        end

        sig do
          params(
            topic: String,
            session: Auth::Session,
          ).returns(RegisterResult)
        end
        def register(topic:, session:)
          return mandatory_registration_result(topic) if mandatory_webhook_topic?(topic)

          registration = @registry[topic]

          unless registration
            raise Errors::InvalidWebhookRegistrationError, "Webhook topic #{topic} has not been added to the registry."
          end

          client = Clients::Graphql::Admin.new(session: session)
          register_check_result = webhook_registration_needed?(client, registration)

          registered = true
          register_body = nil

          if register_check_result[:must_register]
            register_body = send_register_request(
              client,
              registration,
              register_check_result[:webhook_id],
            )
            registered = registration_sucessful?(
              register_body,
              registration.mutation_name(register_check_result[:webhook_id]),
            )
          end

          RegisterResult.new(topic: topic, success: registered, body: register_body)
        end

        sig do
          params(topic: String).returns(RegisterResult)
        end
        def mandatory_registration_result(topic)
          RegisterResult.new(
            topic: topic,
            success: false,
            body: "Mandatory webhooks are to be registered in the partners dashboard",
          )
        end

        sig do
          params(
            session: Auth::Session,
          ).returns(T::Array[RegisterResult])
        end
        def register_all(session:)
          topics = @registry.keys
          result = T.let([], T::Array[RegisterResult])
          topics.each do |topic|
            register_response = register(
              topic: topic,
              session: session,
            )
            result.push(register_response)
          end
          result
        end

        sig do
          params(
            topic: String,
            session: T.nilable(Auth::Session),
          ).returns(T::Hash[String, T.untyped])
        end
        def unregister(topic:, session:)
          return { "response": nil } if mandatory_webhook_topic?(topic)

          client = Clients::Graphql::Admin.new(session: session)

          webhook_id = get_webhook_id(topic: topic, client: client)
          return {} if webhook_id.nil?

          delete_mutation = <<~MUTATION
            mutation webhookSubscription {
              webhookSubscriptionDelete(id: "#{webhook_id}") {
                userErrors {
                  field
                  message
                }
                deletedWebhookSubscriptionId
              }
            }
          MUTATION

          delete_response = client.query(query: delete_mutation, response_as_struct: false)
          raise Errors::WebhookRegistrationError,
            "Failed to delete webhook from Shopify" unless delete_response.ok?
          result = T.cast(delete_response.body, T::Hash[String, T.untyped])
          errors = result["errors"] || {}
          raise Errors::WebhookRegistrationError,
            "Failed to delete webhook from Shopify: #{errors[0]["message"]}" unless errors.empty?
          user_errors = result.dig("data", "webhookSubscriptionDelete", "userErrors") || {}
          raise Errors::WebhookRegistrationError,
            "Failed to delete webhook from Shopify: #{user_errors[0]["message"]}" unless user_errors.empty?
          result
        end

        sig do
          params(
            topic: String,
            client: Clients::Graphql::Admin,
          ).returns(T.nilable(String))
        end
        def get_webhook_id(topic:, client:)
          fetch_id_query = <<~QUERY
            {
              webhookSubscriptions(first: 1, topics: #{topic.gsub(%r{/|\.}, "_").upcase}) {
                edges {
                  node {
                    id
                  }
                }
              }
            }
          QUERY

          fetch_id_response = client.query(query: fetch_id_query, response_as_struct: false)
          raise Errors::WebhookRegistrationError,
            "Failed to fetch webhook from Shopify" unless fetch_id_response.ok?
          body = T.cast(fetch_id_response.body, T::Hash[String, T.untyped])
          errors = body["errors"] || {}
          raise Errors::WebhookRegistrationError,
            "Failed to fetch webhook from Shopify: #{errors[0]["message"]}" unless errors.empty?

          edges = body.dig("data", "webhookSubscriptions", "edges") || {}
          return nil if edges.empty?

          edges[0]["node"]["id"].to_s
        end
        sig { params(request: Request).void }
        def process(request)
          raise Errors::InvalidWebhookError, "Invalid webhook HMAC." unless Utils::HmacValidator.validate(request)

          handler = @registry[request.topic]&.handler

          unless handler
            raise Errors::NoWebhookHandler, "No webhook handler found for topic: #{request.topic}."
          end

          if handler.is_a?(WebhookHandler)
            handler.handle(data: WebhookMetadata.new(topic: request.topic, shop: request.shop,
              body: request.parsed_body, api_version: request.api_version, webhook_id: request.webhook_id))
          else
            handler.handle(topic: request.topic, shop: request.shop, body: request.parsed_body)
            warning = <<~WARNING
              DEPRECATED: Use ShopifyAPI::Webhooks::WebhookHandler#handle instead of
              ShopifyAPI::Webhooks::Handler#handle.
              https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/webhooks.md#create-a-webhook-handler
            WARNING
            ShopifyAPI::Logger.deprecated(warning, "15.0.0")
          end
        end

        private

        sig do
          params(
            client: Clients::Graphql::Admin,
            registration: Registration,
          ).returns(T::Hash[Symbol, T.untyped])
        end
        def webhook_registration_needed?(client, registration)
          check_response = client.query(query: registration.build_check_query, response_as_struct: false)
          raise Errors::WebhookRegistrationError,
            "Failed to check if webhook was already registered" unless check_response.ok?

          parsed_check_result = registration.parse_check_result(T.cast(check_response.body, T::Hash[String, T.untyped]))
          registration_fields = registration.fields || []
          registration_metafield_namespaces = registration.metafield_namespaces || []
          registration_filter = registration.filter

          must_register = parsed_check_result[:current_address] != registration.callback_address ||
            parsed_check_result[:fields].sort != registration_fields.sort ||
            parsed_check_result[:metafield_namespaces].sort != registration_metafield_namespaces.sort ||
            parsed_check_result[:filter] != registration_filter

          { webhook_id: parsed_check_result[:webhook_id], must_register: must_register }
        end

        sig do
          params(
            client: Clients::Graphql::Admin,
            registration: Registration,
            webhook_id: T.nilable(String),
          ).returns(T::Hash[String, T.untyped])
        end
        def send_register_request(client, registration, webhook_id)
          register_response = client.query(query: registration.build_register_query(webhook_id: webhook_id),
            response_as_struct: false)

          raise Errors::WebhookRegistrationError, "Failed to register webhook with Shopify" unless register_response.ok?

          T.cast(register_response.body, T::Hash[String, T.untyped])
        end

        sig { params(body: T::Hash[String, T.untyped], mutation_name: String).returns(T::Boolean) }
        def registration_sucessful?(body, mutation_name)
          !body.dig("data", mutation_name, "webhookSubscription").nil?
        end

        # Mandatory webhooks are subscribed to via the partner dashboard not the API
        # https://shopify.dev/docs/apps/webhooks/configuration/mandatory-webhooks
        sig { params(topic: String).returns(T::Boolean) }
        def mandatory_webhook_topic?(topic)
          MANDATORY_TOPICS.include?(topic)
        end
      end
    end
  end
end
