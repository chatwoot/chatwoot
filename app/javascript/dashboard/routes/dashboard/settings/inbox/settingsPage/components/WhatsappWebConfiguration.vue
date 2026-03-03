<script>
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextInput from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import WhatsappWebChannel from 'dashboard/api/channel/whatsappWebChannel';
import {
  isValidWhatsappWebPhone,
  normalizeWhatsappWebPhone,
} from '../../channels/whatsappWebPhone';

export default {
  components: {
    SettingsFieldSection,
    NextButton,
    TextInput,
    TextArea,
    Checkbox,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      config: null,
      evolutionBaseUrl: '',
      evolutionBasePath: '',
      evolutionApiKey: '',
      phone: '',
      instanceName: '',
      signMsg: false,
      signDelimiter: '\\n',
      msgCall: '',
      reopenConversation: false,
      conversationPending: false,
      importContacts: true,
      importMessages: true,
      ignoreJidsText: '',
      rejectCall: false,
      ignoreGroups: false,
      alwaysOnline: false,
      readMessages: false,
      readStatus: false,
      syncFullHistory: false,
      daysLimitImportMessages: 60,
      pairCode: '',
      qrLink: '',
      qrDuration: null,
      statusPayload: null,
      syncPayload: null,
      devices: [],
      uiFlags: {
        loading: false,
        saving: false,
        testing: false,
        settingUp: false,
        loggingIn: false,
        cancelling: false,
        syncing: false,
      },
    };
  },
  computed: {
    hasInstanceName() {
      return this.instanceName.trim().length > 0;
    },
    normalizedPhone() {
      return normalizeWhatsappWebPhone(this.phone);
    },
    isPhoneValid() {
      return isValidWhatsappWebPhone(this.phone);
    },
    isPhoneLocked() {
      return normalizeWhatsappWebPhone(this.config?.phone || '').length > 0;
    },
    phoneError() {
      if (this.phone.trim() && !this.isPhoneValid) {
        return this.$t(
          'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PAIR_PHONE_ERROR'
        );
      }

      return '';
    },
    formattedPairCode() {
      const normalized = (this.pairCode || '')
        .toString()
        .trim()
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, '');

      if (!normalized) return '';
      if (normalized.length <= 4) return normalized;
      return `${normalized.slice(0, 4)}-${normalized.slice(4, 8)}`;
    },
    canRequestQr() {
      return this.statusFlagValue('can_request_qr', this.hasInstanceName);
    },
    canRequestPairCode() {
      return this.statusFlagValue(
        'can_request_pair_code',
        this.hasInstanceName
      );
    },
    canReconnect() {
      return this.statusFlagValue('can_reconnect', this.hasInstanceName);
    },
    canCancel() {
      return this.statusFlagValue('can_cancel', false);
    },
    canLogout() {
      return this.statusFlagValue('can_logout', this.hasInstanceName);
    },
    canRemoveDevice() {
      return this.statusFlagValue('can_remove_device', this.hasInstanceName);
    },
  },
  mounted() {
    this.loadConfig();
  },
  methods: {
    inboxId() {
      return this.inbox.id;
    },
    selectedInstanceName() {
      return this.instanceName.trim();
    },
    boolValue(value, fallback) {
      return typeof value === 'boolean' ? value : fallback;
    },
    statusFlagValue(flagName, fallback) {
      if (
        this.statusPayload &&
        Object.prototype.hasOwnProperty.call(this.statusPayload, flagName)
      ) {
        return !!this.statusPayload[flagName];
      }

      return fallback;
    },
    apiKeyPlaceholder() {
      if (!this.config?.evolution_api_key_configured) {
        return '';
      }

      return this.$t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PASSWORD_PLACEHOLDER'
      );
    },
    clearLoginArtifacts() {
      this.qrLink = '';
      this.qrDuration = null;
      this.pairCode = '';
    },
    applyStatusPayload(status) {
      this.statusPayload = status || null;

      const state = this.statusPayload?.state || 'unknown';
      const isLoggedIn = !!this.statusPayload?.is_logged_in;
      if (isLoggedIn || state === 'missing' || state === 'close') {
        this.clearLoginArtifacts();
      }
    },
    applyConfig(config) {
      if (!config) return;
      this.config = config;
      this.evolutionBaseUrl = config.evolution_base_url || '';
      this.evolutionBasePath = config.evolution_base_path || '';
      this.phone = normalizeWhatsappWebPhone(config.phone || '');
      this.instanceName = config.instance_name || '';
      this.signMsg = this.boolValue(config.sign_msg, false);
      this.signDelimiter = config.sign_delimiter || '\\n';
      this.msgCall = config.msg_call || '';
      this.reopenConversation = this.boolValue(
        config.reopen_conversation,
        false
      );
      this.conversationPending = this.boolValue(
        config.conversation_pending,
        false
      );
      this.importContacts = this.boolValue(config.import_contacts, true);
      this.importMessages = this.boolValue(config.import_messages, true);
      this.ignoreJidsText = this.formatIgnoreJidsForDisplay(config.ignore_jids);
      this.rejectCall = this.boolValue(config.reject_call, false);
      this.ignoreGroups = this.boolValue(config.ignore_groups, false);
      this.alwaysOnline = this.boolValue(config.always_online, false);
      this.readMessages = this.boolValue(config.read_messages, false);
      this.readStatus = this.boolValue(config.read_status, false);
      this.syncFullHistory = this.boolValue(config.sync_full_history, false);
      this.daysLimitImportMessages =
        Number(config.days_limit_import_messages) || 60;
      this.evolutionApiKey = '';
    },
    getErrorMessage(error, fallbackMessage) {
      return (
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        fallbackMessage
      );
    },
    onPhoneInput(event) {
      this.phone = normalizeWhatsappWebPhone(event.target.value);
    },
    normalizeIgnoreNumber(value) {
      return value
        .toString()
        .trim()
        .split('@')[0]
        .replace(/\D/g, '')
        .slice(0, 11);
    },
    formatIgnoreJidsForDisplay(value) {
      const values = Array.isArray(value)
        ? value
        : value.toString().split(/[\r\n,]+/);

      return values
        .map(jid => this.normalizeIgnoreNumber(jid))
        .filter(Boolean)
        .join('\n');
    },
    onIgnoreJidsInput(value) {
      this.ignoreJidsText = this.formatIgnoreJidsForDisplay(value);
    },
    normalizedIgnoreJids() {
      return this.formatIgnoreJidsForDisplay(this.ignoreJidsText)
        .split('\n')
        .filter(Boolean);
    },
    ensurePhoneValid() {
      this.phone = this.normalizedPhone;
      if (!this.phone) {
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PAIR_PHONE_REQUIRED')
        );
        return false;
      }

      if (this.isPhoneValid) {
        return true;
      }

      useAlert(
        this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PAIR_PHONE_ERROR')
      );
      return false;
    },
    buildConfigPayload({ includeApiKey = false } = {}) {
      const payload = {
        evolution_base_url: this.evolutionBaseUrl.trim(),
        evolution_base_path: this.evolutionBasePath.trim(),
        phone: this.normalizedPhone,
        instance_name: this.selectedInstanceName(),
        sign_msg: this.signMsg,
        sign_delimiter: this.signDelimiter,
        msg_call: this.rejectCall ? this.msgCall.trim() : '',
        reopen_conversation: this.reopenConversation,
        conversation_pending: this.conversationPending,
        import_contacts: this.importContacts,
        import_messages: this.importMessages,
        ignore_jids: this.normalizedIgnoreJids(),
        reject_call: this.rejectCall,
        ignore_groups: this.ignoreGroups,
        always_online: this.alwaysOnline,
        read_messages: this.readMessages,
        read_status: this.readStatus,
        sync_full_history: this.syncFullHistory,
        days_limit_import_messages: Number(this.daysLimitImportMessages) || 60,
      };

      if (includeApiKey && this.evolutionApiKey.trim()) {
        payload.evolution_api_key = this.evolutionApiKey.trim();
      }

      return payload;
    },
    async loadConfig() {
      this.uiFlags.loading = true;
      try {
        const response = await WhatsappWebChannel.showConfig(this.inboxId());
        this.applyConfig(response.data.config);
        if (this.hasInstanceName) {
          await this.refreshStatus({ silent: true });
        }
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOAD_ERROR')
          )
        );
      } finally {
        this.uiFlags.loading = false;
      }
    },
    async saveConfig({ silent = false } = {}) {
      if (!this.ensurePhoneValid()) {
        return false;
      }

      this.uiFlags.saving = true;
      try {
        const response = await WhatsappWebChannel.updateConfig(
          this.inboxId(),
          this.buildConfigPayload({ includeApiKey: true })
        );
        this.applyConfig(response.data.config);
        if (!silent) {
          useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        }
        return true;
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SAVE_ERROR')
          )
        );
        return false;
      } finally {
        this.uiFlags.saving = false;
      }
    },
    async testConnection() {
      this.uiFlags.testing = true;
      try {
        const isSaved = await this.saveConfig({ silent: true });
        if (!isSaved) {
          return;
        }
        const response = await WhatsappWebChannel.testConnection(
          this.inboxId()
        );
        this.devices = response.data.devices || [];
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.TEST_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.TEST_ERROR')
          )
        );
      } finally {
        this.uiFlags.testing = false;
      }
    },
    async setupConnector() {
      if (!this.ensurePhoneValid()) {
        return;
      }

      this.uiFlags.settingUp = true;
      try {
        const response = await WhatsappWebChannel.setup(
          this.inboxId(),
          this.buildConfigPayload({ includeApiKey: true })
        );
        this.applyConfig(response.data.config);
        this.applyStatusPayload(response.data.setup?.status || null);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SETUP_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SETUP_ERROR')
          )
        );
      } finally {
        this.uiFlags.settingUp = false;
      }
    },
    async refreshStatus({ silent = false } = {}) {
      try {
        const response = await WhatsappWebChannel.status(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.applyStatusPayload(response.data.status || null);
      } catch (error) {
        if (!silent) {
          useAlert(
            this.getErrorMessage(
              error,
              this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.STATUS_ERROR')
            )
          );
        }
      }
    },
    async loginQr() {
      this.uiFlags.loggingIn = true;
      try {
        const response = await WhatsappWebChannel.loginQr(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        const loginResult = response.data.login || {};
        this.qrLink = loginResult.qr_link || '';
        this.qrDuration = loginResult.qr_duration || null;
        this.pairCode = '';
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_QR_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_QR_ERROR')
          )
        );
      } finally {
        this.uiFlags.loggingIn = false;
      }
    },
    async loginCode() {
      if (!this.ensurePhoneValid()) {
        return;
      }

      this.uiFlags.loggingIn = true;
      try {
        const response = await WhatsappWebChannel.loginCode(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
          phone: this.normalizedPhone,
        });
        this.pairCode = response.data.login?.pair_code || '';
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_CODE_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_CODE_ERROR')
          )
        );
      } finally {
        this.uiFlags.loggingIn = false;
      }
    },
    async reconnectDevice() {
      try {
        const response = await WhatsappWebChannel.reconnect(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_SUCCESS')
        );
        if (!response.data.status) {
          await this.refreshStatus();
        }
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_ERROR')
          )
        );
      }
    },
    async cancelDevice() {
      this.uiFlags.cancelling = true;
      try {
        const response = await WhatsappWebChannel.cancel(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          response.data?.cancel?.response?.message ||
            this.$t('FILTER.FILTER.CANCEL_BUTTON_LABEL')
        );
        if (!response.data.status) {
          await this.refreshStatus();
        }
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGOUT_ERROR')
          )
        );
      } finally {
        this.uiFlags.cancelling = false;
      }
    },
    async logoutDevice() {
      try {
        const response = await WhatsappWebChannel.logout(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGOUT_SUCCESS')
        );
        if (!response.data.status) {
          await this.refreshStatus();
        }
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGOUT_ERROR')
          )
        );
      }
    },
    async removeDevice() {
      try {
        const response = await WhatsappWebChannel.removeDevice(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          this.$t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.REMOVE_DEVICE_SUCCESS'
          )
        );
        if (!response.data.status) {
          await this.refreshStatus();
        }
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t(
              'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.REMOVE_DEVICE_ERROR'
            )
          )
        );
      }
    },
    async startSync() {
      this.uiFlags.syncing = true;
      try {
        const response = await WhatsappWebChannel.sync(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
          days_limit: Number(this.daysLimitImportMessages) || 60,
          import_messages: this.importMessages,
        });
        this.syncPayload = response.data.sync || null;
        this.applyStatusPayload(response.data.status || this.statusPayload);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_START_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_START_ERROR')
          )
        );
      } finally {
        this.uiFlags.syncing = false;
      }
    },
    async refreshSyncStatus() {
      try {
        const response = await WhatsappWebChannel.syncStatus(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.syncPayload = response.data.sync_status || null;
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_STATUS_ERROR')
          )
        );
      }
    },
  },
};
</script>

