<script>
import { useAlert } from 'dashboard/composables';
import EvolutionAPI from 'dashboard/api/evolution';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    SettingsSection,
    NextButton,
    Spinner,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
      isSaving: false,
      isRestarting: false,
      isDisconnecting: false,
      isRefreshing: false,
      isEnablingIntegration: false,
      pollTimer: null,
      settings: null,
      connectionState: null,
      qrCode: null,
      integrationEnabled: false,
      hasShownConnectedAlert: false,
      // Instance settings
      isSavingInstanceSettings: false,
      rejectCall: false,
      msgCall: '',
      groupsIgnore: false,
      alwaysOnline: false,
      readMessages: false,
      readStatus: false,
      syncFullHistory: false,
      // Integration settings (Chatwoot)
      signMsg: true,
      reopenConversation: true,
      conversationPending: false,
      mergeBrazilContacts: true,
      importContacts: true,
      importMessages: true,
      daysLimitImportMessages: 3,
    };
  },
  computed: {
    evolutionInstanceName() {
      return this.inbox.additional_attributes?.evolution_instance_name;
    },
    isConnected() {
      return this.connectionState?.instance?.state === 'open';
    },
    connectionStatus() {
      if (!this.connectionState?.instance) return 'unknown';
      return this.connectionState.instance.state || 'disconnected';
    },
    needsIntegrationActivation() {
      return this.isConnected && !this.integrationEnabled;
    },
  },
  mounted() {
    this.fetchSettings();
    if (!this.isConnected) {
      this.startPolling();
    }
  },
  beforeUnmount() {
    this.stopPolling();
  },
  methods: {
    async fetchSettings() {
      this.isLoading = true;
      try {
        const [settingsResponse, connectionResponse, instanceSettingsResponse] =
          await Promise.all([
            EvolutionAPI.getChatwootSettings(this.inbox.id),
            EvolutionAPI.getConnectionState(this.inbox.id),
            EvolutionAPI.getInstanceSettings(this.inbox.id),
          ]);

        this.settings = settingsResponse.data;
        this.connectionState = connectionResponse.data;
        this.integrationEnabled = this.settings?.enabled === true;

        if (this.isConnected) {
          this.hasShownConnectedAlert = true;
        }

        // Populate instance settings
        const instanceSettings = instanceSettingsResponse.data;
        if (instanceSettings) {
          this.rejectCall = instanceSettings.rejectCall ?? false;
          this.msgCall = instanceSettings.msgCall ?? '';
          this.groupsIgnore = instanceSettings.groupsIgnore ?? false;
          this.alwaysOnline = instanceSettings.alwaysOnline ?? false;
          this.readMessages = instanceSettings.readMessages ?? false;
          this.readStatus = instanceSettings.readStatus ?? false;
          this.syncFullHistory = instanceSettings.syncFullHistory ?? false;
        }

        // Populate integration settings
        if (this.settings) {
          this.signMsg = this.settings.signMsg ?? true;
          this.reopenConversation = this.settings.reopenConversation ?? true;
          this.conversationPending = this.settings.conversationPending ?? false;
          this.mergeBrazilContacts = this.settings.mergeBrazilContacts ?? true;
          this.importContacts = this.settings.importContacts ?? true;
          this.importMessages = this.settings.importMessages ?? true;
          this.daysLimitImportMessages =
            this.settings.daysLimitImportMessages ?? 3;
        }
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.FETCH_ERROR')
        );
      } finally {
        this.isLoading = false;
      }
    },
    async saveSettings() {
      this.isSaving = true;
      try {
        await EvolutionAPI.updateChatwootSettings(this.inbox.id, {
          sign_msg: this.signMsg,
          reopen_conversation: this.reopenConversation,
          conversation_pending: this.conversationPending,
          merge_brazil_contacts: this.mergeBrazilContacts,
          import_contacts: this.importContacts,
          import_messages: this.importMessages,
          days_limit_import_messages: this.daysLimitImportMessages,
        });
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.SAVE_SUCCESS'));
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.SAVE_ERROR')
        );
      } finally {
        this.isSaving = false;
      }
    },
    async saveInstanceSettings() {
      this.isSavingInstanceSettings = true;
      try {
        await EvolutionAPI.updateInstanceSettings(this.inbox.id, {
          reject_call: this.rejectCall,
          msg_call: this.msgCall,
          groups_ignore: this.groupsIgnore,
          always_online: this.alwaysOnline,
          read_messages: this.readMessages,
          read_status: this.readStatus,
          sync_full_history: this.syncFullHistory,
        });
        useAlert(
          this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE_SAVE_SUCCESS')
        );
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE_SAVE_ERROR')
        );
      } finally {
        this.isSavingInstanceSettings = false;
      }
    },
    async connectInstance() {
      this.isRefreshing = true;
      this.qrCode = { base64: null };
      this.hasShownConnectedAlert = false;

      try {
        const response = await EvolutionAPI.getQRCode(this.inbox.id);
        this.qrCode = response.data;
      } catch (error) {
        console.error('Failed to fetch QR code:', error);
        this.qrCode = null;
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.QR_ERROR')
        );
      } finally {
        this.isRefreshing = false;
      }
    },
    async refreshConnection() {
      try {
        const response = await EvolutionAPI.getConnectionState(this.inbox.id);
        const wasConnected = this.isConnected;
        this.connectionState = response.data;

        if (this.isConnected) {
          this.qrCode = null;
          this.stopPolling();

          if (!wasConnected && !this.hasShownConnectedAlert) {
            this.hasShownConnectedAlert = true;

            if (!this.integrationEnabled) {
              await this.enableIntegration();
            } else {
              useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTED'));
            }
          }
        } else if (
          !this.qrCode?.base64 &&
          !this.isRefreshing
        ) {
          await this.connectInstance();
        }
      } catch (error) {
        console.error('Failed to refresh connection state:', error);
      }
    },
    async enableIntegration() {
      if (!this.isConnected) return;

      this.isEnablingIntegration = true;
      try {
        await EvolutionAPI.enableIntegration(this.inbox.id);
        this.integrationEnabled = true;
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_ENABLED'));
      } catch (error) {
        console.error('Failed to enable integration:', error);
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.ENABLE_ERROR')
        );
      } finally {
        this.isEnablingIntegration = false;
      }
    },
    async restartInstance() {
      this.isRestarting = true;
      try {
        await EvolutionAPI.restartInstance(this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.RESTART_SUCCESS'));
        setTimeout(() => this.refreshConnection(), 3000);
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.RESTART_ERROR')
        );
      } finally {
        this.isRestarting = false;
      }
    },
    async disconnectInstance() {
      this.isDisconnecting = true;
      try {
        await EvolutionAPI.logoutInstance(this.inbox.id);
        this.connectionState = { instance: { state: 'close' } };
        this.integrationEnabled = false;
        this.hasShownConnectedAlert = false;
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_SUCCESS'));
        this.startPolling();
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_ERROR')
        );
      } finally {
        this.isDisconnecting = false;
      }
    },
    startPolling() {
      if (this.pollTimer) return;
      this.pollTimer = setInterval(() => {
        this.refreshConnection();
      }, 5000);
    },
    stopPolling() {
      if (this.pollTimer) {
        clearInterval(this.pollTimer);
        this.pollTimer = null;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <div v-if="isLoading" class="flex justify-center py-12">
      <Spinner size="large" />
    </div>

    <template v-else>
      <!-- Connection Status Section -->
      <SettingsSection
        :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.TITLE')"
        :sub-title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.DESCRIPTION')"
      >
        <div class="flex flex-col gap-4">
          <!-- Status Indicator -->
          <div class="flex items-center gap-3">
            <div
              class="h-3 w-3 rounded-full"
              :class="{
                'bg-n-teal-9': isConnected,
                'bg-n-amber-9': connectionStatus === 'connecting',
                'bg-n-ruby-9':
                  connectionStatus === 'close' ||
                  connectionStatus === 'disconnected' ||
                  connectionStatus === 'unknown',
              }"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{
                $t(
                  `INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.STATUS.${connectionStatus.toUpperCase()}`
                )
              }}
            </span>
          </div>

          <!-- QR Code Display (when disconnected) -->
          <div
            v-if="!isConnected"
            class="flex flex-col items-center gap-4 rounded-lg border border-n-weak bg-n-alpha-1 p-6"
          >
            <p class="text-center text-sm text-n-slate-11">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.SCAN_INSTRUCTION') }}
            </p>

            <div
              v-if="isRefreshing"
              class="flex h-64 w-64 items-center justify-center"
            >
              <Spinner size="large" />
            </div>

            <div v-else-if="qrCode?.base64" class="rounded-lg bg-white p-2">
              <img :src="qrCode.base64" alt="QR Code" class="h-64 w-64" />
            </div>

            <div
              v-else
              class="flex h-64 w-64 cursor-pointer items-center justify-center rounded-lg border border-dashed border-n-weak text-n-slate-9 hover:border-n-brand hover:text-n-slate-11"
              @click="connectInstance"
            >
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.LOAD_QR') }}
            </div>

            <NextButton
              variant="secondary"
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.REFRESH_QR')"
              :disabled="isRefreshing"
              @click="connectInstance"
            />
          </div>

          <!-- Enable Integration Button (when connected but not enabled) -->
          <div v-if="needsIntegrationActivation" class="flex justify-start">
            <NextButton
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.ENABLE_INTEGRATION')"
              :loading="isEnablingIntegration"
              @click="enableIntegration"
            />
          </div>

          <!-- Action Buttons -->
          <div class="flex gap-3">
            <NextButton
              variant="secondary"
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.RESTART')"
              :loading="isRestarting"
              :disabled="isDisconnecting"
              @click="restartInstance"
            />
            <NextButton
              v-if="isConnected"
              variant="secondary"
              color="ruby"
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.DISCONNECT')"
              :loading="isDisconnecting"
              :disabled="isRestarting"
              @click="disconnectInstance"
            />
          </div>
        </div>
      </SettingsSection>

      <!-- Instance Settings Section -->
      <SettingsSection
        :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.TITLE')"
        :sub-title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.DESCRIPTION')"
      >
        <div class="flex flex-col gap-4">
          <label class="flex items-center gap-3">
            <input v-model="rejectCall" type="checkbox" class="form-checkbox" />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.REJECT_CALL') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="groupsIgnore"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.GROUPS_IGNORE') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="alwaysOnline"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.ALWAYS_ONLINE') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="readMessages"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.READ_MESSAGES') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input v-model="readStatus" type="checkbox" class="form-checkbox" />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.READ_STATUS') }}
            </span>
          </label>

          <NextButton
            :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.SAVE')"
            :loading="isSavingInstanceSettings"
            @click="saveInstanceSettings"
          />
        </div>
      </SettingsSection>

      <!-- Integration Settings Section -->
      <SettingsSection
        :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.TITLE')"
        :sub-title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.DESCRIPTION')"
      >
        <div class="flex flex-col gap-4">
          <label class="flex items-center gap-3">
            <input v-model="signMsg" type="checkbox" class="form-checkbox" />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.SIGN_MSG') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="reopenConversation"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.REOPEN_CONVERSATION') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="mergeBrazilContacts"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.MERGE_BRAZIL_CONTACTS') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="importContacts"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.IMPORT_CONTACTS') }}
            </span>
          </label>

          <label class="flex items-center gap-3">
            <input
              v-model="importMessages"
              type="checkbox"
              class="form-checkbox"
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.IMPORT_MESSAGES') }}
            </span>
          </label>

          <NextButton
            :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.SAVE')"
            :loading="isSaving"
            @click="saveSettings"
          />
        </div>
      </SettingsSection>
    </template>
  </div>
</template>

