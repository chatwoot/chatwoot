# Applies the Keycloak integration to upstream Chatwoot classes by prepending modules, so no upstream
# file has to be edited. Called from config/initializers/keycloak.rb (config.to_prepare).
module Keycloak::Patches
  # capability => policy methods that the capability additionally allows
  POLICY_CAPABILITIES = {
    'AutomationRulePolicy' => {
      can_manage_automations: %i[index? create? show? update? clone? destroy?]
    },
    'CampaignPolicy' => {
      can_manage_campaigns: %i[index? update? show? create? destroy?]
    },
    'ContactPolicy' => {
      can_import_contacts: %i[import?],
      can_export_contacts: %i[export?],
      can_delete_contacts: %i[destroy?]
    },
    'ConversationPolicy' => {
      can_delete_conversations: %i[destroy?],
      can_view_all_inboxes: %i[show?]
    },
    'InboxPolicy' => {
      can_manage_campaigns: %i[campaigns?],
      can_manage_inboxes: %i[create? update? destroy? set_agent_bot? avatar? sync_templates?
                             whatsapp_business_management_token? health? reset_secret? rotate_hmac_token?
                             enable_whatsapp_calling? disable_whatsapp_calling? set_inbound_calls? set_call_recording?]
    },
    'ReportPolicy' => {
      can_view_reports: %i[view?]
    }
  }.freeze

  class << self
    def apply!
      prepend_once('AccountUser', AccountUserExtension)
      prepend_once('User', UserExtension)
      prepend_once('RequestExceptionHandler', RequestExceptionHandlerExtension)
      prepend_once('DeviseOverrides::OmniauthCallbacksController', OmniauthCallbacksControllerExtension)
      prepend_once('Api::V1::Accounts::ContactsController', ContactsControllerExtension)
      prepend_once('DashboardController', DashboardControllerExtension)
      prepend_once('SearchService', SearchServiceExtension)
      prepend_once('Conversations::UnreadCounts::Counter', UnreadCountsCounterExtension)
      apply_policies!
      enable_openid_connect_provider!
    end

    private

    def prepend_once(class_name, extension)
      target = class_name.constantize
      target.prepend(extension) unless target < extension
    end

    def apply_policies!
      @policy_extensions ||= {}
      POLICY_CAPABILITIES.each do |policy_name, mapping|
        policy = policy_name.constantize
        extension = (@policy_extensions[policy_name] ||= policy_extension(mapping))
        policy.prepend(extension) unless policy < extension
      end
    end

    def policy_extension(mapping)
      Module.new do
        mapping.each do |capability, policy_methods|
          policy_methods.each do |policy_method|
            define_method(policy_method) { super() || keycloak_permission?(capability) }
          end
        end

        private

        def keycloak_permission?(capability)
          @account_user.present? && @account_user.has_permission?(capability)
        end
      end
    end

    def enable_openid_connect_provider!
      return if ::User.omniauth_providers.include?(:openid_connect)

      ::User.omniauth_providers = ::User.omniauth_providers + [:openid_connect]
    end
  end
end