<template>
  <div>
    <div v-if="uiFlags.loading" class="text-sm text-n-slate-11">
      {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOADING') }}
    </div>

    <template v-else>
      <SettingsFieldSection
        :label="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.DEVICE_ACTIONS_TITLE')
        "
        class="[&>div]:!items-start"
      >
        <div class="w-full max-w-2xl flex flex-col gap-2">
          <div
            class="flex flex-col xl:flex-row xl:flex-wrap xl:items-end gap-2"
          >
            <div class="w-full xl:max-w-[16rem]">
              <div class="flex w-full items-center gap-1.5">
                <span
                  class="shrink-0 select-none text-sm font-medium text-n-brand before:block before:content-['+']"
                />
                <div
                  class="flex h-10 w-full items-center rounded-lg border border-n-weak bg-n-alpha-2"
                  :class="
                    phoneError
                      ? 'border-n-ruby-8'
                      : 'hover:border-n-slate-6 focus-within:border-n-brand'
                  "
                >
                  <input
                    :value="phone"
                    :disabled="isPhoneLocked"
                    type="text"
                    inputmode="numeric"
                    pattern="[0-9]*"
                    maxlength="11"
                    :placeholder="
                      $t(
                        'INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_PLACEHOLDER'
                      )
                    "
                    class="reset-base no-margin h-full min-w-0 flex-1 border-0 bg-transparent px-2.5 py-2 text-sm text-n-slate-12 shadow-none placeholder:text-n-slate-10 focus:outline-none"
                    :class="{ 'cursor-not-allowed opacity-60': isPhoneLocked }"
                    @input="onPhoneInput"
                  />
                </div>
              </div>
              <p v-if="phoneError" class="mt-1 text-label-small text-n-ruby-9">
                {{ phoneError }}
              </p>
            </div>

            <div class="flex flex-wrap items-center gap-2 xl:justify-start">
              <div
                v-if="formattedPairCode"
                class="inline-flex shrink-0 items-center gap-2 rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2"
              >
                <span class="text-xs text-n-slate-11">
                  {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_LABEL') }}
                </span>
                <span
                  class="font-mono text-base text-n-slate-12 tracking-[0.2em]"
                >
                  {{ formattedPairCode }}
                </span>
              </div>

              <div
                class="inline-flex shrink-0 items-center gap-1 rounded-lg border border-n-weak bg-n-alpha-2 p-1"
              >
                <NextButton
                  ghost
                  slate
                  sm
                  icon="i-lucide-qr-code"
                  :disabled="!canRequestQr"
                  :is-loading="uiFlags.loggingIn"
                  :title="
                    $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_QR_BUTTON')
                  "
                  :aria-label="
                    $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_QR_BUTTON')
                  "
                  @click="loginQr"
                />
                <NextButton
                  ghost
                  slate
                  sm
                  icon="i-lucide-key-round"
                  :disabled="!canRequestPairCode"
                  :is-loading="uiFlags.loggingIn"
                  :title="
                    $t(
                      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_CODE_BUTTON'
                    )
                  "
                  :aria-label="
                    $t(
                      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_CODE_BUTTON'
                    )
                  "
                  @click="loginCode"
                />
                <NextButton
                  ghost
                  slate
                  sm
                  icon="i-lucide-refresh-ccw"
                  :disabled="!canReconnect"
                  :title="
                    $t(
                      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_BUTTON'
                    )
                  "
                  :aria-label="
                    $t(
                      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_BUTTON'
                    )
                  "
                  @click="reconnectDevice"
                />
                <NextButton
                  v-if="canCancel"
                  ghost
                  slate
                  sm
                  icon="i-lucide-x"
                  :disabled="!canCancel"
                  :is-loading="uiFlags.cancelling"
                  :title="$t('FILTER.FILTER.CANCEL_BUTTON_LABEL')"
                  :aria-label="$t('FILTER.FILTER.CANCEL_BUTTON_LABEL')"
                  @click="cancelDevice"
                />
                <NextButton
                  ghost
                  slate
                  sm
                  icon="i-lucide-log-out"
                  :disabled="!canLogout"
                  :title="
                    $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGOUT_BUTTON')
                  "
                  :aria-label="
                    $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGOUT_BUTTON')
                  "
                  @click="logoutDevice"
                />
                <NextButton
                  ghost
                  ruby
                  sm
                  icon="i-lucide-trash-2"
                  :disabled="!canRemoveDevice"
                  :title="
                    $t(
                      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.REMOVE_DEVICE_BUTTON'
                    )
                  "
                  :aria-label="
                    $t(
                      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.REMOVE_DEVICE_BUTTON'
                    )
                  "
                  @click="removeDevice"
                />
              </div>
            </div>
          </div>

          <div
            v-if="qrLink || formattedPairCode"
            class="text-sm text-n-slate-11 text-center"
          >
            <div
              v-if="qrLink"
              class="rounded-lg border border-n-weak p-2 inline-block mx-auto"
            >
              <img
                :src="qrLink"
                alt="WhatsApp Web login QR"
                class="size-64 rounded-md"
              />
            </div>
            <div v-if="qrDuration" class="mt-1">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.QR_DURATION') }}
              {{ qrDuration }}
            </div>
          </div>
        </div>
      </SettingsFieldSection>

      <SettingsFieldSection
        :label="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.GROUPS.CONVERSATIONS.TITLE'
          )
        "
        :help-text="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.GROUPS.CONVERSATIONS.SUBTITLE'
          )
        "
        class="mt-4 [&>div]:!items-start"
      >
        <div class="w-full max-w-2xl grid grid-cols-1 md:grid-cols-2 gap-3">
          <TextInput
            v-model="signDelimiter"
            :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.SIGN_DELIMITER.LABEL')"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SIGN_DELIMITER.PLACEHOLDER')
            "
          />

          <div class="md:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-3">
            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="signMsg" />
              <span>{{
                $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SIGN_MSG.LABEL')
              }}</span>
            </label>

            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="reopenConversation" />
              <span>
                {{
                  $t('INBOX_MGMT.ADD.WHATSAPP_WEB.REOPEN_CONVERSATION.LABEL')
                }}
              </span>
            </label>

            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="conversationPending" />
              <span>
                {{
                  $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONVERSATION_PENDING.LABEL')
                }}
              </span>
            </label>
          </div>
        </div>
      </SettingsFieldSection>

      <SettingsFieldSection
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.GROUPS.SYNC.TITLE')"
        :help-text="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.GROUPS.SYNC.SUBTITLE')
        "
        class="mt-4 [&>div]:!items-start"
      >
        <div class="w-full max-w-2xl grid grid-cols-1 md:grid-cols-2 gap-3">
          <TextInput
            v-model="daysLimitImportMessages"
            type="number"
            min="1"
            :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DAYS_LIMIT.LABEL')"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_WEB.DAYS_LIMIT.PLACEHOLDER')
            "
          />

          <div class="md:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-3">
            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="importContacts" />
              <span>
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.IMPORT_CONTACTS.LABEL') }}
              </span>
            </label>

            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="importMessages" />
              <span>
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.IMPORT_MESSAGES.LABEL') }}
              </span>
            </label>

            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="readMessages" />
              <span>
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.READ_MESSAGES.LABEL') }}
              </span>
            </label>

            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="readStatus" />
              <span>
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.READ_STATUS.LABEL') }}
              </span>
            </label>

            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="syncFullHistory" />
              <span>
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SYNC_FULL_HISTORY.LABEL') }}
              </span>
            </label>
          </div>
        </div>
      </SettingsFieldSection>

      <SettingsFieldSection
        :label="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.GROUPS.FILTERS.TITLE')
        "
        :help-text="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.GROUPS.FILTERS.SUBTITLE')
        "
        class="mt-4 [&>div]:!items-start"
      >
        <div class="w-full max-w-2xl grid grid-cols-1 md:grid-cols-2 gap-3">
          <TextArea
            :model-value="ignoreJidsText"
            auto-height
            :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.IGNORE_JIDS.LABEL')"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_WEB.IGNORE_JIDS.PLACEHOLDER')
            "
            :message="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.IGNORE_JIDS.SUBTITLE')"
            :max-length="5000"
            min-height="6rem"
            max-height="12rem"
            class="md:col-span-2 w-full"
            @update:model-value="onIgnoreJidsInput"
          />

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="alwaysOnline" />
            <span>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.ALWAYS_ONLINE.LABEL') }}
            </span>
          </label>

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="ignoreGroups" />
            <span>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.IGNORE_GROUPS.LABEL') }}
            </span>
          </label>

          <div class="md:col-span-2 flex flex-col gap-3">
            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Checkbox v-model="rejectCall" />
              <span>
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.REJECT_CALL.LABEL') }}
              </span>
            </label>

            <TextInput
              v-if="rejectCall"
              v-model="msgCall"
              :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.MSG_CALL.LABEL')"
              :placeholder="
                $t('INBOX_MGMT.ADD.WHATSAPP_WEB.MSG_CALL.PLACEHOLDER')
              "
              :message="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.MSG_CALL.SUBTITLE')"
            />
          </div>
        </div>

        <template #extra>
          <div class="grid grid-cols-1 lg:grid-cols-8">
            <div class="col-span-1 lg:col-span-2 invisible" />
            <div
              class="col-span-1 lg:col-span-6 mt-4 flex flex-wrap gap-2 justify-self-start lg:justify-self-end"
            >
              <NextButton
                :is-loading="uiFlags.saving"
                :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                @click="saveConfig"
              />
              <NextButton
                variant="outline"
                color="slate"
                :is-loading="uiFlags.testing"
                :label="
                  $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.TEST_BUTTON')
                "
                @click="testConnection"
              />
              <NextButton
                variant="outline"
                :is-loading="uiFlags.settingUp"
                :label="
                  $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SETUP_BUTTON')
                "
                @click="setupConnector"
              />
            </div>
          </div>
        </template>
      </SettingsFieldSection>
    </template>

    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_TITLE')"
      class="mt-4 [&>div]:!items-start"
    >
      <div class="w-full max-w-2xl flex flex-col gap-3">
        <div class="flex gap-2 flex-wrap">
          <NextButton
            :disabled="!hasInstanceName"
            :is-loading="uiFlags.syncing"
            :label="
              $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_START_BUTTON')
            "
            @click="startSync"
          />
          <NextButton
            variant="outline"
            :disabled="!hasInstanceName"
            :label="
              $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_STATUS_BUTTON')
            "
            @click="refreshSyncStatus"
          />
        </div>
      </div>
    </SettingsFieldSection>
  </div>
</template>
