<script>
import { useAlert } from 'dashboard/composables';
import EvolutionAPI from 'dashboard/api/evolution';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';

export default {
  components: {
    SettingsSection,
    NextButton,
    Spinner,
    ConfirmationModal,
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
      isConnecting: false,
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
      skipAutoQrFetch: false,
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
    evolutionChannel() {
      return this.inbox.additional_attributes?.evolution_channel;
    },
    evolutionInstanceName() {
      return this.inbox.additional_attributes?.evolution_instance_name;
    },
    isBaileys() {
      return this.evolutionChannel === 'baileys';
    },
    isConnected() {
      return this.connectionState?.instance?.state === 'open';
    },
    connectionStatus() {
      // If QR code is displayed, show as connecting
      if (this.qrCode?.base64 && !this.isConnected) return 'connecting';
      if (!this.connectionState?.instance) return 'unknown';
      return this.connectionState.instance.state || 'disconnected';
    },
    needsIntegrationActivation() {
      return this.isBaileys && this.isConnected && !this.integrationEnabled;
    },
  },
  mounted() {
    this.fetchSettings();
    if (this.isBaileys && !this.isConnected) {
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
        const [
          settingsResponse,
          connectionResponse,
          instanceSettingsResponse,
        ] = await Promise.all([
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
      if (!this.isBaileys) return;

      this.isConnecting = true;
      this.qrCode = { base64: null };
      this.hasShownConnectedAlert = false;

      try {
        const response = await EvolutionAPI.getQRCode(this.inbox.id);
        this.qrCode = response.data;
        // Start polling to detect when QR code is scanned
        this.startPolling();
      } catch (error) {
        console.error('Failed to fetch QR code:', error);
        this.qrCode = null;
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.QR_ERROR')
        );
      } finally {
        this.isConnecting = false;
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
          this.skipAutoQrFetch = false;

          if (!wasConnected && !this.hasShownConnectedAlert) {
            this.hasShownConnectedAlert = true;

            if (this.isBaileys && !this.integrationEnabled) {
              await this.enableIntegration();
            } else {
              useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTED'));
            }
          }
        } else if (
          this.isBaileys &&
          !this.qrCode?.base64 &&
          !this.isConnecting &&
          !this.skipAutoQrFetch
        ) {
          await this.connectInstance();
        }
      } catch (error) {
        console.error('Failed to refresh connection state:', error);
      }
    },
    async enableIntegration() {
      if (!this.isBaileys || !this.isConnected) return;

      this.isEnablingIntegration = true;
      try {
        await EvolutionAPI.enableIntegration(this.inbox.id);
        this.integrationEnabled = true;
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_ENABLED'));
      } catch (error) {
        console.error('Failed to enable integration:', error);
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_ENABLE_ERROR')
        );
      } finally {
        this.isEnablingIntegration = false;
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
    async restartInstance() {
      this.isRestarting = true;
      try {
        await EvolutionAPI.restartInstance(this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.RESTART_SUCCESS'));

        this.skipAutoQrFetch = true;

        await new Promise(resolve => setTimeout(resolve, 2000));

        const response = await EvolutionAPI.getConnectionState(this.inbox.id);
        this.connectionState = response.data;

        setTimeout(() => {
          this.skipAutoQrFetch = false;
        }, 30000);
      } catch (error) {
        this.skipAutoQrFetch = false;
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.RESTART_ERROR')
        );
      } finally {
        this.isRestarting = false;
      }
    },
    async openDisconnectDialog() {
      try {
        const confirmed =
          await this.$refs.disconnectConfirmDialog.showConfirmation();
        if (confirmed) {
          await this.confirmDisconnect();
        }
      } catch (error) {
        console.error('Error in disconnect dialog:', error);
      }
    },
    async confirmDisconnect() {
      this.isDisconnecting = true;
      try {
        await EvolutionAPI.logoutInstance(this.inbox.id);
        this.hasShownConnectedAlert = false;
        this.qrCode = null;
        this.integrationEnabled = false;
        useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_SUCCESS'));

        // Refresh connection state
        const response = await EvolutionAPI.getConnectionState(this.inbox.id);
        this.connectionState = response.data;

        // Start polling for reconnection
        this.startPolling();
      } catch (error) {
        console.error('Error disconnecting instance:', error);
        const errorMsg =
          error.response?.data?.error ||
          error.message ||
          this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_ERROR');
        useAlert(errorMsg);
      } finally {
        this.isDisconnecting = false;
      }
    },
    async refreshInstance() {
      this.isRefreshing = true;
      try {
        const response = await EvolutionAPI.getConnectionState(this.inbox.id);
        this.connectionState = response.data;

        // If now connected and wasn't before, show success
        if (this.isConnected && !this.hasShownConnectedAlert) {
          this.hasShownConnectedAlert = true;
          this.qrCode = null;
          useAlert(this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTED'));
        }
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.EVOLUTION.SETTINGS.REFRESH_ERROR')
        );
      } finally {
        this.isRefreshing = false;
      }
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <Spinner v-if="isLoading" />

    <template v-else>
      <!-- Connection Status -->
      <SettingsSection
        :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.TITLE')"
        :sub-title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECTION.DESCRIPTION')"
        :show-border="true"
      >
        <div class="flex flex-col gap-4">
          <div class="flex items-center gap-3">
            <span
              class="inline-block w-3 h-3 rounded-full"
              :class="{
                'bg-green-500': isConnected,
                'bg-yellow-500': connectionStatus === 'connecting',
                'bg-red-500':
                  connectionStatus === 'close' ||
                  connectionStatus === 'disconnected' ||
                  connectionStatus === 'unknown',
              }"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{
                $t(
                  `INBOX_MGMT.EVOLUTION.SETTINGS.STATUS.${connectionStatus.toUpperCase()}`
                )
              }}
            </span>
          </div>

          <div class="text-sm text-n-slate-11">
            <p>
              <strong
                >{{
                  $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE_NAME')
                }}:</strong
              >
              {{ evolutionInstanceName }}
            </p>
            <p>
              <strong
                >{{
                  $t('INBOX_MGMT.EVOLUTION.SETTINGS.CHANNEL_TYPE')
                }}:</strong
              >
              {{ isBaileys ? 'Baileys' : 'WhatsApp Cloud API' }}
            </p>
            <p>
              <strong
                >{{
                  $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_STATUS')
                }}:</strong
              >
              {{ ' ' }}
              <span
                :class="
                  integrationEnabled ? 'text-green-600' : 'text-red-600'
                "
              >
                {{
                  integrationEnabled
                    ? $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_ACTIVE')
                    : $t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_INACTIVE')
                }}
              </span>
            </p>
          </div>

          <!-- Warning: Integration not enabled but connected -->
          <div
            v-if="needsIntegrationActivation"
            class="mt-4 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg"
          >
            <div class="flex items-start gap-3">
              <svg
                class="w-5 h-5 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-0.5"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                  clip-rule="evenodd"
                />
              </svg>
              <div class="flex-1">
                <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                  {{
                    $t(
                      'INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_NOT_ENABLED_TITLE'
                    )
                  }}
                </h4>
                <p class="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
                  {{
                    $t(
                      'INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION_NOT_ENABLED_DESC'
                    )
                  }}
                </p>
                <NextButton
                  class="mt-3"
                  solid
                  blue
                  :label="
                    $t('INBOX_MGMT.EVOLUTION.SETTINGS.ENABLE_INTEGRATION_BUTTON')
                  "
                  :is-loading="isEnablingIntegration"
                  @click="enableIntegration"
                />
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex gap-2 mt-4">
            <button
              type="button"
              class="p-2 rounded-md hover:bg-n-slate-3 transition-colors"
              :disabled="isRefreshing"
              :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.REFRESH_BUTTON')"
              @click="refreshInstance"
            >
              <svg
                v-if="!isRefreshing"
                class="w-5 h-5 text-n-slate-11"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                />
              </svg>
              <Spinner v-else class="w-5 h-5" />
            </button>
            <NextButton
              ghost
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.RESTART_BUTTON')"
              :is-loading="isRestarting"
              @click="restartInstance"
            />
            <NextButton
              v-if="isConnected && isBaileys"
              ruby
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_BUTTON')"
              :is-loading="isDisconnecting"
              @click="openDisconnectDialog"
            />
          </div>

          <!-- QR Code for Baileys -->
          <div v-if="isBaileys && !isConnected" class="mt-4">
            <NextButton
              :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CONNECT_BUTTON')"
              :is-loading="isConnecting"
              solid
              blue
              @click="connectInstance"
            />

            <!-- QR Code Display -->
            <div
              v-if="qrCode"
              class="mt-4 p-4 bg-white dark:bg-n-slate-2 rounded-lg"
            >
              <div v-if="qrCode.base64" class="flex flex-col items-center">
                <img :src="qrCode.base64" alt="QR Code" class="w-64 h-64" />
                <p class="mt-3 text-sm text-center text-n-slate-11">
                  {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.QR_INSTRUCTION') }}
                </p>
                <NextButton
                  class="mt-4"
                  ghost
                  :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.GET_NEW_QR')"
                  @click="connectInstance"
                />
              </div>
              <div v-else class="flex flex-col items-center py-8">
                <Spinner />
                <p class="mt-3 text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.QR_LOADING') }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </SettingsSection>

      <!-- Instance Settings (Baileys only) -->
      <SettingsSection
        v-if="isBaileys"
        :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.TITLE')"
        :sub-title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.DESCRIPTION')"
        :show-border="true"
      >
        <div class="flex flex-col gap-4">
          <label class="flex items-center gap-2">
            <input v-model="rejectCall" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.REJECT_CALL')
            }}</span>
          </label>
          <p class="text-xs text-n-slate-11 -mt-2 ml-6">
            {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.REJECT_CALL_DESC') }}
          </p>

          <label class="flex items-center gap-2">
            <input v-model="groupsIgnore" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.GROUPS_IGNORE')
            }}</span>
          </label>
          <p class="text-xs text-n-slate-11 -mt-2 ml-6">
            {{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.GROUPS_IGNORE_DESC')
            }}
          </p>

          <label class="flex items-center gap-2">
            <input v-model="alwaysOnline" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.ALWAYS_ONLINE')
            }}</span>
          </label>
          <p class="text-xs text-n-slate-11 -mt-2 ml-6">
            {{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.ALWAYS_ONLINE_DESC')
            }}
          </p>

          <label class="flex items-center gap-2">
            <input v-model="readMessages" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.READ_MESSAGES')
            }}</span>
          </label>
          <p class="text-xs text-n-slate-11 -mt-2 ml-6">
            {{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.READ_MESSAGES_DESC')
            }}
          </p>

          <label class="flex items-center gap-2">
            <input v-model="syncFullHistory" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.SYNC_FULL_HISTORY')
            }}</span>
          </label>
          <p class="text-xs text-n-slate-11 -mt-2 ml-6">
            {{
              $t(
                'INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.SYNC_FULL_HISTORY_DESC'
              )
            }}
          </p>

          <label class="flex items-center gap-2">
            <input v-model="readStatus" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.READ_STATUS')
            }}</span>
          </label>
          <p class="text-xs text-n-slate-11 -mt-2 ml-6">
            {{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.INSTANCE.READ_STATUS_DESC') }}
          </p>
        </div>

        <div class="mt-6">
          <NextButton
            :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.SAVE_BUTTON')"
            :is-loading="isSavingInstanceSettings"
            @click="saveInstanceSettings"
          />
        </div>
      </SettingsSection>

      <!-- Integration Settings -->
      <SettingsSection
        :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.TITLE')"
        :sub-title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.INTEGRATION.DESCRIPTION')"
        :show-border="true"
      >
        <div class="flex flex-col gap-4">
          <label class="flex items-center gap-2">
            <input v-model="signMsg" type="checkbox" />
            <span>{{ $t('INBOX_MGMT.EVOLUTION.SETTINGS.SIGN_MSG') }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="reopenConversation" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.REOPEN_CONVERSATION')
            }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="conversationPending" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.CONVERSATION_PENDING')
            }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="mergeBrazilContacts" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.MERGE_BRAZIL_CONTACTS')
            }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="importContacts" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.IMPORT_CONTACTS')
            }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="importMessages" type="checkbox" />
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.IMPORT_MESSAGES')
            }}</span>
          </label>

          <label v-if="importMessages" class="flex flex-col gap-1">
            <span>{{
              $t('INBOX_MGMT.EVOLUTION.SETTINGS.DAYS_LIMIT_IMPORT')
            }}</span>
            <input
              v-model.number="daysLimitImportMessages"
              type="number"
              min="1"
              max="30"
              class="w-24"
            />
          </label>
        </div>

        <div class="mt-6">
          <NextButton
            :label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.SAVE_BUTTON')"
            :is-loading="isSaving"
            @click="saveSettings"
          />
        </div>
      </SettingsSection>
    </template>

    <!-- Disconnect Confirmation Dialog -->
    <ConfirmationModal
      ref="disconnectConfirmDialog"
      :title="$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_CONFIRM_TITLE')"
      :description="
        $t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_CONFIRM_MESSAGE')
      "
      :confirm-label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.DISCONNECT_BUTTON')"
      :cancel-label="$t('INBOX_MGMT.EVOLUTION.SETTINGS.CANCEL_BUTTON')"
      confirm-color="ruby"
    />
  </div>
</template>
