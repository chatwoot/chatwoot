<script setup>
import Spinner from 'shared/components/Spinner.vue';
import { defineProps, defineEmits, computed, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useStore } from 'dashboard/composables/store';
import { required, email, minLength, maxLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { ref } from 'vue';
import Button from 'shared/components/Button.vue';
import { isAxiosError } from 'axios';

const props = defineProps({
  unverfied_shopify_email: {
    type: String,
    required: true,
  },
});

const form = reactive({
  email: '',
});

const rules = {
  email: { required, email },
};

const v$ = useVuelidate(rules, form);

const oform = reactive({
  otp: '',
});

const orules = {
  otp: { required, minLength: minLength(6), maxLength: maxLength(6) },
};

const o$ = useVuelidate(orules, oform);

const store = useStore();

const widgetColor = useMapGetter('appConfig/getWidgetColor');

const contactUiFlags = computed(() => store.getters['contacts/getUiFlags']);

const otpStage = ref(false);

const startTime = ref(Date.now());
const elapsed = ref(0);
let timer = null;

const formattedTime = computed(() => {
  const seconds = Math.floor(elapsed.value / 1000) % 60;
  const minutes = Math.floor(elapsed.value / 60000);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
});

const onSubmit = async () => {
  console.log('contacts/verifyShopifyEmail');
  try {
    await store.dispatch('contacts/verifyShopifyEmail', {
      email:
        props.unverfied_shopify_email === null
          ? form.email
          : props.unverfied_shopify_email,
    });

    otpStage.value = true;
    onOtpSent();
  } catch (e) {}
};

const otpResult = ref({
  canResend: true,
});

const onOtpSent = () => {
  otpResult.value = {
    canResend: false,
  };
  timer = setInterval(() => {
    elapsed.value = Date.now() - startTime.value;

    if (elapsed.value >= 60000) {
      clearInterval(timer);
      otpResult.value = {
        canResend: true,
      };
    }
  }, 1000);
};

const verifyOtp = async () => {
  try {
    const result = await store.dispatch('contacts/verifyShopifyOTP', {
      otp: oform.otp,
    });
    console.log('gotten final result', result);
  } catch (e) {
    console.log('gotten error', e);
  }

  console.log(`OTP RESULT:`, otpResult.value);
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <h3 class="font-medium text-n-slate-12">
      {{ $t('SHOPIFY_LOGIN') }}
    </h3>
    <form
      v-if="props.unverfied_shopify_email === null"
      class="email-input-group h-10 flex my-2 mx-0 min-w-[200px] gap-4"
      @submit.prevent="onSubmit"
    >
      <input
        v-model="form.email"
        type="email"
        :placeholder="$t('EMAIL_PLACEHOLDER')"
        :class="{ error: v$.email.$error }"
        @input="v$.email.$touch"
        @keydown.enter="onSubmit"
        @blur="v$.email.$touch()"
      />

      <Button
        :style="{ color: widgetColor }"
        :disabled="v$.email.$invalid"
        buttonType="submit"
      >
        <button
          class="flex flex-row items-center justify-center h-[20px] w-[40px]"
        >
          <span
            class="text-white flex flex-row items-center justify-center h-[20px] w-full"
            v-if="!contactUiFlags.isUpdating"
          >
            {{ $t('VERIFY_EMAIL') }}
          </span>

          <Spinner v-else class="h-full flex items-center justify-center" />
        </button>
      </Button>
    </form>

    <form
      v-else-if="otpStage"
      class="email-input-group h-10 flex my-2 mx-0 min-w-[200px] gap-4"
      @submit.prevent="verifyOtp"
    >
      <div class="flex flex-col items-start">
        <input
          v-model="oform.otp"
          type="text"
          :placeholder="$t('OTP_PLACEHOLDER')"
          :class="{ error: o$.otp.$error }"
          @input="o$.otp.$touch"
          @keydown.enter="verifyOtp"
          @blur="o$.otp.$touch()"
        />

        <span
          v-if="contactUiFlags.otpError"
          class="text-xs text-red-500 pt-1"
          >{{ contactUiFlags.otpError }}</span
        >
      </div>

      <div class="flex flex-col gap-2">
        <Button
          :style="{ color: widgetColor }"
          :disabled="o$.otp.$invalid"
          buttonType="submit"
        >
          <button
            class="flex flex-row items-center justify-center h-[20px] w-[40px]"
          >
            <span
              class="text-white flex flex-row items-center justify-center h-[20px] w-full"
              v-if="!contactUiFlags.isUpdating"
            >
              {{ $t('VERIFY_OTP') }}
            </span>

            <Spinner v-else class="h-full flex items-center justify-center" />
          </button>
        </Button>
      </div>
    </form>
    <div
      class="flex flex-col"
      v-if="
        props.unverfied_shopify_email !== null &&
        !otpStage &&
        otpResult.canResend
      "
    >
      <div>Please verify your email via OTP: {{ unverfied_shopify_email }}</div>
      <Button class="h-[40px]">
        <button
          :style="{ color: widgetColor }"
          @click.stop="onSubmit"
          class="flex flex-row items-center justify-center h-full w-full"
        >
          <label
            class="text-white h-full flex items-center justify-center"
            v-if="!contactUiFlags.isUpdating"
          >
            {{ $t('SEND_OTP') }}
          </label>
          <Spinner v-else class="h-full flex items-center justify-center" />
        </button>
      </Button>
    </div>
  </div>
</template>
