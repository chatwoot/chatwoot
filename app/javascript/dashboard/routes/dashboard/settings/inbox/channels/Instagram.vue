<script>
import { useVuelidate } from '@vuelidate/core';
import { useAccount } from 'dashboard/composables/useAccount';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import instagramClient from 'dashboard/api/channel/instagramClient';

export default {
  mixins: [globalConfigMixin],
  setup() {
    const { accountId } = useAccount();
    return {
      accountId,
      v$: useVuelidate(),
    };
  },
  data() {
    return {
      isCreating: false,
      hasError: false,
      errorStateMessage: '',
      errorStateDescription: '',
      isRequestingAuthorization: false,
    };
  },

  mounted() {
    const urlParams = new URLSearchParams(window.location.search);
    //  TODO: Handle error type
    // const errorType = urlParams.get('error_type');
    const errorCode = urlParams.get('code');
    const errorMessage = urlParams.get('error_message');

    if (errorMessage) {
      this.hasError = true;
      if (errorCode === '400') {
        this.errorStateMessage = errorMessage;
        this.errorStateDescription = this.$t(
          'INBOX_MGMT.ADD.INSTAGRAM.ERROR_AUTH'
        );
      } else {
        this.errorStateMessage = this.$t(
          'INBOX_MGMT.ADD.INSTAGRAM.ERROR_MESSAGE'
        );
        this.errorStateDescription = errorMessage;
      }
    }
    // User need to remove the error params from the url to avoid the error to be shown again after page reload, so that user can try again
    const cleanURL = window.location.pathname;
    window.history.replaceState({}, document.title, cleanURL);
  },

  methods: {
    async requestAuthorization() {
      this.isRequestingAuthorization = true;
      const response = await instagramClient.generateAuthorization();
      const {
        data: { url },
      } = response;

      window.location.href = url;
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="flex flex-col items-center justify-center h-full text-center">
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center h-full text-center"
      >
        <button
          class="flex items-center justify-center px-8 py-3.5 text-white rounded-full bg-gradient-to-r from-[#833AB4] via-[#FD1D1D] to-[#FCAF45] hover:shadow-lg transition-all duration-300 min-w-[240px] overflow-hidden"
          :disabled="isRequestingAuthorization"
          @click="requestAuthorization()"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5 mr-2"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path
              d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"
            />
          </svg>
          <span class="text-base font-medium">
            {{ $t('INBOX_MGMT.ADD.INSTAGRAM.CONTINUE_WITH_INSTAGRAM') }}
          </span>
          <span v-if="isRequestingAuthorization" class="ml-2">
            <svg
              class="w-5 h-5 animate-spin"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          </span>
        </button>
        <p class="py-6">
          {{ $t('INBOX_MGMT.ADD.INSTAGRAM.HELP') }}
        </p>
      </div>
    </div>
  </div>
</template>
