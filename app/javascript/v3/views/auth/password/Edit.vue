<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { setNewPassword } from '../../../api/auth';

const props = defineProps({
  resetPasswordToken: { type: String, default: '' },
});

const { t } = useI18n();

const credentials = reactive({
  confirmPassword: '',
  password: '',
});

const showLoading = ref(false);

const rules = computed(() => ({
  credentials: {
    password: {
      required,
      minLength: minLength(6),
    },
    confirmPassword: {
      required,
      minLength: minLength(6),
      isEqPassword(value) {
        return value === credentials.password;
      },
    },
  },
}));

const v$ = useVuelidate(rules, { credentials });

const showAlertMessage = message => {
  showLoading.value = false;
  useAlert(message);
};

const submitForm = async () => {
  showLoading.value = true;
  const credentialsData = {
    confirmPassword: credentials.confirmPassword,
    password: credentials.password,
    resetPasswordToken: props.resetPasswordToken,
  };

  try {
    await setNewPassword(credentialsData);
    window.location = DEFAULT_REDIRECT_URL;
  } catch (error) {
    showAlertMessage(error?.message || t('SET_NEW_PASSWORD.API.ERROR_MESSAGE'));
  }
};

onMounted(() => {
  // If url opened without token, redirect to login
  if (!props.resetPasswordToken) {
    window.location = DEFAULT_REDIRECT_URL;
  }
});
</script>

<template>
  <div
    class="flex flex-col justify-center w-full min-h-screen py-12 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <form
      class="bg-white shadow sm:mx-auto sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
      @submit.prevent="submitForm"
    >
      <h1
        class="mb-1 text-2xl font-medium tracking-tight text-left text-n-slate-12"
      >
        {{ $t('SET_NEW_PASSWORD.TITLE') }}
      </h1>

      <div class="space-y-6 mt-5">
        <Input
          v-model="credentials.password"
          name="password"
          type="password"
          autocomplete="new-password"
          :message-type="v$.credentials.password.$error ? 'error' : ''"
          :message="
            v$.credentials.password.$error
              ? $t('SET_NEW_PASSWORD.PASSWORD.ERROR')
              : ''
          "
          :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
          @blur="v$.credentials.password.$touch"
        />
        <Input
          v-model="credentials.confirmPassword"
          name="confirm_password"
          type="password"
          autocomplete="confirm-password"
          :message-type="v$.credentials.confirmPassword.$error ? 'error' : ''"
          :message="
            v$.credentials.confirmPassword.$error
              ? $t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.ERROR')
              : ''
          "
          :placeholder="$t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.PLACEHOLDER')"
          @blur="v$.credentials.confirmPassword.$touch"
        />
        <NextButton
          lg
          type="submit"
          data-testid="submit_button"
          class="w-full"
          :label="$t('SET_NEW_PASSWORD.SUBMIT')"
          :disabled="
            v$.credentials.password.$invalid ||
            v$.credentials.confirmPassword.$invalid ||
            showLoading
          "
          :is-loading="showLoading"
        />
      </div>
    </form>
  </div>
</template>
