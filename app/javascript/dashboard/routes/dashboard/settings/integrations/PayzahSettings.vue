<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import payzahSettingsAPI from 'dashboard/api/payzahSettings';

import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextInput from 'next/input/Input.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'next/button/Button.vue';

const { t } = useI18n();

const id = ref(null);
const isEnabled = ref(false);
const isSubmitting = ref(false);
const isLoading = ref(true);

const formState = reactive({
  apiKey: '',
});

const validations = {
  apiKey: { required },
};

const v$ = useVuelidate(validations, formState);

const apiKeyError = computed(() =>
  v$.value.apiKey.$error
    ? t('INTEGRATION_SETTINGS.PAYZAH.FORM.API_KEY.ERROR')
    : ''
);

const loadPayzahSettings = async () => {
  try {
    isLoading.value = true;
    const response = await payzahSettingsAPI.get();
    const settings = response.data;

    if (settings.api_key) {
      id.value = settings.id;
      formState.apiKey = settings.api_key || '';
      isEnabled.value = settings.enabled || false;
    }
  } catch (error) {
    // If no settings exist (404), that's expected - just keep defaults
    if (error.response?.status !== 404) {
      useAlert(t('INTEGRATION_SETTINGS.PAYZAH.API.LOAD_ERROR'));
    }
  } finally {
    isLoading.value = false;
  }
};

const savePayzahSettings = async settings => {
  try {
    isSubmitting.value = true;

    if (isEnabled.value && formState.apiKey) {
      // Create or update settings based on existing id
      let response;
      if (id.value) {
        response = await payzahSettingsAPI.update(settings);
      } else {
        response = await payzahSettingsAPI.create(settings);
      }

      // Update local state with response data
      if (response?.data) {
        id.value = response.data.id;
      }

      useAlert(t('INTEGRATION_SETTINGS.PAYZAH.API.SUCCESS_MESSAGE'));
    } else {
      // Disable/delete settings
      await payzahSettingsAPI.delete();
      useAlert(t('INTEGRATION_SETTINGS.PAYZAH.API.DELETE_SUCCESS'));
    }
  } catch (error) {
    // Handle backend validation errors
    if (error.response?.data?.errors) {
      const errorMessages = error.response.data.errors;
      const firstError = Array.isArray(errorMessages)
        ? errorMessages[0]
        : errorMessages;
      useAlert(firstError);
    } else {
      useAlert(t('INTEGRATION_SETTINGS.PAYZAH.API.ERROR_MESSAGE'));
    }
    throw error;
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const settings = {
    api_key: formState.apiKey,
    enabled: isEnabled.value,
  };

  await savePayzahSettings(settings);
};

const handleDisable = async () => {
  id.value = null;
  formState.apiKey = '';

  // the empty save will delete the Payzah settings item
  await savePayzahSettings({});
};

const togglePayzah = async () => {
  if (!isEnabled.value) {
    await handleDisable();
  }
};

onMounted(() => {
  loadPayzahSettings();
});
</script>

<template>
  <SectionLayout
    :title="$t('INTEGRATION_SETTINGS.PAYZAH.FORM.TITLE')"
    :description="$t('INTEGRATION_SETTINGS.PAYZAH.FORM.DESCRIPTION')"
    :hide-content="!isEnabled || isLoading"
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch
          v-model="isEnabled"
          :disabled="isLoading"
          @change="togglePayzah"
        />
      </div>
    </template>

    <!-- Info Section -->
    <div class="mb-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 class="mb-2 font-semibold text-slate-900">
        {{
          $t(
            'INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.CONFIGURATION_INFO.TITLE'
          )
        }}
      </h3>
      <div class="space-y-2 text-sm text-slate-700">
        <p>
          {{
            $t(
              'INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.CONFIGURATION_INFO.TEXT'
            )
          }}
        </p>
      </div>
    </div>

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        name="apiKey"
        :label="$t('INTEGRATION_SETTINGS.PAYZAH.FORM.API_KEY.LABEL')"
        :help-message="$t('INTEGRATION_SETTINGS.PAYZAH.FORM.API_KEY.HELP')"
        :has-error="v$.apiKey.$error"
        :error-message="apiKeyError"
        required
      >
        <TextInput
          v-model="formState.apiKey"
          class="w-full"
          type="password"
          :placeholder="
            $t('INTEGRATION_SETTINGS.PAYZAH.FORM.API_KEY.PLACEHOLDER')
          "
        />
      </WithLabel>

      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          :label="$t('INTEGRATION_SETTINGS.PAYZAH.FORM.SUBMIT')"
        />
      </div>
    </form>

    <!-- Instructions -->
    <div class="mt-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 class="mb-2 font-semibold text-slate-900">
        {{ $t('INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.TITLE') }}
      </h3>
      <ol class="list-decimal space-y-2 pl-5 text-sm text-slate-700">
        <li>
          {{ $t('INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.STEP_1') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.STEP_2') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.STEP_3') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.PAYZAH.SETUP_INSTRUCTIONS.STEP_4') }}
        </li>
      </ol>
    </div>
  </SectionLayout>
</template>
