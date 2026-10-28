<script>
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CallRecordingSettings from './CallRecordingSettings.vue';
import CallAnnouncementSettings from './CallAnnouncementSettings.vue';
import SettingsCheckboxOption from './SettingsCheckboxOption.vue';

export default {
  components: {
    SettingsToggleSection,
    NextInput,
    NextButton,
    Spinner,
    CallRecordingSettings,
    CallAnnouncementSettings,
    SettingsCheckboxOption,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      voiceEnabled: this.inbox.voice_enabled || false,
      inboundCallsEnabled: this.inbox.inbound_calls_enabled !== false,
      apiKeySid: this.inbox.api_key_sid || '',
      apiKeySecret: '',
      authToken: '',
      isUpdating: false,
      isTogglingInbound: false,
    };
  },
  computed: {
    hasApiKeySid() {
      return !!this.inbox.api_key_sid;
    },
    hasExistingCredentials() {
      return this.hasApiKeySid && !!this.inbox.has_api_key_secret;
    },
    needsCredentials() {
      return this.voiceEnabled && !this.hasExistingCredentials;
    },
    needsAccountAuthToken() {
      return (
        this.voiceEnabled &&
        this.hasApiKeySid &&
        !this.inbox.account_auth_token_configured
      );
    },
    needsApiKeySid() {
      return this.needsCredentials && !this.hasApiKeySid;
    },
    webhookUrls() {
      return [
        {
          key: 'VOICE',
          url: this.inbox.voice_call_webhook_url,
        },
        {
          key: 'STATUS',
          url: this.inbox.voice_status_webhook_url,
        },
      ];
    },
    isSubmitDisabled() {
      if (!this.voiceEnabled) return false;
      if (this.needsAccountAuthToken && !this.authToken) return true;
      if (this.needsCredentials) {
        if (this.needsApiKeySid && !this.apiKeySid) return true;
        return !this.apiKeySecret;
      }
      return false;
    },
  },
  watch: {
    'inbox.voice_enabled'(val) {
      this.voiceEnabled = val || false;
    },
    'inbox.api_key_sid'(val) {
      this.apiKeySid = val || '';
    },
    'inbox.inbound_calls_enabled'(val) {
      this.inboundCallsEnabled = val !== false;
    },
  },
  methods: {
    async copyUrl(url) {
      try {
        await copyTextToClipboard(url);
        useAlert(this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
      } catch (_) {
        useAlert(this.$t('COMPONENTS.CODE.COPY_ERROR'));
      }
    },
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
    // SMS upgrades collect the account token separately from API key credentials.
    async handleVoiceToggle(newValue) {
      if (this.isUpdating) return;
      const previousValue = this.voiceEnabled;
      this.voiceEnabled = newValue;

      if (this.needsAccountAuthToken || this.needsCredentials) return;

      try {
        await this.updateVoiceSettings();
      } catch (_) {
        this.voiceEnabled = previousValue;
      }
    },
    async submitVoiceCredentials() {
      try {
        await this.updateVoiceSettings();
      } catch (_) {
        this.voiceEnabled = this.inbox.voice_enabled || false;
      }
    },
    async updateVoiceSettings() {
      this.isUpdating = true;
      try {
        const channelPayload = { voice_enabled: this.voiceEnabled };
        if (this.needsAccountAuthToken) {
          channelPayload.auth_token = this.authToken;
        }

        if (this.needsCredentials) {
          if (this.needsApiKeySid) {
            channelPayload.api_key_sid = this.apiKeySid;
          }
          channelPayload.api_key_secret = this.apiKeySecret;
        }

        await this.$store.dispatch('inboxes/updateInbox', {
          id: this.inbox.id,
          formData: false,
          channel: channelPayload,
        });
        this.apiKeySecret = '';
        this.authToken = '';
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
        throw error;
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div :class="{ 'pointer-events-none opacity-60': isUpdating }">
      <SettingsToggleSection
        :model-value="voiceEnabled"
        :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.ENABLE_VOICE.LABEL')"
        :description="
          $t('INBOX_MGMT.VOICE_CONFIGURATION.ENABLE_VOICE.DESCRIPTION')
        "
        :hide-toggle="isUpdating"
        @update:model-value="handleVoiceToggle"
      >
        <template v-if="isUpdating" #hiddenToggle>
          <Spinner class="size-4 text-n-slate-11" />
        </template>
        <template v-if="needsAccountAuthToken || needsCredentials" #editor>
          <div class="flex flex-col gap-4 pt-2">
            <p class="text-body-main text-n-slate-11">
              {{ $t('INBOX_MGMT.VOICE_CONFIGURATION.CREDENTIALS.DESCRIPTION') }}
            </p>
            <NextInput
              v-if="needsApiKeySid"
              v-model="apiKeySid"
              :label="$t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL')"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER')
              "
            />
            <NextInput
              v-if="needsAccountAuthToken"
              v-model="authToken"
              type="password"
              :label="$t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.LABEL')"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.PLACEHOLDER')
              "
            />
            <NextInput
              v-if="needsCredentials"
              v-model="apiKeySecret"
              type="password"
              :label="$t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL')"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER')
              "
            />
            <div class="flex justify-end">
              <NextButton
                :disabled="isSubmitDisabled"
                :is-loading="isUpdating"
                :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                sm
                @click="submitVoiceCredentials"
              />
            </div>
          </div>
        </template>
        <template v-else-if="inbox.voice_enabled" #editor>
          <div class="flex flex-col gap-3 pt-2">
            <CallAnnouncementSettings
              :inbox="inbox"
              kind="out_of_hours"
              i18n-key="BUSINESS_HOURS"
              :enabled="!!inbox.business_hours_calls_enabled"
              :message="inbox.out_of_hours_call_message || ''"
              :audio-url="inbox.out_of_hours_call_audio_url || ''"
              checkbox
            >
              <template v-if="!inbox.working_hours_enabled" #notice>
                <p class="text-body-main text-n-amber-11">
                  {{
                    $t(
                      'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.HOURS_NOT_ENABLED'
                    )
                  }}
                </p>
              </template>
            </CallAnnouncementSettings>
            <SettingsCheckboxOption
              :model-value="inboundCallsEnabled"
              :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.OPTIONS.INBOUND')"
              :class="{ 'pointer-events-none opacity-60': isTogglingInbound }"
              @update:model-value="handleInboundToggle"
            />
            <CallRecordingSettings :inbox="inbox" checkbox />
          </div>
        </template>
      </SettingsToggleSection>
    </div>

    <CallAnnouncementSettings
      v-if="inbox.voice_enabled"
      :inbox="inbox"
      kind="greeting"
      i18n-key="GREETING"
      :enabled="!!inbox.call_greeting_enabled"
      :message="inbox.call_greeting_message || ''"
    />

    <CallAnnouncementSettings
      v-if="inbox.voice_enabled"
      :inbox="inbox"
      kind="unanswered"
      i18n-key="UNANSWERED"
      :enabled="!!inbox.unanswered_calls_enabled"
      :message="inbox.unanswered_call_message || ''"
      :timeout-seconds="inbox.unanswered_call_timeout_seconds"
    />

    <div
      v-if="inbox.voice_enabled && inbox.voice_call_webhook_url"
      class="flex flex-col outline outline-1 -outline-offset-1 outline-n-weak rounded-xl divide-y divide-n-weak"
    >
      <div
        v-for="webhook in webhookUrls"
        :key="webhook.key"
        class="flex flex-col gap-1 px-4 py-3"
      >
        <span class="text-heading-3 text-n-slate-12">
          {{
            $t(
              `INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_${webhook.key}_URL_TITLE`
            )
          }}
        </span>
        <span class="text-body-main text-n-slate-11">
          {{
            $t(
              `INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_${webhook.key}_URL_SUBTITLE`
            )
          }}
        </span>
        <div class="flex items-center gap-2 mt-2">
          <code
            class="flex-1 min-w-0 px-3 py-2 text-sm truncate rounded-lg bg-n-alpha-black2 text-n-teal-11"
          >
            {{ webhook.url }}
          </code>
          <NextButton
            :label="$t('COMPONENTS.CODE.BUTTON_TEXT')"
            slate
            outline
            sm
            @click="copyUrl(webhook.url)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
