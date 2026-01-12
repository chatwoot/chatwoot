<script>
import { mapGetters } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';
import CustomButton from 'shared/components/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import { getContrastingTextColor } from '@chatwoot/utils';
import { LocalStorage } from 'shared/helpers/localStorage';

const SMS_STORAGE_KEY = 'chatwoot_sms_state';

export default {
  name: 'TermsAndConditions',
  components: {
    CustomButton,
    Spinner,
  },
  mixins: [routerMixin, configMixin],
  data() {
    return {
      isSending: false,
      isSuccess: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    dealerName() {
      return this.channelConfig.dealerName || 'Us';
    },
    phoneNumber() {
      return this.$route.query.phoneNumber || '';
    },
    message() {
      return this.$route.query.message || '';
    },
  },
  watch: {
    // If success view toggles after send, re-assert full height
    isSuccess(newVal) {
      if (
        newVal &&
        this.$root &&
        typeof this.$root.setIframeHeight === 'function'
      ) {
        this.$root.setIframeHeight(false);
      }
    },
  },
  mounted() {
    // Check if we should show success message on mount (e.g., after page refresh)
    const storedSmsState = LocalStorage.get('chatwoot_sms_state');
    if (storedSmsState && storedSmsState.sent) {
      // Check if state is not too old (within 24 hours)
      const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
      if (storedSmsState.timestamp && storedSmsState.timestamp >= oneDayAgo) {
        this.isSuccess = true;
      }
    }

    // Also check route query for success flag
    if (this.$route.query.success === 'true') {
      this.isSuccess = true;
    }

    // Ensure iframe takes full height on this page
    // Guards against any prior fixed-height set by unread/campaign views
    if (this.$root && typeof this.$root.setIframeHeight === 'function') {
      this.$root.setIframeHeight(false);
    }
  },
  methods: {
    async handleAgree() {
      if (this.isSending) {
        return;
      }

      this.isSending = true;

      try {
        const { websiteToken } = window.chatwootWebChannel;
        const baseUrl =
          window.$chatwoot?.baseUrl || window.$chatwoot?.baseDomain || '';

        const response = await fetch(`${baseUrl}/api/v1/widget/sms/send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            website_token: websiteToken,
            phone_number: this.phoneNumber,
            message: this.message,
          }),
        });

        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || this.$t('SMS_TERMS.ERROR_SEND_FAILED'));
        }

        // On success, show success message and update localStorage
        this.isSuccess = true;
        this.isSending = false;

        // Update localStorage to mark SMS as sent
        const smsState = {
          phoneNumber: this.phoneNumber,
          message: this.message,
          sent: true,
          timestamp: Date.now(),
        };
        LocalStorage.set(SMS_STORAGE_KEY, smsState);
      } catch (error) {
        // Keep button in "Sending..." state on error
        // Error is silently handled - user can retry by refreshing
      }
    },
    handleDisagree() {
      // Navigate back to SMS form with the form data preserved
      this.$router.push({
        name: 'sms-form',
        query: {
          phoneNumber: this.phoneNumber,
          message: this.message,
        },
      });
    },
    handleClose() {
      this.replaceRoute('messages');
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 w-full p-4">
    <div
      v-if="isSuccess"
      class="flex flex-col items-center justify-center flex-1 text-center"
    >
      <div class="mb-4">
        <svg
          class="w-16 h-16 mx-auto"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          :style="{ color: widgetColor }"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
      </div>
      <h2 class="text-2xl font-bold mb-2 text-n-slate-12">
        {{ $t('SMS_SUCCESS.TITLE') }}
      </h2>
      <p class="text-base mb-6 leading-relaxed text-n-slate-11">
        {{ $t('SMS_SUCCESS.MESSAGE') }}
      </p>
      <!-- <CustomButton
        class="w-full font-medium"
        :bg-color="widgetColor"
        :text-color="textColor"
        @click="handleClose"
      >
        {{ $t('SMS_SUCCESS.BUTTON_CLOSE') }}
      </CustomButton> -->
    </div>

    <div v-else>
      <div class="mb-4">
        <h2 class="text-2xl font-bold mb-4 text-n-slate-11">
          {{ $t('SMS_TERMS.TITLE') }}
        </h2>
        <p class="text-sm mb-6 leading-relaxed text-n-slate-11">
          {{ $t('SMS_TERMS.AGREEMENT_TEXT') }}
          <span class="font-semibold text-n-slate-11">{{ dealerName }}</span>
          {{ $t('SMS_TERMS.AGREEMENT_CONTINUED') }}
          <a
            href="https://staging.getcruisecontrol.com/terms-and-conditions"
            target="_blank"
            rel="noopener noreferrer"
            class="underline text-n-brand"
          >
            {{ $t('SMS_TERMS.TERMS_LINK') }}
          </a>
          {{ ' ' }}{{ $t('SMS_TERMS.PERIOD') || '.' }}
        </p>
      </div>

      <div class="flex flex-col gap-3">
        <CustomButton
          class="w-full font-medium"
          :bg-color="widgetColor"
          :text-color="textColor"
          :disabled="isSending"
          @click="handleAgree"
        >
          <template v-if="isSending">
            <Spinner class="p-0" />
            <span>{{ $t('SMS_TERMS.BUTTON_SENDING') }}</span>
          </template>
          <span v-else>{{ $t('SMS_TERMS.BUTTON_AGREE') }}</span>
        </CustomButton>
        <button
          class="text-n-slate-12 text-center py-2 hover:underline"
          @click="handleDisagree"
        >
          {{ $t('SMS_TERMS.BUTTON_DISAGREE') }}
        </button>
      </div>
    </div>
  </div>
</template>
