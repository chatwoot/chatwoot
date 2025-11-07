<script setup>
import { ref, reactive, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { resetPassword } from '../../../../api/auth';
import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const credentials = reactive({ email: '' });
const showLoading = ref(false);

const rules = computed(() => ({
  credentials: {
    email: {
      required,
      email,
      minLength: minLength(4),
    },
  },
}));

const v$ = useVuelidate(rules, { credentials });

const showAlertMessage = message => {
  showLoading.value = false;
  useAlert(message);
};

const submit = async () => {
  showLoading.value = true;

  try {
    const res = await resetPassword(credentials);
    let successMessage = t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
    if (res.data && res.data.message) {
      successMessage = res.data.message;
    }
    showAlertMessage(successMessage);
  } catch (error) {
    let errorMessage = t('RESET_PASSWORD.API.ERROR_MESSAGE');
    if (error?.response?.data?.message) {
      errorMessage = error.response.data.message;
    }
    showAlertMessage(errorMessage);
  }
};
</script>

<template>
  <div
    class="flex flex-col justify-center w-full min-h-screen py-12 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <form
      class="bg-white shadow sm:mx-auto sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
      @submit.prevent="submit"
    >
      <h1
        class="mb-1 text-2xl font-medium tracking-tight text-left text-n-slate-12"
      >
        {{ $t('RESET_PASSWORD.TITLE') }}
      </h1>
      <p
        class="mb-4 text-sm font-normal leading-6 tracking-normal text-n-slate-11"
      >
        {{ replaceInstallationName($t('RESET_PASSWORD.DESCRIPTION')) }}
      </p>
      <div class="space-y-5">
        <Input
          v-model="credentials.email"
          name="email_address"
          autocomplete="email"
          type="email"
          :message="
            v$.credentials.email.$error ? $t('RESET_PASSWORD.EMAIL.ERROR') : ''
          "
          :message-type="v$.credentials.email.$error ? 'error' : ''"
          :placeholder="$t('RESET_PASSWORD.EMAIL.PLACEHOLDER')"
          @input="v$.credentials.email.$touch"
        />
        <NextButton
          lg
          type="submit"
          data-testid="submit_button"
          class="w-full"
          :label="$t('RESET_PASSWORD.SUBMIT')"
          :disabled="v$.credentials.email.$invalid || showLoading"
          :is-loading="showLoading"
        />
      </div>
      <p class="mt-4 -mb-1 text-sm text-n-slate-11">
        {{ $t('RESET_PASSWORD.GO_BACK_TO_LOGIN') }}
        <router-link to="/auth/login" class="text-link text-n-brand">
          {{ $t('COMMON.CLICK_HERE') }}.
        </router-link>
      </p>
    </form>
  </div>
</template>
