<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, minLength } from '@vuelidate/validators';
import router from '../../../../index';
// no phone/token fields in partner flow

import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { DotLottieVue } from '@lottiefiles/dotlottie-vue';

export default {
  name: 'WhapiSettings',
  components: {
    NextButton,
    Spinner,
    DotLottieVue,
  },
  props: {
    disabledAutoRoute: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      step: 'name', // name | qr | success
      inboxName: '',
      createdInbox: null,
      qrImageB64: '',
      qrPollTimer: null,
      qrRetryCount: 0,
      qrMaxRetries: 20, // ~5 minutes at 15s interval
      isLoadingQr: false,
      qrError: null,
      showLottieAnimation: true,
      isLottieComplete: false,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
    currentInbox() {
      if (!this.createdInbox) return {};
      return (
        this.$store.getters['inboxes/getInbox'](this.createdInbox.id) || {}
      );
    },
    connectionStatus() {
      const cfg = this.currentInbox.provider_config || {};
      return cfg.connection_status || 'pending';
    },
    isContinueButtonDisabled() {
      // Button is disabled if validation fails or if creating is in progress
      return this.v$.inboxName.$invalid || this.uiFlags.isCreating;
    },
  },
  validations: {
    inboxName: {
      required,
      minLength: minLength(2), // Minimum 2 characters for a valid name
    },
  },
  watch: {
    connectionStatus(newVal) {
      if (this.step === 'qr' && newVal === 'connected') {
        this.clearQrTimer();
        this.step = 'success';
      }
    },
    step(newVal) {
      this.$emit('step-changed', newVal);
      // Reset animation state when entering success step
      if (newVal === 'success') {
        console.log('Entering success step');
        this.showLottieAnimation = true;
        this.isLottieComplete = false;
        console.log('Animation state reset:', {
          showLottieAnimation: this.showLottieAnimation,
          isLottieComplete: this.isLottieComplete,
        });
        // Start the fallback timer
        this.$nextTick(() => {
          this.startLottieTimer();
        });
      }
    },
  },
  mounted() {
    this.$emit('step-changed', this.step);
  },
  beforeUnmount() {
    this.clearQrTimer();
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) return;
      try {
        const created = await this.$store.dispatch(
          'inboxes/createWhapiChannel',
          {
            name: this.inboxName,
          }
        );
        this.createdInbox = created;
        this.step = 'qr';
        this.fetchQrAndStartPolling();
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
        );
      }
    },
    async fetchQrAndStartPolling() {
      this.isLoadingQr = true;
      this.qrError = null;

      try {
        const response = await this.$store.dispatch(
          'inboxes/getWhapiQrCode',
          this.createdInbox.id
        );

        console.log('QR Code Response:', response);

        // Check if channel is already authenticated
        if (response.authenticated) {
          console.log('Channel already authenticated!');
          this.isLoadingQr = false;
          this.clearQrTimer();
          this.step = 'success';
          return;
        }

        const {
          image_base64: imageBase64,
          poll_in: pollIn,
          expires_in: expiresIn,
        } = response;
        console.log('QR Code Response:', {
          imageBase64: imageBase64?.substring(0, 50) + '...',
          pollIn,
          expiresIn,
        });

        if (imageBase64) {
          this.qrImageB64 = `data:image/png;base64,${imageBase64}`;
          this.isLoadingQr = false;
          console.log('QR Image set: Success');
        } else {
          console.log('QR Image not available yet, will retry');
          this.qrError = 'QR code is being generated, please wait...';
        }

        this.clearQrTimer();
        const intervalMs = (pollIn || Math.max(15, expiresIn || 20)) * 1000;
        this.qrRetryCount += 1;
        if (this.qrRetryCount > this.qrMaxRetries) {
          this.isLoadingQr = false;
          this.qrError = 'QR code generation timed out. Please try again.';
          useAlert(this.$t('INBOX_MGMT.ADD.WHAPI.QR_EXPIRED_OR_RETRY_LIMIT'));
          return;
        }
        this.qrPollTimer = setTimeout(this.fetchQrAndStartPolling, intervalMs);
      } catch (e) {
        // Enhanced error handling with specific messages
        console.error('QR Code fetch error:', e);
        this.isLoadingQr = false;

        this.qrRetryCount += 1;
        if (this.qrRetryCount > this.qrMaxRetries) {
          this.qrError = 'QR code generation failed. Please try again.';
          useAlert(this.$t('INBOX_MGMT.ADD.WHAPI.QR_EXPIRED_OR_RETRY_LIMIT'));
          return;
        }

        // Show specific error message if available
        if (e.message && e.message.includes('already authenticated')) {
          console.log('Channel already authenticated - moving to success!');
          this.clearQrTimer();
          this.step = 'success';
        } else if (e.message && e.message.includes('503')) {
          console.log(
            'Service temporarily unavailable, retrying in 30 seconds...'
          );
          this.qrError = 'Service temporarily unavailable. Retrying...';
          this.qrPollTimer = setTimeout(this.fetchQrAndStartPolling, 30000);
        } else if (
          e.message &&
          e.message.includes('unexpected response format')
        ) {
          console.log('QR code format issue, retrying in 15 seconds...');
          this.qrError = 'QR code is being prepared. Retrying...';
          this.qrPollTimer = setTimeout(this.fetchQrAndStartPolling, 15000);
        } else {
          // Default retry interval
          this.qrError = 'Generating QR code. Please wait...';
          this.qrPollTimer = setTimeout(this.fetchQrAndStartPolling, 20000);
        }
      }
    },
    clearQrTimer() {
      if (this.qrPollTimer) {
        clearTimeout(this.qrPollTimer);
        this.qrPollTimer = null;
      }
    },
    proceedOnSuccess() {
      if (this.disabledAutoRoute) return;
      router.replace({
        name: 'settings_inboxes_add_agents',
        params: { page: 'new', inbox_id: this.createdInbox.id },
      });
    },
    onLottieComplete() {
      console.log('Lottie animation completed');
      // Hide the animation and show the success content
      this.showLottieAnimation = false;
      this.isLottieComplete = true;
    },
    startLottieTimer() {
      // Fallback timer in case @complete event doesn't fire
      // Most Lottie animations are 2-3 seconds, so we'll wait 2.5 seconds
      console.log('Starting Lottie fallback timer');

      // Auto-complete after 2.5 seconds
      setTimeout(() => {
        if (this.showLottieAnimation && !this.isLottieComplete) {
          console.log('Lottie timer completed (fallback)');
          this.onLottieComplete();
        }
      }, 2500);
    },
  },
};
</script>

