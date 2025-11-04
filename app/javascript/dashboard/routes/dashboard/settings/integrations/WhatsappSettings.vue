<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import whatsappSettingsAPI from 'dashboard/api/whatsappSettings';

import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextInput from 'next/input/Input.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'next/button/Button.vue';

const id = ref(null);
const isEnabled = ref(false);
const isSubmitting = ref(false);
const isLoading = ref(true);

const formState = reactive({
  appId: '',
  appSecret: '',
  configurationId: '',
  verifyToken: '',
  apiVersion: 'v22.0',
});

const validations = {
  appId: { required },
  appSecret: { required },
  configurationId: { required },
};

const v$ = useVuelidate(validations, formState);

const webhookUrl = computed(() => {
  return `${window.location.origin}/webhooks/whatsapp`;
});

const appIdError = computed(() =>
  v$.value.appId.$error ? 'WhatsApp App ID is required' : ''
);

const appSecretError = computed(() =>
  v$.value.appSecret.$error ? 'WhatsApp App Secret is required' : ''
);

const configurationIdError = computed(() =>
  v$.value.configurationId.$error ? 'Configuration ID is required' : ''
);

const loadWhatsappSettings = async () => {
  try {
    isLoading.value = true;
    const response = await whatsappSettingsAPI.get();
    const settings = response.data;

    if (settings.app_id) {
      id.value = settings.id;
      formState.appId = settings.app_id;
      formState.appSecret = settings.app_secret || '';
      formState.configurationId = settings.configuration_id || '';
      formState.verifyToken = settings.verify_token || '';
      formState.apiVersion = settings.api_version || 'v22.0';
      isEnabled.value = true;
    }
  } catch (error) {
    // If no settings exist (404), that's expected - just keep defaults
    if (error.response?.status !== 404) {
      useAlert('Failed to load WhatsApp settings');
    }
  } finally {
    isLoading.value = false;
  }
};

