<template>
  <div class="card">
    <h2>Order Details</h2>
    <form @submit.prevent="handleSubmit">
      <PhoneInput
        v-model="phoneNumber"
        :placeholder="'Enter your phone number'"
        :readonly="false"
        :styles="inputStyles"
        :error="hasError"
        :default-country-code="'IN'"
        :default-dial-code="'+91'"
        @setCode="handleSetCode"
      />
      <input
        id="orderId"
        v-model="orderId"
        type="text"
        placeholder="Enter order ID"
        required
        class="order-id-input"
      />
      <button type="submit" :disabled="isUpdating">Submit</button>
    </form>
  </div>
</template>

<script>
import PhoneInput from 'widget/components/PhoneInput.vue';
import { mapActions } from 'vuex';

export default {
  name: 'OrderCard',
  components: {
    PhoneInput,
  },
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
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    async handleSubmit() {
      this.isUpdating = true;
      try {
        const dialCode = this.selectedDialCode.split('+')[1] || 91;
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
  gap: 5px;
}
.card {
  box-shadow: 0px 2px 10px 0px #0000001a;
  box-shadow: 0px 0px 2px 0px #00000033;
  border-radius: 8px;
  padding: 16px;
  gap: 8px;
  width: 300px;
  display: flex;
  flex-direction: column;
  background-color: #fff;
  gap: 10px;
  margin-top: 10px;
}

.order-id-input {
  border: 1px solid #d9d9d9;
  border-radius: 4px;
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
  width: 50%;
  margin-left: auto;
  align-self: flex-end;
  background-color: #559cf8;
  box-shadow: 0px 1px 0px 0px #0000000d;
  border-radius: 4px;
  margin-top: 10px;
  width: 81px;
  height: 32px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  border: none;
}
</style>
