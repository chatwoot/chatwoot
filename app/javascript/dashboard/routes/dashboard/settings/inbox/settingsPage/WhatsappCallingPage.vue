<script>
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

export default {
  components: {
    SettingsFieldSection,
    SettingsToggleSection,
    NextButton,
    TextArea,
    Spinner,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      callingEnabled: this.inbox.provider_config?.calling_enabled || false,
      inboundCallsEnabled:
        this.inbox.provider_config?.inbound_calls_enabled !== false,
      permissionRequestBody:
        this.inbox.provider_config?.call_permission_request_body || '',
      isUpdating: false,
      isTogglingCalling: false,
      isTogglingInbound: false,
    };
  },
  computed: {
    phoneNumber() {
      return (
        this.inbox.provider_config?.phone_number || this.inbox.phone_number
      );
    },
  },
  watch: {
    'inbox.provider_config.calling_enabled'(val) {
      this.callingEnabled = val || false;
    },
    'inbox.provider_config.call_permission_request_body'(val) {
      this.permissionRequestBody = val || '';
    },
    'inbox.provider_config.inbound_calls_enabled'(val) {
      this.inboundCallsEnabled = val !== false;
    },
  },
  methods: {
    async handleInboundToggle(newValue) {
      if (this.isTogglingInbound) return;
      const previousValue = this.inboundCallsEnabled;
      this.inboundCallsEnabled = newValue;
      this.isTogglingInbound = true;
      try {
        await InboxesAPI.setInboundCalls(this.inbox.id, newValue);
        await this.$store.dispatch('inboxes/get', this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (_) {
        this.inboundCallsEnabled = previousValue;
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      } finally {
        this.isTogglingInbound = false;
      }
    },
    async handleCallingToggle(newValue) {
      if (this.isTogglingCalling) return;
      const previousValue = this.callingEnabled;
      this.callingEnabled = newValue;
      this.isTogglingCalling = true;
      try {
        if (newValue) {
          await InboxesAPI.enableWhatsappCalling(this.inbox.id);
        } else {
          await InboxesAPI.disableWhatsappCalling(this.inbox.id);
        }
        await this.$store.dispatch('inboxes/get', this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (_) {
        this.callingEnabled = previousValue;
        const fallbackKey = newValue
          ? 'INBOX_MGMT.WHATSAPP_CALLING.ENABLE_FAILED'
          : 'INBOX_MGMT.EDIT.API.ERROR_MESSAGE';
        useAlert(this.$t(fallbackKey));
      } finally {
        this.isTogglingCalling = false;
      }
    },
    async updateCallingSettings() {
      this.isUpdating = true;
      try {
        await this.$store.dispatch('inboxes/updateInbox', {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              call_permission_request_body:
                this.permissionRequestBody.trim() || null,
            },
          },
        });
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        const message =
          error?.response?.data?.message ||
          this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE');
        useAlert(message);
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <div
      class="relative"
      :class="{ 'pointer-events-none opacity-60': isTogglingCalling }"
    >
      <SettingsToggleSection
        :model-value="callingEnabled"
        :header="$t('INBOX_MGMT.WHATSAPP_CALLING.ENABLE.LABEL')"
        :description="$t('INBOX_MGMT.WHATSAPP_CALLING.ENABLE.DESCRIPTION')"
        :hide-toggle="isTogglingCalling"
        @update:model-value="handleCallingToggle"
      >
        <template v-if="isTogglingCalling" #hiddenToggle>
          <Spinner class="size-4 text-n-slate-11" />
        </template>
      </SettingsToggleSection>
    </div>

    <template v-if="callingEnabled">
      <div
        class="relative"
        :class="{ 'pointer-events-none opacity-60': isTogglingInbound }"
      >
        <SettingsToggleSection
          :model-value="inboundCallsEnabled"
          :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.INBOUND.LABEL')"
          :description="
            $t('INBOX_MGMT.VOICE_CONFIGURATION.INBOUND.DESCRIPTION')
          "
          :hide-toggle="isTogglingInbound"
          @update:model-value="handleInboundToggle"
        >
          <template v-if="isTogglingInbound" #hiddenToggle>
            <Spinner class="size-4 text-n-slate-11" />
          </template>
        </SettingsToggleSection>
      </div>

      <SettingsFieldSection
        v-if="phoneNumber"
        :label="$t('INBOX_MGMT.WHATSAPP_CALLING.PHONE_NUMBER.LABEL')"
        :help-text="$t('INBOX_MGMT.WHATSAPP_CALLING.PHONE_NUMBER.HELP_TEXT')"
      >
        <woot-code :script="phoneNumber" lang="html" />
      </SettingsFieldSection>

      <SettingsFieldSection
        :label="$t('INBOX_MGMT.WHATSAPP_CALLING.PERMISSION_REQUEST_BODY.LABEL')"
        :help-text="
          $t('INBOX_MGMT.WHATSAPP_CALLING.PERMISSION_REQUEST_BODY.HELP_TEXT')
        "
      >
        <TextArea
          v-model="permissionRequestBody"
          :placeholder="
            $t(
              'INBOX_MGMT.WHATSAPP_CALLING.PERMISSION_REQUEST_BODY.PLACEHOLDER'
            )
          "
          auto-height
          resize
        />
      </SettingsFieldSection>

      <SettingsFieldSection
        :label="$t('INBOX_MGMT.WHATSAPP_CALLING.HOW_IT_WORKS.LABEL')"
        :help-text="$t('INBOX_MGMT.WHATSAPP_CALLING.HOW_IT_WORKS.DESCRIPTION')"
      />

      <div>
        <NextButton
          :is-loading="isUpdating"
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          @click="updateCallingSettings"
        />
      </div>
    </template>
  </div>
</template>
