<script>
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, minLength, email } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import FormInput from '../../../../components/Form/Input.vue';
import { resetPassword } from '../../../../api/auth';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: { FormInput, NextButton },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      credentials: { email: '' },
      resetPassword: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
  validations() {
    return {
      credentials: {
        email: {
          required,
          email,
          minLength: minLength(4),
        },
      },
    };
  },
  methods: {
    showAlertMessage(message) {
      this.resetPassword.showLoading = false;
      useAlert(message);
    },
    submit() {
      this.resetPassword.showLoading = true;
      resetPassword(this.credentials)
        .then(res => {
          let successMessage = this.$t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
          if (res.data && res.data.message) {
            successMessage = res.data.message;
          }
          this.showAlertMessage(successMessage);
        })
        .catch(error => {
          let errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
          if (error?.response?.data?.message) {
            errorMessage = error.response.data.message;
          }
          this.showAlertMessage(errorMessage);
        });
    },
  },
};
</script>

<template>
  <main
    class="flex min-h-screen w-full flex-col bg-n-brand/5 py-16 dark:bg-background sm:px-6 sm:py-20 md:py-24 lg:px-8"
  >
    <section class="mx-auto w-full max-w-5xl px-4 sm:px-0">
      <div class="flex flex-col items-center justify-center">
        <img
          :src="globalConfig.logoThumbnail"
          :alt="globalConfig.installationName"
          class="block h-24 w-auto shrink-0 sm:h-28 md:h-32"
        />
        <div
          class="flex flex-col items-center gap-0.5 text-center sm:items-start sm:text-left"
        >
          <span
            class="font-inter text-4xl font-bold uppercase leading-none tracking-tight text-transparent bg-gradient-to-r from-woot-500 via-secondary to-green-200 bg-clip-text sm:text-5xl"
          >
            {{ globalConfig.installationName }}
          </span>
        </div>
      </div>
    </section>

    <section
      class="mt-12 mb-10 overflow-hidden rounded-xl bg-white px-8 pb-0 pt-8 shadow-sm ring-1 ring-n-container dark:bg-surface-container dark:ring-0 dark:shadow-xl sm:mx-auto sm:mt-14 sm:mb-12 sm:w-full sm:max-w-lg sm:px-10 sm:pt-10"
    >
      <div>
        <h1
          class="mb-2 text-[2rem] font-bold leading-[1.15] tracking-tight text-balance text-n-slate-12 dark:text-on-surface sm:text-[2.125rem]"
        >
          {{ $t('RESET_PASSWORD.TITLE') }}
        </h1>
        <p
          class="mb-6 max-w-md text-sm leading-relaxed text-n-slate-11 dark:text-on-surface-variant sm:mb-8"
        >
          {{ $t('RESET_PASSWORD.DESCRIPTION') }}
        </p>
        <form class="space-y-6" @submit.prevent="submit">
          <FormInput
            v-model="credentials.email"
            name="email_address"
            :label="$t('RESET_PASSWORD.EMAIL.LABEL')"
            :has-error="v$.credentials.email.$error"
            :error-message="$t('RESET_PASSWORD.EMAIL.ERROR')"
            :placeholder="$t('RESET_PASSWORD.EMAIL.PLACEHOLDER')"
            @input="v$.credentials.email.$touch"
          />
          <NextButton
            lg
            type="submit"
            data-testid="submit_button"
            class="mt-1 w-full"
            :label="$t('RESET_PASSWORD.SUBMIT')"
            :disabled="
              v$.credentials.email.$invalid || resetPassword.showLoading
            "
            :is-loading="resetPassword.showLoading"
          />
        </form>
      </div>
      <div
        class="mt-8 pb-8 pt-1 text-center text-xs leading-relaxed text-n-slate-11 dark:text-on-surface-variant sm:mt-10 sm:pb-10 sm:pt-2 sm:text-sm"
      >
        <div
          aria-hidden="true"
          class="mx-auto mb-5 h-px w-[min(10rem,62%)] max-w-full bg-gradient-to-r from-transparent via-n-container to-transparent opacity-80 dark:via-outline-variant sm:mb-6 sm:w-[min(12rem,58%)]"
        />
        <span class="text-n-slate-11 dark:text-on-surface-variant">
          {{ $t('RESET_PASSWORD.GO_BACK_TO_LOGIN') }}
        </span>
        {{ ' ' }}
        <router-link
          to="/app/login"
          class="font-semibold text-n-brand underline-offset-4 transition-opacity hover:opacity-90 hover:underline dark:text-secondary"
        >
          {{ $t('RESET_PASSWORD.BACK_TO_LOGIN_LINK') }}
        </router-link>
      </div>
    </section>
  </main>
</template>
