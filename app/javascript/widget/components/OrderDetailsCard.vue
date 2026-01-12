<template>
  <div class="card px-3.5 py-3 !mt-1 gap-4">
    <!-- <h2>Order Details</h2> -->
    <form @submit.prevent="handleSubmit">
      <PhoneInput
        v-model="phoneNumber"
        :placeholder="'Enter your phone number'"
        :readonly="false"
        :styles="inputStyles"
        :error="hasError"
        :default-country-code="defaultCountryCode"
        :default-dial-code="defaultDialCode"
        @setCode="handleSetCode"
      />
      <input
        id="orderId"
        v-model="orderId"
        type="text"
        placeholder="Enter Order ID (Optional)"
        class="order-id-input rounded-lg px-4 py-2.5"
      />
      <button
        :style="{
          background: widgetColor,
          color: textColor,
          borderRadius: '8px',
        }"
        type="submit"
        :class="'hover:opacity-80'"
        :disabled="isUpdating"
      >
        Submit
      </button>
    </form>
  </div>
</template>

<script>
import PhoneInput from 'widget/components/PhoneInput.vue';
import { mapActions } from 'vuex';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'OrderCard',
  components: {
    PhoneInput,
  },
  mixins: [configMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      phoneNumber: '',
      orderId: '',
      selectedDialCode: '',
      hasError: false,
      inputStyles: {},
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    defaultCountryCode() {
      return this.channelConfig.defaultCountryCode;
    },
    defaultDialCode() {
      return this.channelConfig.defaultDialCode;
    },
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    async handleSubmit() {
      this.isUpdating = true;
      try {
        const dialCode =
          this.selectedDialCode.split('+')[1] || this.defaultDialCode || 91;
        if (
          this.phoneNumber.trim() === '' ||
          !this.isValid10DigitPhoneNumber(this.phoneNumber)
        ) {
          this.hasError = true;
          return;
        }
        await this.$store.dispatch('message/update', {
          messageId: this.messageId,
          phone: `${dialCode}${this.phoneNumber}`,
          orderId: this.orderId,
        });
        const messageContent = `Order Details:\nPhone Number: ${dialCode}${this.phoneNumber}\nOrder ID: ${this.orderId}`;
        await this.sendMessage({
          content: messageContent,
          phoneNumber: `${dialCode}${this.phoneNumber}`,
          orderId: this.orderId,
          replyTo: this.messageId,
        });
      } catch (error) {
        // Ignore error
      } finally {
        this.isUpdating = false;
      }
    },
    isValid10DigitPhoneNumber(phoneNumber) {
      // Check if phoneNumber contains any non-digit characters (including alphabets)
      if (/\D/.test(phoneNumber)) {
        return false;
      }

      // At this point we know it's all digits, so just check the length
      return phoneNumber.length === 10;
    },
    handleSetCode(dialCode) {
      this.selectedDialCode = dialCode;
    },
  },
};
</script>

<style scoped>
form {
  display: flex;
  flex-direction: column;
}
.card {
  box-shadow:
    0 0.25rem 6px rgba(50, 50, 93, 0.08),
    0 1px 3px rgba(0, 0, 0, 0.05);
  border: 1px solid rgb(240, 240, 240);
  border-radius: 8px;
  color: #3c4858;
  font-size: 0.875rem;
  line-height: 1.5;
  max-width: 100%;
  width: 300px;
  display: flex;
  flex-direction: column;
  background-color: #fff;
}

.order-id-input {
  border: 1px solid #d9d9d9;
  width: 100%;
  padding: 8px;
  font-size: 14px;
}

h2 {
  font-weight: 600;
  color: #262626;
  font-weight: 600;
  font-size: 14px;
}

.input-group {
  margin-bottom: 15px;
  text-align: left;
}

.input-group label {
  display: block;
  margin-bottom: 5px;
  font-size: 0.9rem;
  color: #555;
}

.input-group input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 1rem;
}

button {
  width: 100%;
  margin-left: auto;
  align-self: flex-end;
  box-shadow: 0px 1px 0px 0px #0000000d;
  border-radius: 8px;
  margin-top: 1rem;
  padding: 8px 16px 8px 16px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  border: none;
}
</style>
