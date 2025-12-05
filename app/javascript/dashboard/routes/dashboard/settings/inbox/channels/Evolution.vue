<script setup>
import { ref, computed, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import {
  isEvolutionAPIError,
  formatEvolutionError,
  getEvolutionErrorKey,
} from 'dashboard/helper/evolutionErrorHandler';

import NextButton from 'dashboard/components-next/button/Button.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const phoneNumber = ref('');
const retryCount = ref(0);
const maxRetries = 3;

// Enhanced error state management
const errorState = reactive({
  hasError: false,
  message: '',
  canRetry: false,
  isRetrying: false,
  troubleshootingTips: [],
  showTroubleshooting: false,
});

const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);

const rules = {
  phoneNumber: { required, isPhoneE164OrEmpty },
};

const v$ = useVuelidate(rules, { phoneNumber });

const clearError = () => {
  errorState.hasError = false;
  errorState.message = '';
  errorState.canRetry = false;
  errorState.troubleshootingTips = [];
  errorState.showTroubleshooting = false;
};

const showTroubleshootingTips = () => {
  errorState.showTroubleshooting = true;
};

const handleCreationError = error => {
  if (error.isEvolutionError || isEvolutionAPIError(error)) {
    const errorKey = getEvolutionErrorKey(error.originalError || error);
    const formattedError = formatEvolutionError(
      error.originalError || error,
      t
    );

    errorState.hasError = true;
    errorState.message = t(errorKey);
    errorState.canRetry =
      formattedError.canRetry && retryCount.value < maxRetries;
    errorState.troubleshootingTips = formattedError.troubleshooting;

    // Show alert with enhanced message
    const alertMessage = `${errorState.message}\n\n${t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_RETRY_MESSAGE')}`;
    useAlert(alertMessage);
  } else {
    // Fallback for non-Evolution errors
    const fallbackMessage =
      error.message || t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
    useAlert(fallbackMessage);
  }
};

const createChannel = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  clearError();

  try {
    const whatsappChannel = await store.dispatch(
      'inboxes/createEvolutionChannel',
      {
        name: phoneNumber.value.replace(/\D/g, ''),
        channel: {
          type: 'api',
        },
      }
    );

    // Reset retry count on success
    retryCount.value = 0;

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: whatsappChannel.id,
      },
    });
  } catch (error) {
    handleCreationError(error);
  }
};

const retryChannelCreation = async () => {
  if (retryCount.value >= maxRetries) {
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_RETRY_MESSAGE'));
    return;
  }

  clearError();
  errorState.isRetrying = true;
  retryCount.value += 1;

  try {
    await createChannel();
  } finally {
    errorState.isRetrying = false;
  }
};

const getSubmitButtonLabel = () => {
  if (errorState.isRetrying) {
    return t('GENERAL.RETRYING');
  }
  if (uiFlags.value.isCreating) {
    return t('GENERAL.CREATING');
  }
  return t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON');
};
</script>

<template>
  <div class="space-y-4">
    <!-- Error Display Section -->
    <div
      v-if="errorState.hasError"
      class="bg-red-50 border border-red-200 rounded-lg p-4 space-y-3"
    >
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0">
          <svg
            class="w-5 h-5 text-red-400"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fill-rule="evenodd"
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
        <div class="flex-1">
          <h4 class="text-sm font-medium text-red-800 mb-1">
            {{
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_INSTANCE_CREATION_FAILED'
              )
            }}
          </h4>
          <p class="text-sm text-red-700">
            {{ errorState.message }}
          </p>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex items-center space-x-3">
        <NextButton
          v-if="errorState.canRetry"
          :is-loading="errorState.isRetrying"
          size="small"
          variant="outline"
          color="red"
          @click="retryChannelCreation"
        >
          {{ $t('GENERAL.RETRY') }} ({{ retryCount }} {{ $t('GENERAL.OF') }}
          {{ maxRetries }})
        </NextButton>

        <button
          v-if="errorState.troubleshootingTips.length > 0"
          type="button"
          class="text-sm text-red-700 hover:text-red-900 underline"
          @click="showTroubleshootingTips"
        >
          {{
            $t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.TITLE')
          }}
        </button>
      </div>

      <!-- Troubleshooting Tips -->
      <div
        v-if="
          errorState.showTroubleshooting &&
          errorState.troubleshootingTips.length > 0
        "
        class="bg-red-25 border border-red-100 rounded p-3 mt-3"
      >
        <h5 class="text-sm font-medium text-red-800 mb-2">
          {{
            $t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.TITLE')
          }}
        </h5>
        <ul class="text-sm text-red-700 space-y-1">
          <li
            v-for="(tip, index) in errorState.troubleshootingTips"
            :key="index"
            class="flex items-start space-x-2"
          >
            <span class="text-red-400 mt-0.5">{{
              $t('GENERAL.BULLET_POINT')
            }}</span>
            <span>{{ tip }}</span>
          </li>
        </ul>
      </div>
    </div>

    <!-- Main Form -->
    <form class="flex flex-wrap mx-0" @submit.prevent="createChannel()">
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
          <input
            v-model.trim="phoneNumber"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')
            "
            @blur="v$.phoneNumber.$touch"
            @input="clearError"
          />
          <span v-if="v$.phoneNumber.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating || errorState.isRetrying"
          :disabled="errorState.hasError && !errorState.canRetry"
          type="submit"
          solid
          blue
          :label="getSubmitButtonLabel()"
        />

        <!-- Loading message for Evolution API -->
        <p
          v-if="uiFlags.isCreating || errorState.isRetrying"
          class="text-sm text-gray-600 mt-2"
        >
          {{
            errorState.isRetrying
              ? $t('GENERAL.RETRYING_CONNECTION_TO_EVOLUTION_API')
              : $t('GENERAL.CONNECTING_TO_EVOLUTION_API')
          }}
        </p>
      </div>
    </form>
  </div>
</template>
