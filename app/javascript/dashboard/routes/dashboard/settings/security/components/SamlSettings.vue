<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import samlSettingsAPI from 'dashboard/api/samlSettings';

import SectionLayout from '../../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextInput from 'next/input/Input.vue';
import TextArea from 'next/textarea/TextArea.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'next/button/Button.vue';
import SamlInfoSection from './SamlInfoSection.vue';
import SamlAttributeMap from './SamlAttributeMap.vue';

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const id = ref(null);
const fingerprint = ref('');
const spEntityId = ref('');
const spSlsUrl = ref('');
const spCertificate = ref('');
const isEnabled = ref(false);
const isSubmitting = ref(false);
const isLoading = ref(true);

const formState = reactive({
  ssoUrl: '',
  slsUrl: '',
  certificate: '',
  idpEntityId: '',
});

const httpUrl = value => {
  if (!value) return true;

  try {
    const parsedUrl = new URL(value);
    return (
      ['http:', 'https:'].includes(parsedUrl.protocol) &&
      Boolean(parsedUrl.hostname) &&
      !/\s/.test(value)
    );
  } catch {
    return false;
  }
};

const validations = {
  ssoUrl: { required },
  slsUrl: { httpUrl },
  certificate: { required },
  idpEntityId: { required },
};

const v$ = useVuelidate(validations, formState);

const hasFeature = computed(() => isCloudFeatureEnabled('saml'));

const ssoUrlError = computed(() =>
  v$.value.ssoUrl.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.SSO_URL_ERROR')
    : ''
);

const slsUrlError = computed(() =>
  v$.value.slsUrl.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.SLS_URL_ERROR')
    : ''
);

const certificateError = computed(() =>
  v$.value.certificate.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.CERTIFICATE_ERROR')
    : ''
);

const idpEntityIdError = computed(() =>
  v$.value.idpEntityId.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.IDP_ENTITY_ID_ERROR')
    : ''
);

const loadSamlSettings = async () => {
  if (!hasFeature.value) return;

  try {
    isLoading.value = true;
    const response = await samlSettingsAPI.get();
    const settings = response.data;

    if (settings.sso_url) {
      id.value = settings.id;
      formState.ssoUrl = settings.sso_url;
      formState.slsUrl = settings.sls_url || '';
      formState.certificate = settings.certificate || '';
      spEntityId.value = settings.sp_entity_id || '';
      spSlsUrl.value = settings.sp_sls_url || '';
      spCertificate.value = settings.sp_certificate || '';
      formState.idpEntityId = settings.idp_entity_id || '';
      fingerprint.value = settings.fingerprint || '';
      isEnabled.value = formState.ssoUrl !== '';
    }
  } catch (error) {
    // If no settings exist (404), that's expected - just keep defaults
    if (error.response?.status !== 404) {
      useAlert(t('SECURITY_SETTINGS.SAML.API.ERROR_LOADING'));
    }
  } finally {
    isLoading.value = false;
  }
};

const saveSamlSettings = async settings => {
  try {
    isSubmitting.value = true;

    if (isEnabled.value && formState.ssoUrl) {
      // Create or update settings based on existing id
      let response;
      if (id.value) {
        response = await samlSettingsAPI.update(settings);
      } else {
        response = await samlSettingsAPI.create(settings);
      }

      // Update local state with response data including fingerprint and id
      if (response?.data) {
        id.value = response.data.id;
        fingerprint.value = response.data.fingerprint || '';
        spEntityId.value = response.data.sp_entity_id || '';
        spSlsUrl.value = response.data.sp_sls_url || '';
        spCertificate.value = response.data.sp_certificate || '';
      }

      useAlert(t('SECURITY_SETTINGS.SAML.API.SUCCESS'));
    } else {
      // Disable/delete settings
      await samlSettingsAPI.delete();
      useAlert(t('SECURITY_SETTINGS.SAML.API.DISABLED'));
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
      useAlert(t('SECURITY_SETTINGS.SAML.API.ERROR'));
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
    sso_url: formState.ssoUrl,
    sls_url: formState.slsUrl,
    certificate: formState.certificate,
    idp_entity_id: formState.idpEntityId,
    role_mappings: {},
  };

  await saveSamlSettings(settings);
};

const handleDisable = async () => {
  id.value = null;
  formState.ssoUrl = '';
  formState.slsUrl = '';
  formState.certificate = '';
  spEntityId.value = '';
  spSlsUrl.value = '';
  spCertificate.value = '';
  formState.idpEntityId = '';
  fingerprint.value = '';

  // the empty save will delete the SAML settings item
  await saveSamlSettings({});
};

const toggleSaml = async () => {
  if (!isEnabled.value) {
    await handleDisable();
  }
};

onMounted(() => {
  loadSamlSettings();
});
</script>

<template>
  <SectionLayout
    :title="t('SECURITY_SETTINGS.SAML.TITLE')"
    :description="t('SECURITY_SETTINGS.SAML.NOTE')"
    beta
    :hide-content="!hasFeature || !isEnabled || isLoading"
    class="max-w-2xl ltr:mr-auto rtl:ml-auto"
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch
          v-model="isEnabled"
          :disabled="isLoading"
          @change="toggleSaml"
        />
      </div>
    </template>

    <SamlInfoSection
      class="mb-5"
      :fingerprint="fingerprint"
      :sp-entity-id="spEntityId"
      :sp-sls-url="spSlsUrl"
      :sp-certificate="spCertificate"
    />
    <SamlAttributeMap class="mb-5" />

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        name="ssoUrl"
        :label="t('SECURITY_SETTINGS.SAML.SSO_URL.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.SSO_URL.HELP')"
        :has-error="v$.ssoUrl.$error"
        :error-message="ssoUrlError"
        required
      >
        <TextInput
          v-model="formState.ssoUrl"
          class="w-full"
          type="url"
          :placeholder="t('SECURITY_SETTINGS.SAML.SSO_URL.PLACEHOLDER')"
        />
      </WithLabel>

      <WithLabel
        name="slsUrl"
        :label="t('SECURITY_SETTINGS.SAML.SLS_URL.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.SLS_URL.HELP')"
        :has-error="v$.slsUrl.$error"
        :error-message="slsUrlError"
      >
        <TextInput
          v-model="formState.slsUrl"
          class="w-full"
          type="url"
          :placeholder="t('SECURITY_SETTINGS.SAML.SLS_URL.PLACEHOLDER')"
        />
      </WithLabel>

      <WithLabel
        name="idpEntityId"
        :label="t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.HELP')"
        :has-error="v$.idpEntityId.$error"
        :error-message="idpEntityIdError"
        required
      >
        <TextInput
          v-model="formState.idpEntityId"
          class="w-full"
          :placeholder="t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.PLACEHOLDER')"
        />
      </WithLabel>

      <WithLabel
        name="certificate"
        :label="t('SECURITY_SETTINGS.SAML.CERTIFICATE.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.CERTIFICATE.HELP')"
        :has-error="v$.certificate.$error"
        :error-message="certificateError"
        required
      >
        <TextArea
          v-model="formState.certificate"
          class="w-full"
          rows="8"
          :placeholder="t('SECURITY_SETTINGS.SAML.CERTIFICATE.PLACEHOLDER')"
        />
      </WithLabel>

      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          :label="t('SECURITY_SETTINGS.SAML.UPDATE_BUTTON')"
        />
      </div>
    </form>
  </SectionLayout>
</template>
