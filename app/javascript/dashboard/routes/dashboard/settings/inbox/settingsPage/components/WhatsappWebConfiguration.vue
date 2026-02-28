<script>
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
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
    Input,
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
      reopenConversation: false,
      conversationPending: false,
      importContacts: true,
      mergeBrazilContacts: false,
      importMessages: true,
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
    phoneError() {
      if (this.phone.trim() && !this.isPhoneValid) {
        return this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PAIR_PHONE_ERROR');
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
    apiKeyPlaceholder() {
      if (!this.config?.evolution_api_key_configured) {
        return '';
      }

      return this.$t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PASSWORD_PLACEHOLDER'
      );
    },
    applyConfig(config) {
      if (!config) return;
      this.config = config;
      this.evolutionBaseUrl = config.evolution_base_url || '';
      this.evolutionBasePath = config.evolution_base_path || '';
      this.phone = normalizeWhatsappWebPhone(config.phone || '');
      this.instanceName = config.instance_name || '';
      this.signMsg = this.boolValue(config.sign_msg, false);
      this.reopenConversation = this.boolValue(
        config.reopen_conversation,
        false
      );
      this.conversationPending = this.boolValue(
        config.conversation_pending,
        false
      );
      this.importContacts = this.boolValue(config.import_contacts, true);
      this.mergeBrazilContacts = this.boolValue(
        config.merge_brazil_contacts,
        false
      );
      this.importMessages = this.boolValue(config.import_messages, true);
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

      useAlert(this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PAIR_PHONE_ERROR'));
      return false;
    },
    buildConfigPayload({ includeApiKey = false } = {}) {
      const payload = {
        evolution_base_url: this.evolutionBaseUrl.trim(),
        evolution_base_path: this.evolutionBasePath.trim(),
        phone: this.normalizedPhone,
        instance_name: this.selectedInstanceName(),
        sign_msg: this.signMsg,
        reopen_conversation: this.reopenConversation,
        conversation_pending: this.conversationPending,
        import_contacts: this.importContacts,
        merge_brazil_contacts: this.mergeBrazilContacts,
        import_messages: this.importMessages,
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
        this.statusPayload = response.data.setup?.status || null;
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
    async refreshStatus() {
      try {
        const response = await WhatsappWebChannel.status(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        this.statusPayload = response.data.status || null;
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.STATUS_ERROR')
          )
        );
      }
    },
    async loginQr() {
      if (!this.ensurePhoneValid()) {
        return;
      }

      this.uiFlags.loggingIn = true;
      try {
        const payload = {
          instance_name: this.selectedInstanceName(),
          phone: this.normalizedPhone,
        };

        const response = await WhatsappWebChannel.loginQr(
          this.inboxId(),
          payload
        );
        const loginResult = response.data.login || {};
        this.qrLink = loginResult.qr_link || '';
        this.qrDuration = loginResult.qr_duration || null;
        this.pairCode = loginResult.pair_code || '';
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
        await WhatsappWebChannel.reconnect(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_SUCCESS')
        );
        await this.refreshStatus();
      } catch (error) {
        useAlert(
          this.getErrorMessage(
            error,
            this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_ERROR')
          )
        );
      }
    },
    async logoutDevice() {
      try {
        await WhatsappWebChannel.logout(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGOUT_SUCCESS')
        );
        await this.refreshStatus();
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
        await WhatsappWebChannel.removeDevice(this.inboxId(), {
          instance_name: this.selectedInstanceName(),
        });
        useAlert(
          this.$t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.REMOVE_DEVICE_SUCCESS'
          )
        );
        await this.refreshStatus();
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
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.CONFIG_TITLE')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.CONFIG_SUBTITLE')"
      class="[&>div]:!items-start"
    >
      <div v-if="uiFlags.loading" class="text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOADING') }}
      </div>

      <div v-else class="w-full max-w-2xl flex flex-col gap-4">
        <Input
          v-model="evolutionBaseUrl"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.EVOLUTION_URL.LABEL')"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.EVOLUTION_URL.PLACEHOLDER')
          "
        />

        <Input
          v-model="evolutionBasePath"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.EVOLUTION_PATH.LABEL')"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.EVOLUTION_PATH.PLACEHOLDER')
          "
        />

        <Input
          v-model="evolutionApiKey"
          type="password"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.EVOLUTION_API_KEY.LABEL')"
          :placeholder="apiKeyPlaceholder()"
        />

        <Input
          v-model="daysLimitImportMessages"
          type="number"
          min="1"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DAYS_LIMIT.LABEL')"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.DAYS_LIMIT.PLACEHOLDER')
          "
        />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 py-1">
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="signMsg" />
            <span>{{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SIGN_MSG.LABEL') }}</span>
          </label>

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="reopenConversation" />
            <span>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.REOPEN_CONVERSATION.LABEL') }}
            </span>
          </label>

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="conversationPending" />
            <span>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONVERSATION_PENDING.LABEL') }}
            </span>
          </label>

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="importContacts" />
            <span>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.IMPORT_CONTACTS.LABEL') }}
            </span>
          </label>

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="mergeBrazilContacts" />
            <span>
              {{
                $t('INBOX_MGMT.ADD.WHATSAPP_WEB.MERGE_BRAZIL_CONTACTS.LABEL')
              }}
            </span>
          </label>

          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="importMessages" />
            <span>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.IMPORT_MESSAGES.LABEL') }}
            </span>
          </label>
        </div>

        <div class="flex flex-wrap gap-2 pt-1">
          <NextButton
            :is-loading="uiFlags.saving"
            :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            @click="saveConfig"
          />
          <NextButton
            variant="outline"
            color="slate"
            :is-loading="uiFlags.testing"
            :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.TEST_BUTTON')"
            @click="testConnection"
          />
          <NextButton
            variant="outline"
            :is-loading="uiFlags.settingUp"
            :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SETUP_BUTTON')"
            @click="setupConnector"
          />
        </div>
      </div>
    </SettingsFieldSection>

    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.WEBHOOK_URL_TITLE')"
      :help-text="
        $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.WEBHOOK_URL_SUBTITLE')
      "
    >
      <woot-code :script="config?.chatwoot_webhook_url || ''" />
    </SettingsFieldSection>

    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.DEVICE_ACTIONS_TITLE')"
      class="[&>div]:!items-start"
    >
      <div class="w-full max-w-2xl flex flex-col gap-3">
        <div class="flex items-center justify-center gap-2 overflow-x-auto pb-1">
          <div
            v-if="formattedPairCode"
            class="inline-flex shrink-0 items-center gap-2 rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2"
          >
            <span class="text-xs text-n-slate-11">
              {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_LABEL') }}
            </span>
            <span class="font-mono text-base text-n-slate-12 tracking-[0.2em]">
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
              :disabled="!hasInstanceName"
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
              :disabled="!hasInstanceName"
              :is-loading="uiFlags.loggingIn"
              :title="
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_CODE_BUTTON')
              "
              :aria-label="
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.LOGIN_CODE_BUTTON')
              "
              @click="loginCode"
            />
            <NextButton
              ghost
              slate
              sm
              icon="i-lucide-refresh-ccw"
              :disabled="!hasInstanceName"
              :title="
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_BUTTON')
              "
              :aria-label="
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.RECONNECT_BUTTON')
              "
              @click="reconnectDevice"
            />
            <NextButton
              ghost
              slate
              sm
              icon="i-lucide-log-out"
              :disabled="!hasInstanceName"
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
              :disabled="!hasInstanceName"
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

        <div class="w-full max-w-md mx-auto">
          <label class="mb-0.5 text-heading-3 text-n-slate-12">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.PAIR_PHONE_LABEL') }}
          </label>
          <div class="mt-1 flex w-full items-center gap-2">
            <span class="shrink-0 select-none text-base font-medium text-n-brand">
              +
            </span>
            <div
              class="flex h-10 w-full items-center rounded-lg bg-n-alpha-black2 outline outline-1 outline-offset-[-1px]"
              :class="
                phoneError
                  ? 'outline-n-ruby-8'
                  : 'outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand'
              "
            >
              <input
                :value="phone"
                type="text"
                inputmode="numeric"
                pattern="[0-9]*"
                maxlength="11"
                :placeholder="
                  $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_PLACEHOLDER')
                "
                class="reset-base no-margin h-full min-w-0 flex-1 border-0 bg-transparent px-3 py-2.5 text-sm text-n-slate-12 shadow-none placeholder:text-n-slate-10 focus:outline-none"
                @input="onPhoneInput"
              />
            </div>
          </div>
          <p v-if="phoneError" class="mt-1 text-label-small text-n-ruby-9">
            {{ phoneError }}
          </p>
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

        <div v-if="statusPayload">
          <woot-code
            :script="JSON.stringify(statusPayload, null, 2)"
            lang="json"
          />
        </div>
      </div>
    </SettingsFieldSection>

    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB.SYNC_TITLE')"
      class="[&>div]:!items-start"
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

        <div v-if="syncPayload">
          <woot-code
            :script="JSON.stringify(syncPayload, null, 2)"
            lang="json"
          />
        </div>
      </div>
    </SettingsFieldSection>
  </div>
</template>
