<script>
import { mapGetters } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';
import CustomButton from 'shared/components/Button.vue';
import PhoneInput from 'widget/components/Form/PhoneInput.vue';
import { createInput, FormKit } from '@formkit/vue';
import { getContrastingTextColor } from '@chatwoot/utils';
import { LocalStorage } from 'shared/helpers/localStorage';
import { trackEvent } from 'widget/helpers/analyticsHelper';

const SMS_STORAGE_KEY = 'chatwoot_sms_state';

export default {
  name: 'SmsForm',
  components: {
    CustomButton,
    FormKit,
  },
  mixins: [routerMixin, configMixin],
  setup() {
    const phoneInput = createInput(PhoneInput);
    return { phoneInput };
  },
  data() {
    return {
      phoneNumber: '',
      message: '',
      hasTrackedInteraction: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    isValid() {
      return (
        this.phoneNumber.trim().length > 0 && this.message.trim().length > 0
      );
    },
  },
  watch: {
    $route(to) {
      // Restore form data when route changes (e.g., coming back from Terms page)
      if (to.name === 'sms-form') {
        this.$nextTick(() => {
          if (to.query.phoneNumber) {
            this.phoneNumber = to.query.phoneNumber;
          }
          if (to.query.message) {
            this.message = to.query.message;
          }
        });
      }
    },
    phoneNumber() {
      this.trackInteraction();
      this.trackInput();
    },
    message() {
      this.trackInteraction();
      this.trackInput();
    },
  },
  mounted() {
    // Restore form data from query params or localStorage
    this.$nextTick(() => {
      // First check query params (for navigation from Terms page)
      if (this.$route.query.phoneNumber) {
        this.phoneNumber = this.$route.query.phoneNumber;
      }
      if (this.$route.query.message) {
        this.message = this.$route.query.message;
      }

      // If no query params, check localStorage
      if (!this.$route.query.phoneNumber && !this.$route.query.message) {
        const storedSmsState = LocalStorage.get(SMS_STORAGE_KEY);
        if (storedSmsState && !storedSmsState.sent) {
          // Only restore if SMS wasn't sent yet
          if (storedSmsState.phoneNumber) {
            this.phoneNumber = storedSmsState.phoneNumber;
          }
          if (storedSmsState.message) {
            this.message = storedSmsState.message;
          }
        }
      }
    });
  },
  methods: {
    handleSubmit() {
      if (!this.isValid) {
        return;
      }

      // Store form data in localStorage before navigating
      const smsState = {
        phoneNumber: this.phoneNumber.trim(),
        message: this.message.trim(),
        sent: false,
        timestamp: Date.now(),
      };
      LocalStorage.set(SMS_STORAGE_KEY, smsState);

      // Navigate to terms and conditions page with form data as query params
      this.$router.push({
        name: 'terms-and-conditions',
        query: {
          phoneNumber: this.phoneNumber.trim(),
          message: this.message.trim(),
        },
      });
    },
    handleCancel() {
      // Clear stored SMS state when canceling
      LocalStorage.remove(SMS_STORAGE_KEY);
      this.replaceRoute('home');
    },
    trackInteraction() {
      if (!this.hasTrackedInteraction && (this.phoneNumber || this.message)) {
        trackEvent('phone_number_form_interaction');
        this.hasTrackedInteraction = true;
      }
    },
    trackInput() {
      if (this.inputTimeout) {
        clearTimeout(this.inputTimeout);
      }
      this.inputTimeout = setTimeout(() => {
        if (this.phoneNumber || this.message) {
          trackEvent('phone_number_form_input');
        }
      }, 500);
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 w-full p-4">
    <!-- SMS Form -->
    <div class="mb-4">
      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ $t('SMS_FORM.TITLE') }}
      </h2>
      <p class="mt-1 text-sm text-n-slate-11">
        {{ $t('SMS_FORM.DESCRIPTION') }}
      </p>
    </div>

    <div class="flex flex-col gap-4">
      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ $t('SMS_FORM.PHONE_NUMBER.LABEL') }}
        </label>
        <FormKit
          v-model="phoneNumber"
          :type="phoneInput"
          name="phoneNumber"
          :placeholder="$t('SMS_FORM.PHONE_NUMBER.PLACEHOLDER')"
          validation="required|isValidPhoneNumber"
          :validation-messages="{
            required: $t('SMS_FORM.PHONE_NUMBER.REQUIRED_ERROR'),
            isValidPhoneNumber: $t('SMS_FORM.PHONE_NUMBER.VALID_ERROR'),
          }"
        />
      </div>

      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ $t('SMS_FORM.MESSAGE.LABEL') }}
        </label>
        <FormKit
          v-model="message"
          type="textarea"
          name="message"
          :placeholder="$t('SMS_FORM.MESSAGE.PLACEHOLDER')"
          rows="4"
          validation="required"
          :validation-messages="{
            required: $t('SMS_FORM.MESSAGE.REQUIRED_ERROR'),
          }"
        />
      </div>

      <div class="flex gap-2 mt-2">
        <CustomButton
          class="flex-1 font-medium"
          :bg-color="widgetColor"
          :text-color="textColor"
          :disabled="!isValid"
          @click="handleSubmit"
        >
          {{ $t('SMS_FORM.BUTTON_TEXT') }}
        </CustomButton>

        <CustomButton
          class="px-4 font-medium"
          bg-color="#f3f4f6"
          text-color="#374151"
          @click="handleCancel"
        >
          {{ $t('SMS_FORM.BUTTON_CANCEL') }}
        </CustomButton>
      </div>
    </div>
  </div>
</template>