const saveWhatsappSettings = async settings => {
  try {
    isSubmitting.value = true;

    if (isEnabled.value && formState.appId) {
      // Create or update settings based on existing id
      let response;
      if (id.value) {
        response = await whatsappSettingsAPI.update(settings);
      } else {
        response = await whatsappSettingsAPI.create(settings);
      }

      // Update local state with response data
      if (response?.data) {
        id.value = response.data.id;
        formState.verifyToken =
          response.data.verify_token || formState.verifyToken;
      }

      useAlert('WhatsApp settings saved successfully');
    } else {
      // Disable/delete settings
      await whatsappSettingsAPI.delete();
      useAlert('WhatsApp settings disabled');
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
      useAlert('Failed to save WhatsApp settings');
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
    app_id: formState.appId,
    app_secret: formState.appSecret,
    configuration_id: formState.configurationId,
    verify_token: formState.verifyToken,
    api_version: formState.apiVersion,
  };

  await saveWhatsappSettings(settings);
};

const handleDisable = async () => {
  id.value = null;
  formState.appId = '';
  formState.appSecret = '';
  formState.configurationId = '';
  formState.verifyToken = '';
  formState.apiVersion = 'v22.0';

  // the empty save will delete the WhatsApp settings item
  await saveWhatsappSettings({});
};

const toggleWhatsapp = async () => {
  if (!isEnabled.value) {
    await handleDisable();
  }
};

onMounted(() => {
  loadWhatsappSettings();
});
</script>

<template>
  <SectionLayout
    :title="$t('INTEGRATION_SETTINGS.WHATSAPP.FORM.TITLE')"
    :description="$t('INTEGRATION_SETTINGS.WHATSAPP.FORM.DESCRIPTION')"
    :hide-content="!isEnabled || isLoading"
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch
          v-model="isEnabled"
          :disabled="isLoading"
          @change="toggleWhatsapp"
        />
      </div>
    </template>

    <!-- Info Section -->
    <div class="mb-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 class="mb-2 font-semibold text-slate-900">
        {{ $t('INTEGRATION_SETTINGS.WHATSAPP.FORM.WEBHOOK_SECTION.TITLE') }}
      </h3>
      <div class="space-y-2 text-sm text-slate-700">
        <div>
          <span class="font-medium">{{
            $t(
              'INTEGRATION_SETTINGS.WHATSAPP.FORM.WEBHOOK_SECTION.CALLBACK_URL'
            )
          }}</span>
          <code class="ml-2 rounded bg-slate-100 px-2 py-1">{{
            webhookUrl
          }}</code>
        </div>
        <div v-if="formState.verifyToken">
          <span class="font-medium">{{
            $t(
              'INTEGRATION_SETTINGS.WHATSAPP.FORM.WEBHOOK_SECTION.VERIFY_TOKEN'
            )
          }}</span>
          <code class="ml-2 rounded bg-slate-100 px-2 py-1">{{
            formState.verifyToken
          }}</code>
        </div>
      </div>
    </div>

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        name="appId"
        label="WhatsApp App ID"
        help-message="Your Facebook App ID for WhatsApp Business API"
        :has-error="v$.appId.$error"
        :error-message="appIdError"
        required
      >
        <TextInput
          v-model="formState.appId"
          class="w-full"
          placeholder="123456789012345"
        />
      </WithLabel>

      <WithLabel
        name="appSecret"
        label="WhatsApp App Secret"
        help-message="Your App Secret from Facebook Developer Console"
        :has-error="v$.appSecret.$error"
        :error-message="appSecretError"
        required
      >
        <TextInput
          v-model="formState.appSecret"
          class="w-full"
          type="password"
          placeholder="••••••••••••••••"
        />
      </WithLabel>

      <WithLabel
        name="configurationId"
        label="Configuration ID"
        help-message="Configuration ID for Embedded Signup flow"
        :has-error="v$.configurationId.$error"
        :error-message="configurationIdError"
        required
      >
        <TextInput
          v-model="formState.configurationId"
          class="w-full"
          placeholder="987654321098765"
        />
      </WithLabel>

      <WithLabel
        name="verifyToken"
        label="Webhook Verify Token"
        help-message="Custom token for webhook verification (auto-generated if empty)"
      >
        <TextInput
          v-model="formState.verifyToken"
          class="w-full"
          placeholder="your_custom_verify_token"
        />
      </WithLabel>

      <WithLabel
        name="apiVersion"
        :label="$t('INTEGRATION_SETTINGS.WHATSAPP.FORM.API_VERSION.LABEL')"
        :help-message="
          $t('INTEGRATION_SETTINGS.WHATSAPP.FORM.API_VERSION.HELP')
        "
      >
        <select
          v-model="formState.apiVersion"
          class="w-full rounded-md border border-slate-300 px-3 py-2"
        >
          <option value="v22.0">
            {{ $t('INTEGRATION_SETTINGS.WHATSAPP.FORM.API_VERSION.V22') }}
          </option>
          <option value="v21.0">
            {{ $t('INTEGRATION_SETTINGS.WHATSAPP.FORM.API_VERSION.V21') }}
          </option>
          <option value="v20.0">
            {{ $t('INTEGRATION_SETTINGS.WHATSAPP.FORM.API_VERSION.V20') }}
          </option>
        </select>
      </WithLabel>

      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          label="Save Configuration"
        />
      </div>
    </form>

    <!-- Instructions -->
    <div class="mt-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 class="mb-2 font-semibold text-slate-900">
        {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.TITLE') }}
      </h3>
      <ol class="list-decimal space-y-2 pl-5 text-sm text-slate-700">
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_1') }}
          <a
            href="https://developers.facebook.com"
            target="_blank"
            rel="noopener noreferrer"
            class="text-blue-600 underline"
          >
            {{
              $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_1_LINK')
            }}
          </a>
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_2') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_3') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_4') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_5') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_6') }}
        </li>
        <li>
          {{ $t('INTEGRATION_SETTINGS.WHATSAPP.SETUP_INSTRUCTIONS.STEP_7') }}
        </li>
      </ol>
    </div>
  </SectionLayout>
</template>