<template>
  <div class="flex flex-col mx-0">
    <form
      v-if="step === 'name'"
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{
              v$.inboxName.$errors[0].$validator === 'required'
                ? $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR')
                : 'Channel name must be at least 2 characters long'
            }}
          </span>
          <p
            v-if="!v$.inboxName.$error && inboxName.length > 0"
            class="help-text text-green-600"
          >
            ✓ Valid channel name
          </p>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          label="Continue"
          :disabled="isContinueButtonDisabled"
          :class="{ 'opacity-50 cursor-not-allowed': isContinueButtonDisabled }"
        />
      </div>
    </form>

    <div
      v-else-if="step === 'qr'"
      class="flex flex-col items-center justify-center"
    >
      <!-- Loading spinner when QR is being generated -->
      <div v-if="isLoadingQr && !qrImageB64" class="flex flex-col items-center">
        <div class="flex items-center justify-center h-48 w-48">
          <Spinner :size="64" class="text-n-brand" />
        </div>
        <p class="mt-4 text-slate-600">Generating QR code...</p>
      </div>

      <!-- QR Code image when available -->
      <img
        v-else-if="qrImageB64"
        :src="qrImageB64"
        alt="WhatsApp QR Code"
        class="h-48 w-48 border border-gray-300 rounded"
      />

      <!-- Error state when QR failed to load -->
      <div v-else-if="qrError" class="flex flex-col items-center">
        <div
          class="h-48 w-48 border-2 border-dashed border-gray-300 rounded flex items-center justify-center"
        >
          <p class="text-gray-500 text-center px-4">{{ qrError }}</p>
        </div>
      </div>

      <!-- Default loading state -->
      <div v-else class="flex flex-col items-center">
        <div
          class="h-48 w-48 border-2 border-dashed border-gray-300 rounded flex items-center justify-center"
        >
          <p class="text-gray-500">Loading QR code...</p>
        </div>
      </div>

      <p v-if="qrImageB64" class="mt-3 text-slate-600">
        {{ $t('INBOX_MGMT.ADD.WHAPI.QR_HELP_TEXT') }}
      </p>
    </div>

    <div
      v-else-if="step === 'success'"
      class="flex flex-col items-center justify-center"
    >
      <DotLottieVue
        v-if="showLottieAnimation"
        style="height: 200px; width: 200px"
        autoplay
        :loop="false"
        src="https://lottie.host/bc4d2cc8-bf76-47a0-a9f9-63abebc62420/gj5OjtX7ZL.lottie"
        @complete="onLottieComplete"
        @finished="onLottieComplete"
        @end="onLottieComplete"
        @ready="() => console.log('Lottie ready')"
        @load="() => console.log('Lottie loaded')"
      />

      <p
        v-if="isLottieComplete"
        class="mt-3 text-slate-600 text-center font-medium"
      >
        Your WhatsApp channel has been successfully connected!
      </p>
      <div v-if="isLottieComplete" class="w-full mt-4">
        <NextButton
          solid
          green
          :label="$t('INBOX_MGMT.ADD.WHAPI.CONTINUE_BUTTON')"
          @click="proceedOnSuccess"
        />
      </div>
    </div>
  </div>
</template>
