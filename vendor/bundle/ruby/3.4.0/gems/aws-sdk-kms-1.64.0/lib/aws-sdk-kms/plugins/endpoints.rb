# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


module Aws::KMS
  module Plugins
    class Endpoints < Seahorse::Client::Plugin
      option(
        :endpoint_provider,
        doc_type: 'Aws::KMS::EndpointProvider',
        docstring: 'The endpoint provider used to resolve endpoints. Any '\
                   'object that responds to `#resolve_endpoint(parameters)` '\
                   'where `parameters` is a Struct similar to '\
                   '`Aws::KMS::EndpointParameters`'
      ) do |cfg|
        Aws::KMS::EndpointProvider.new
      end

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          # If endpoint was discovered, do not resolve or apply the endpoint.
          unless context[:discovered_endpoint]
            params = parameters_for_operation(context)
            endpoint = context.config.endpoint_provider.resolve_endpoint(params)

            context.http_request.endpoint = endpoint.url
            apply_endpoint_headers(context, endpoint.headers)
          end

          context[:endpoint_params] = params
          context[:auth_scheme] =
            Aws::Endpoints.resolve_auth_scheme(context, endpoint)

          @handler.call(context)
        end

        private

        def apply_endpoint_headers(context, headers)
          headers.each do |key, values|
            value = values
              .compact
              .map { |s| Seahorse::Util.escape_header_list_string(s.to_s) }
              .join(',')

            context.http_request.headers[key] = value
          end
        end

        def parameters_for_operation(context)
          case context.operation_name
          when :cancel_key_deletion
            Aws::KMS::Endpoints::CancelKeyDeletion.build(context)
          when :connect_custom_key_store
            Aws::KMS::Endpoints::ConnectCustomKeyStore.build(context)
          when :create_alias
            Aws::KMS::Endpoints::CreateAlias.build(context)
          when :create_custom_key_store
            Aws::KMS::Endpoints::CreateCustomKeyStore.build(context)
          when :create_grant
            Aws::KMS::Endpoints::CreateGrant.build(context)
          when :create_key
            Aws::KMS::Endpoints::CreateKey.build(context)
          when :decrypt
            Aws::KMS::Endpoints::Decrypt.build(context)
          when :delete_alias
            Aws::KMS::Endpoints::DeleteAlias.build(context)
          when :delete_custom_key_store
            Aws::KMS::Endpoints::DeleteCustomKeyStore.build(context)
          when :delete_imported_key_material
            Aws::KMS::Endpoints::DeleteImportedKeyMaterial.build(context)
          when :describe_custom_key_stores
            Aws::KMS::Endpoints::DescribeCustomKeyStores.build(context)
          when :describe_key
            Aws::KMS::Endpoints::DescribeKey.build(context)
          when :disable_key
            Aws::KMS::Endpoints::DisableKey.build(context)
          when :disable_key_rotation
            Aws::KMS::Endpoints::DisableKeyRotation.build(context)
          when :disconnect_custom_key_store
            Aws::KMS::Endpoints::DisconnectCustomKeyStore.build(context)
          when :enable_key
            Aws::KMS::Endpoints::EnableKey.build(context)
          when :enable_key_rotation
            Aws::KMS::Endpoints::EnableKeyRotation.build(context)
          when :encrypt
            Aws::KMS::Endpoints::Encrypt.build(context)
          when :generate_data_key
            Aws::KMS::Endpoints::GenerateDataKey.build(context)
          when :generate_data_key_pair
            Aws::KMS::Endpoints::GenerateDataKeyPair.build(context)
          when :generate_data_key_pair_without_plaintext
            Aws::KMS::Endpoints::GenerateDataKeyPairWithoutPlaintext.build(context)
          when :generate_data_key_without_plaintext
            Aws::KMS::Endpoints::GenerateDataKeyWithoutPlaintext.build(context)
          when :generate_mac
            Aws::KMS::Endpoints::GenerateMac.build(context)
          when :generate_random
            Aws::KMS::Endpoints::GenerateRandom.build(context)
          when :get_key_policy
            Aws::KMS::Endpoints::GetKeyPolicy.build(context)
          when :get_key_rotation_status
            Aws::KMS::Endpoints::GetKeyRotationStatus.build(context)
          when :get_parameters_for_import
            Aws::KMS::Endpoints::GetParametersForImport.build(context)
          when :get_public_key
            Aws::KMS::Endpoints::GetPublicKey.build(context)
          when :import_key_material
            Aws::KMS::Endpoints::ImportKeyMaterial.build(context)
          when :list_aliases
            Aws::KMS::Endpoints::ListAliases.build(context)
          when :list_grants
            Aws::KMS::Endpoints::ListGrants.build(context)
          when :list_key_policies
            Aws::KMS::Endpoints::ListKeyPolicies.build(context)
          when :list_keys
            Aws::KMS::Endpoints::ListKeys.build(context)
          when :list_resource_tags
            Aws::KMS::Endpoints::ListResourceTags.build(context)
          when :list_retirable_grants
            Aws::KMS::Endpoints::ListRetirableGrants.build(context)
          when :put_key_policy
            Aws::KMS::Endpoints::PutKeyPolicy.build(context)
          when :re_encrypt
            Aws::KMS::Endpoints::ReEncrypt.build(context)
          when :replicate_key
            Aws::KMS::Endpoints::ReplicateKey.build(context)
          when :retire_grant
            Aws::KMS::Endpoints::RetireGrant.build(context)
          when :revoke_grant
            Aws::KMS::Endpoints::RevokeGrant.build(context)
          when :schedule_key_deletion
            Aws::KMS::Endpoints::ScheduleKeyDeletion.build(context)
          when :sign
            Aws::KMS::Endpoints::Sign.build(context)
          when :tag_resource
            Aws::KMS::Endpoints::TagResource.build(context)
          when :untag_resource
            Aws::KMS::Endpoints::UntagResource.build(context)
          when :update_alias
            Aws::KMS::Endpoints::UpdateAlias.build(context)
          when :update_custom_key_store
            Aws::KMS::Endpoints::UpdateCustomKeyStore.build(context)
          when :update_key_description
            Aws::KMS::Endpoints::UpdateKeyDescription.build(context)
          when :update_primary_region
            Aws::KMS::Endpoints::UpdatePrimaryRegion.build(context)
          when :verify
            Aws::KMS::Endpoints::Verify.build(context)
          when :verify_mac
            Aws::KMS::Endpoints::VerifyMac.build(context)
          end
        end
      end

      def add_handlers(handlers, _config)
        handlers.add(Handler, step: :build, priority: 75)
      end
    end
  end
end
