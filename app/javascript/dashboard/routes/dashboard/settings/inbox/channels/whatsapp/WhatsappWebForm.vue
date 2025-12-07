<script>
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

import NextButton from 'dashboard/components-next/button/Button.vue';
import QRCodeModal from 'dashboard/components/QRCodeModal.vue';
import WhatsappWebGatewayApi from 'dashboard/api/whatsappWebGateway';
import WhatsappAdminApi from 'dashboard/api/whatsappAdminApi';

export default {
  name: 'WhatsappWebForm',
  components: {
    NextButton,
    QRCodeModal,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    mode: {
      type: String,
      default: 'create', // 'create' or 'edit'
      validator: value => ['create', 'edit'].includes(value),
    },
  },
  emits: ['submit'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      gatewayBaseUrl: '',
      basicAuthUser: '',
      basicAuthPassword: '',
      webhookSecret: '',
      includeSignature: true,
      showQRModal: false,
      connectionStatus: null,
      isLoadingStatus: false,
      isDisconnecting: false,
      isReconnecting: false,
      connectionMode: 'existing', // 'existing' or 'provision'
      adminApiConfigured: false,
      isCheckingAdminApi: false,
      isProvisioning: false,
    };
  },
  computed: {
    gatewayConfig() {
      return {
        gatewayBaseUrl: this.gatewayBaseUrl,
        phoneNumber: this.phoneNumber,
        basicAuthUser: this.basicAuthUser,
        basicAuthPassword: this.basicAuthPassword,
      };
    },
    canShowQRCode() {
      return this.gatewayBaseUrl && this.gatewayBaseUrl.trim() !== '';
    },
    submitButtonLabel() {
      return this.mode === 'create'
        ? this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.SUBMIT_BUTTON')
        : this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON');
    },
    showInboxNameField() {
      return this.mode === 'create';
    },
    connectionStatusText() {
      if (this.isLoadingStatus) return 'CHECKING';
      if (!this.connectionStatus) return 'UNKNOWN';

      // Parse the status response based on QRCodeModal logic
      if (this.connectionStatus.code === 'SUCCESS') {
        // Check if logged in (similar to QRCodeModal logic)
        if (this.connectionStatus.results?.is_logged_in) {
          return 'CONNECTED';
        }

        // Check status string for more detailed info
        const status = this.connectionStatus.results?.status || '';
        if (status.includes('connected') || status.includes('authenticated')) {
          return 'CONNECTED';
        }
        if (
          status.includes('disconnected') ||
          status.includes('not authenticated')
        ) {
          return 'DISCONNECTED';
        }
        if (status.includes('qr') || status.includes('waiting')) {
          return 'WAITING_QR';
        }

        // Default to disconnected if success but no logged in flag
        return 'DISCONNECTED';
      }
      return 'ERROR';
    },
    connectionStatusColor() {
      switch (this.connectionStatusText) {
        case 'CONNECTED':
          return 'text-green-600 bg-green-50 border-green-200';
        case 'DISCONNECTED':
        case 'ERROR':
          return 'text-red-600 bg-red-50 border-red-200';
        case 'WAITING_QR':
          return 'text-yellow-600 bg-yellow-50 border-yellow-200';
        case 'CHECKING':
          return 'text-blue-600 bg-blue-50 border-blue-200';
        default:
          return 'text-gray-600 bg-gray-50 border-gray-200';
      }
    },
    connectionStatusLabel() {
      const statusKey = this.connectionStatusText;
      const translationKey = `INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_STATUS.${statusKey}`;
      return this.$t(translationKey);
    },
    showConnectButton() {
      return this.connectionStatusText !== 'CONNECTED';
    },
    showDisconnectButton() {
      return this.connectionStatusText === 'CONNECTED';
    },
    showReconnectButton() {
      // Reconnect should be available when connected (to restart connection)
      // or when there are connection issues
      return (
        this.connectionStatusText === 'CONNECTED' ||
        this.connectionStatusText === 'DISCONNECTED' ||
        this.connectionStatusText === 'ERROR'
      );
    },
    showConnectionModeToggle() {
      return this.mode === 'create' && this.adminApiConfigured;
    },
    isProvisioningMode() {
      return this.connectionMode === 'provision';
    },
  },
  validations() {
    const baseValidations = {
      phoneNumber: { required, isPhoneE164OrEmpty },
      webhookSecret: { required },
    };

    // In provisioning mode, we don't need gateway URL and basic auth
    if (!this.isProvisioningMode) {
      baseValidations.gatewayBaseUrl = { required };
      baseValidations.basicAuthUser = {};
      baseValidations.basicAuthPassword = {};
    }

    if (this.mode === 'create') {
      baseValidations.inboxName = { required };
    }

    return baseValidations;
  },
  watch: {
    inbox: {
      immediate: true,
      handler(newInbox) {
        if (newInbox && this.mode === 'edit') {
          this.setDefaults(newInbox);
          this.checkConnectionStatus();
        }
      },
    },
  },
  mounted() {
    if (this.mode === 'create') {
      this.checkAdminApiStatus();
    }
  },
  methods: {
    setDefaults(inbox) {
      if (!inbox) return;

      this.inboxName = inbox.name || '';
      this.phoneNumber = inbox.phone_number || '';

      if (inbox.provider_config) {
        this.gatewayBaseUrl = inbox.provider_config.gateway_base_url || '';
        this.basicAuthUser = inbox.provider_config.basic_auth_user || '';
        this.basicAuthPassword =
          inbox.provider_config.basic_auth_password || '';
        this.webhookSecret = inbox.provider_config.webhook_secret || '';
        this.includeSignature =
          inbox.provider_config.include_signature !== false;
      }
    },

    openQRModal() {
      if (!this.canShowQRCode) {
        useAlert(
          this.$t(
            'INBOX_MGMT.ADD.WHATSAPP_WEB.TEST_CONNECTION.VALIDATION_ERROR'
          )
        );
        return;
      }
      this.showQRModal = true;
    },

    closeQRModal() {
      this.showQRModal = false;
    },

    handleWhatsAppConnected() {
      this.closeQRModal();
      // You could add additional logic here, like auto-filling fields
      // or proceeding to the next step
    },

    async checkAdminApiStatus() {
      this.isCheckingAdminApi = true;
      try {
        const response = await WhatsappAdminApi.checkAdminApiStatus();
        this.adminApiConfigured =
          response.data.configured && response.data.healthy;
      } catch (error) {
        this.adminApiConfigured = false;
      } finally {
        this.isCheckingAdminApi = false;
      }
    },

    async handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      // If provisioning mode, provision the instance first
      if (this.isProvisioningMode) {
        this.isProvisioning = true;
        try {
          const provisionResponse = await WhatsappAdminApi.provisionInstance(
            this.phoneNumber,
            this.webhookSecret
          );

          const { gateway_base_url, basic_auth_user, basic_auth_password } =
            provisionResponse.data;

          // Use the provisioned credentials
          this.gatewayBaseUrl = gateway_base_url;
          this.basicAuthUser = basic_auth_user;
          this.basicAuthPassword = basic_auth_password;

          useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PROVISIONING.SUCCESS'));
        } catch (error) {
          this.isProvisioning = false;
          const errorMessage = error.response?.data?.error || error.message;

          if (errorMessage.includes('No available ports')) {
            useAlert(
              this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PROVISIONING.NO_PORTS')
            );
          } else {
            useAlert(
              errorMessage ||
                this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PROVISIONING.ERROR')
            );
          }
          return;
        } finally {
          this.isProvisioning = false;
        }
      }

      // Build provider_config, omitting optional Basic Auth if left blank
      const providerConfig = {
        gateway_base_url: this.gatewayBaseUrl,
        webhook_secret: this.webhookSecret,
        include_signature: this.includeSignature,
      };

      if (this.basicAuthUser && this.basicAuthPassword) {
        providerConfig.basic_auth_user = this.basicAuthUser;
        providerConfig.basic_auth_password = this.basicAuthPassword;
      }

      const formData = {
        name: this.inboxName,
        phone_number: this.phoneNumber,
        provider_config: providerConfig,
      };

      this.$emit('submit', formData);
    },

    async checkConnectionStatus() {
      if (this.mode !== 'edit' || !this.inbox?.id) return;

      this.isLoadingStatus = true;
      try {
        const response = await WhatsappWebGatewayApi.getStatus(this.inbox.id);
        this.connectionStatus = response.data.data;
      } catch (error) {
        // Connection status check failed
        this.connectionStatus = { code: 'ERROR', error: error.message };
      } finally {
        this.isLoadingStatus = false;
      }
    },

    async refreshConnectionStatus() {
      await this.checkConnectionStatus();
    },

    async disconnectWhatsApp() {
      if (!this.inbox?.id) return;

      // Show confirmation dialog
      const confirmed = window.confirm(
        this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DISCONNECT.CONFIRMATION')
      );

      if (!confirmed) return;

      this.isDisconnecting = true;
      try {
        await WhatsappWebGatewayApi.logout(this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DISCONNECT.SUCCESS'));
        // Refresh status after successful disconnect
        await this.checkConnectionStatus();
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DISCONNECT.ERROR')
        );
      } finally {
        this.isDisconnecting = false;
      }
    },

    async reconnectWhatsApp() {
      if (!this.inbox?.id) return;

      this.isReconnecting = true;
      try {
        await WhatsappWebGatewayApi.reconnect(this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.RECONNECT.SUCCESS'));
        // Refresh status after successful reconnect
        await this.checkConnectionStatus();
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.RECONNECT.ERROR')
        );
      } finally {
        this.isReconnecting = false;
      }
    },
  },
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="handleSubmit()">
    <!-- Connection Mode Toggle -->
    <div
      v-if="showConnectionModeToggle"
      class="flex-shrink-0 flex-grow-0 mb-4 p-4 border border-slate-200 dark:border-slate-700 rounded-lg"
    >
      <label
        class="block text-sm font-medium text-slate-900 dark:text-slate-100 mb-3"
      >
        {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_MODE.LABEL') }}
      </label>
      <div class="grid grid-cols-1 gap-3">
        <label
          class="flex items-start p-3 border rounded-lg cursor-pointer transition-colors"
          :class="
            connectionMode === 'existing'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-slate-200 dark:border-slate-700 hover:border-slate-300'
          "
        >
          <input
            v-model="connectionMode"
            type="radio"
            value="existing"
            class="mt-1 mr-3"
          />
          <div>
            <div class="font-medium text-slate-900 dark:text-slate-100">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_MODE.EXISTING') }}
            </div>
            <div class="text-xs text-slate-600 dark:text-slate-400 mt-1">
              {{
                $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_MODE.EXISTING_DESC')
              }}
            </div>
          </div>
        </label>
        <label
          class="flex items-start p-3 border rounded-lg cursor-pointer transition-colors"
          :class="
            connectionMode === 'provision'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-slate-200 dark:border-slate-700 hover:border-slate-300'
          "
        >
          <input
            v-model="connectionMode"
            type="radio"
            value="provision"
            class="mt-1 mr-3"
          />
          <div>
            <div class="font-medium text-slate-900 dark:text-slate-100">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_MODE.PROVISION') }}
            </div>
            <div class="text-xs text-slate-600 dark:text-slate-400 mt-1">
              {{
                $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_MODE.PROVISION_DESC')
              }}
            </div>
          </div>
        </label>
      </div>
    </div>

    <div v-if="showInboxNameField" class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INBOX_NAME.LABEL') }}
        <input
          v-model="inboxName"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INBOX_NAME.PLACEHOLDER')
          "
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.LABEL') }}
        <input
          v-model="phoneNumber"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.PLACEHOLDER')
          "
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <!-- Only show gateway fields in existing mode -->
    <div v-if="!isProvisioningMode" class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.gatewayBaseUrl.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.GATEWAY_BASE_URL.LABEL') }}
          <span class="text-xs text-slate-11 ml-1">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.GATEWAY_BASE_URL.TOOLTIP') }}
          </span>
        </span>
        <input
          v-model="gatewayBaseUrl"
          type="url"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.GATEWAY_BASE_URL.PLACEHOLDER')
          "
          @blur="v$.gatewayBaseUrl.$touch"
        />
        <span v-if="v$.gatewayBaseUrl.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.GATEWAY_BASE_URL.ERROR') }}
        </span>
      </label>
    </div>

    <div v-if="!isProvisioningMode" class="grid grid-cols-2 gap-4">
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.basicAuthUser.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.BASIC_AUTH_USER.LABEL') }}
          <input
            v-model="basicAuthUser"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_WEB.BASIC_AUTH_USER.PLACEHOLDER')
            "
            @blur="v$.basicAuthUser.$touch"
          />
          <span v-if="v$.basicAuthUser.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.BASIC_AUTH_USER.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.basicAuthPassword.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.BASIC_AUTH_PASSWORD.LABEL') }}
          <input
            v-model="basicAuthPassword"
            type="password"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_WEB.BASIC_AUTH_PASSWORD.PLACEHOLDER')
            "
            @blur="v$.basicAuthPassword.$touch"
          />
          <span v-if="v$.basicAuthPassword.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.BASIC_AUTH_PASSWORD.ERROR') }}
          </span>
        </label>
      </div>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.webhookSecret.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.WEBHOOK_SECRET.LABEL') }}
          <span class="text-xs text-slate-11 ml-1">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.WEBHOOK_SECRET.TOOLTIP') }}
          </span>
        </span>
        <input
          v-model="webhookSecret"
          type="password"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_WEB.WEBHOOK_SECRET.PLACEHOLDER')
          "
          @blur="v$.webhookSecret.$touch"
        />
        <span v-if="v$.webhookSecret.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.WEBHOOK_SECRET.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label class="flex items-center">
        <input v-model="includeSignature" type="checkbox" class="mr-2" />
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INCLUDE_SIGNATURE.LABEL') }}
        </span>
      </label>
      <p class="text-xs text-slate-11 mt-1">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INCLUDE_SIGNATURE.HELP_TEXT') }}
      </p>
    </div>

    <!-- Connection Status (only in edit mode) -->
    <div v-if="mode === 'edit'" class="flex-shrink-0 flex-grow-0 my-4">
      <div class="flex items-center justify-between mb-2">
        <span class="text-sm font-medium text-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_STATUS.LABEL') }}
        </span>
        <button
          type="button"
          :disabled="isLoadingStatus"
          class="text-sm text-blue-600 hover:text-blue-800 disabled:text-gray-400"
          @click="refreshConnectionStatus"
        >
          {{
            isLoadingStatus
              ? $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_STATUS.REFRESHING')
              : $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION_STATUS.REFRESH')
          }}
        </button>
      </div>
      <div
        class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border"
        :class="connectionStatusColor"
      >
        <span
          v-if="isLoadingStatus"
          class="inline-block w-3 h-3 mr-2 border-2 border-current border-t-transparent rounded-full animate-spin"
        />
        <span v-else class="w-2 h-2 mr-2 rounded-full bg-current" />
        {{ connectionStatusLabel }}
      </div>
    </div>

    <div class="flex gap-2 mt-4">
      <!-- Connect Button (QR Code) -->
      <NextButton
        v-if="mode === 'edit' && showConnectButton"
        type="button"
        color="green"
        variant="outline"
        size="md"
        icon="i-lucide-qr-code"
        :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.TITLE')"
        :disabled="!canShowQRCode"
        @click="openQRModal"
      />

      <!-- Disconnect Button -->
      <NextButton
        v-if="mode === 'edit' && showDisconnectButton"
        type="button"
        color="red"
        variant="outline"
        size="md"
        icon="i-lucide-log-out"
        :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DISCONNECT.TITLE')"
        :is-loading="isDisconnecting"
        @click="disconnectWhatsApp"
      />

      <!-- Reconnect Button -->
      <NextButton
        v-if="mode === 'edit' && showReconnectButton"
        type="button"
        color="orange"
        variant="outline"
        size="md"
        icon="i-lucide-refresh-cw"
        :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.RECONNECT.TITLE')"
        :is-loading="isReconnecting"
        @click="reconnectWhatsApp"
      />

      <!-- Submit Button -->
      <NextButton
        :is-loading="isLoading || isProvisioning"
        type="submit"
        variant="solid"
        color="blue"
        size="md"
        :label="
          isProvisioning
            ? $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PROVISIONING.IN_PROGRESS')
            : submitButtonLabel
        "
      />
    </div>

    <!-- QR Code Modal -->
    <QRCodeModal
      :show="showQRModal"
      :gateway-config="gatewayConfig"
      :inbox-id="inbox?.id"
      @close="closeQRModal"
      @connected="handleWhatsAppConnected"
    />
  </form>
</template>
