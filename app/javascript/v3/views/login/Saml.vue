<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { samlLogin } from '../../api/auth';

// components
import FormInput from '../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();

const credentials = ref({
  email: '',
});

const loginApi = ref({
  showLoading: false,
  hasErrored: false,
});

const validations = {
  credentials: {
    email: {
      required,
      email,
    },
  },
};

const v$ = useVuelidate(validations, { credentials });

const globalConfig = computed(() => store.getters['globalConfig/get']);

const showAlertMessage = message => {
  loginApi.value.showLoading = false;
  useAlert(message);
};

const submitSamlLogin = async () => {
  if (v$.value.credentials.email.$invalid) {
    showAlertMessage(t('LOGIN.EMAIL.ERROR'));
    return;
  }

  loginApi.value.hasErrored = false;
  loginApi.value.showLoading = true;

  try {
    const response = await samlLogin({ email: credentials.value.email });
    // Create a form and submit as POST request with CSRF token
    // The user has to make a post request to the redirect_url for
    // the passthru controller to work
    // There's multiple issues across the devise+omniauth ecosystem,
    // Here's one: https://github.com/omniauth/omniauth/issues/1053
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = response.data.redirect_url;

    // Add CSRF token
    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content');
    if (csrfToken) {
      const tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'authenticity_token';
      tokenInput.value = csrfToken;
      form.appendChild(tokenInput);
    }

    document.body.appendChild(form);
    form.submit();
  } catch (error) {
    loginApi.value.hasErrored = true;
    showAlertMessage(
      error?.response?.data?.error || t('LOGIN.SAML.API.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <main
    class="flex flex-col w-full min-h-screen py-20 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <section class="max-w-5xl mx-auto">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="block w-auto h-8 mx-auto dark:hidden"
      />
      <img
        v-if="globalConfig.logoDark"
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="hidden w-auto h-8 mx-auto dark:block"
      />
      <h2 class="mt-6 text-3xl font-medium text-center text-n-slate-12">
        {{ t('LOGIN.SAML.TITLE') }}
      </h2>
    </section>
    <section
      class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
      :class="{
        'animate-wiggle': loginApi.hasErrored,
      }"
    >
      <form class="space-y-5" @submit.prevent="submitSamlLogin">
        <FormInput
          v-model="credentials.email"
          name="email_address"
          type="text"
          :tabindex="1"
          required
          :label="t('LOGIN.SAML.WORK_EMAIL.LABEL')"
          :placeholder="t('LOGIN.SAML.WORK_EMAIL.PLACEHOLDER')"
          :has-error="v$.credentials.email.$error"
          @input="v$.credentials.email.$touch"
        />
        <NextButton
          lg
          type="submit"
          class="w-full"
          :tabindex="2"
          :label="t('LOGIN.SAML.SUBMIT')"
          :disabled="loginApi.showLoading"
          :is-loading="loginApi.showLoading"
        />
      </form>
    </section>
    <p class="mt-6 text-sm text-center text-n-slate-11">
      <router-link to="/app/login" class="text-link text-n-brand">
        {{ t('LOGIN.SAML.BACK_TO_LOGIN') }}
      </router-link>
    </p>
  </main>
</template>
