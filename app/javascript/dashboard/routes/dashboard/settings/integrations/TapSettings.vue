<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import tapSettingsAPI from 'dashboard/api/tapSettings';

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
  secretKey: '',
});

const validations = {
  secretKey: { required },
};

const v$ = useVuelidate(validations, formState);

const secretKeyError = computed(() =>
  v$.value.secretKey.$error
    ? t('INTEGRATION_SETTINGS.TAP.FORM.SECRET_KEY.ERROR')
    : ''
);

const loadTapSettings = async () => {
  try {
    isLoading.value = true;
    const response = await tapSettingsAPI.get();
    const settings = response.data;

    if (settings.secret_key) {
      id.value = settings.id;
      formState.secretKey = settings.secret_key || '';
      isEnabled.value = settings.enabled || false;
    }
  } catch (error) {
    // If no settings exist (404), that's expected - just keep defaults
    if (error.response?.status !== 404) {
      useAlert(t('INTEGRATION_SETTINGS.TAP.API.LOAD_ERROR'));
    }
  } finally {
    isLoading.value = false;
  }
};

const saveTapSettings = async settings => {
  try {
    isSubmitting.value = true;

    if (isEnabled.value && formState.secretKey) {
      // Create or update settings based on existing id
      let response;
      if (id.value) {
        response = await tapSettingsAPI.update(settings);
      } else {
        response = await tapSettingsAPI.create(settings);
      }

      // Update local state with response data
      if (response?.data) {
        id.value = response.data.id;
      }

      useAlert(t('INTEGRATION_SETTINGS.TAP.API.SUCCESS_MESSAGE'));
    } else {
      // Disable/delete settings
      await tapSettingsAPI.delete();
      useAlert(t('INTEGRATION_SETTINGS.TAP.API.DELETE_SUCCESS'));
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
      useAlert(t('INTEGRATION_SETTINGS.TAP.API.ERROR_MESSAGE'));
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
    secret_key: formState.secretKey,
    enabled: isEnabled.value,
  };

  await saveTapSettings(settings);
};

const handleDisable = async () => {
  id.value = null;
  formState.secretKey = '';

  // the empty save will delete the Tap settings item
  await saveTapSettings({});
};

const toggleTap = async () => {
  if (!isEnabled.value) {
    await handleDisable();
  }
};

onMounted(() => {
  loadTapSettings();
});
</script>

<template>
  <SectionLayout
    :title="$t('INTEGRATION_SETTINGS.TAP.FORM.TITLE')"
    :description="$t('INTEGRATION_SETTINGS.TAP.FORM.DESCRIPTION')"
    :hide-content="!isEnabled || isLoading"
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" :disabled="isLoading" @change="toggleTap" />
      </div>
    </template>

    <!-- Info Section -->
    <div class="mb-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 class="mb-2 font-semibold text-slate-900">
        {{
          $t(
            'INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.CONFIGURATION_INFO.TITLE'
          )
        }}
      </h3>
      <div class="space-y-2 text-sm text-slate-700">
        <p>
          {{
            $t(
              'INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.CONFIGURATION_INFO.TEXT'
            )
          }}
        </p>
      </div>
    </div>

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        name="secretKey"
        :label="$t('INTEGRATION_SETTINGS.TAP.FORM.SECRET_KEY.LABEL')"
        :help-message="$t('INTEGRATION_SETTINGS.TAP.FORM.SECRET_KEY.HELP')"
        :has-error="v$.secretKey.$error"
        :error-message="secretKeyError"
        required
      >
        <TextInput
          v-model="formState.secretKey"
          class="w-full"
          type="password"
          :placeholder="
            $t('INTEGRATION_SETTINGS.TAP.FORM.SECRET_KEY.PLACEHOLDER')
          "
        />
      </WithLabel>

      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          :label="$t('INTEGRATION_SETTINGS.TAP.FORM.SUBMIT')"
        />
      </div>
    </form>

    <!-- Instructions -->
    <div class="mt-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 class="mb-2 font-semibold text-slate-900">
        {{ $t('INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.TITLE') }}
      </h3>
      <ol class="list-decimal space-y-2 pl-5 text-sm text-slate-700">
        <li>
          {{ $t('INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.STEP_1') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.STEP_2') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.STEP_3') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.TAP.SETUP_INSTRUCTIONS.STEP_4') }}
        </li>
      </ol>
    </div>
  </SectionLayout>
</template>
