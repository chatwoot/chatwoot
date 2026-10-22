<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import samlSettingsAPI from 'dashboard/api/samlSettings';

import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextInput from 'next/input/Input.vue';
import TextArea from 'next/textarea/TextArea.vue';
import NextButton from 'next/button/Button.vue';
import SamlInfoSection from './SamlInfoSection.vue';
import SamlAttributeMap from './SamlAttributeMap.vue';

const METADATA_URL_TAB = 0;
const MANUAL_TAB = 1;

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const id = ref(null);
const fingerprint = ref('');
const spEntityId = ref('');
const isEnabled = ref(false);
const isSubmitting = ref(false);
const isLoading = ref(true);
const isRefreshing = ref(false);
const savedMetadataUrl = ref('');
const activeTab = ref(METADATA_URL_TAB);

const formState = reactive({
  metadataUrl: '',
  ssoUrl: '',
  certificate: '',
  idpEntityId: '',
});

const tabs = computed(() => [
  {
    label: t('SECURITY_SETTINGS.SAML.SOURCE.METADATA_URL'),
    index: METADATA_URL_TAB,
  },
  { label: t('SECURITY_SETTINGS.SAML.SOURCE.MANUAL'), index: MANUAL_TAB },
]);

// The server reads the identity provider fields from the metadata URL when one is set
const usesMetadataUrl = computed(() => activeTab.value === METADATA_URL_TAB);
const requiredWithMetadataUrl = requiredIf(usesMetadataUrl);
const requiredWithoutMetadataUrl = requiredIf(() => !usesMetadataUrl.value);

const validations = {
  metadataUrl: { required: requiredWithMetadataUrl },
  ssoUrl: { required: requiredWithoutMetadataUrl },
  certificate: { required: requiredWithoutMetadataUrl },
  idpEntityId: { required: requiredWithoutMetadataUrl },
};

const v$ = useVuelidate(validations, formState);

const hasFeature = computed(() => isCloudFeatureEnabled('saml'));

const metadataUrlError = computed(() =>
  v$.value.metadataUrl.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.METADATA_URL_ERROR')
    : ''
);

const ssoUrlError = computed(() =>
  v$.value.ssoUrl.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.SSO_URL_ERROR')
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

const setIdpFields = settings => {
  formState.metadataUrl = settings.metadata_url || '';
  savedMetadataUrl.value = formState.metadataUrl;
  formState.ssoUrl = settings.sso_url || '';
  formState.certificate = settings.certificate || '';
  formState.idpEntityId = settings.idp_entity_id || '';
  activeTab.value = formState.metadataUrl ? METADATA_URL_TAB : MANUAL_TAB;
};

const selectTab = tab => {
  activeTab.value = tab.index;
  v$.value.$reset();
};

const loadSamlSettings = async () => {
  if (!hasFeature.value) return;

  try {
    isLoading.value = true;
    const response = await samlSettingsAPI.get();
    const settings = response.data;

    if (settings.sso_url) {
      id.value = settings.id;
      setIdpFields(settings);
      spEntityId.value = settings.sp_entity_id || '';
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

    if (isEnabled.value && (formState.ssoUrl || formState.metadataUrl)) {
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
        setIdpFields(response.data);
        fingerprint.value = response.data.fingerprint || '';
        spEntityId.value = response.data.sp_entity_id || '';
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

const refreshMetadata = async () => {
  try {
    isRefreshing.value = true;
    const { data } = await samlSettingsAPI.refresh();
    setIdpFields(data);
    fingerprint.value = data.fingerprint || '';
    useAlert(t('SECURITY_SETTINGS.SAML.API.REFRESH_SUCCESS'));
  } catch (error) {
    useAlert(
      error.response?.data?.errors?.[0] ||
        t('SECURITY_SETTINGS.SAML.API.REFRESH_ERROR')
    );
  } finally {
    isRefreshing.value = false;
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const settings = usesMetadataUrl.value
    ? { metadata_url: formState.metadataUrl, role_mappings: {} }
    : {
        metadata_url: '',
        sso_url: formState.ssoUrl,
        certificate: formState.certificate,
        idp_entity_id: formState.idpEntityId,
        role_mappings: {},
      };

  await saveSamlSettings(settings);
};

const handleDisable = async () => {
  id.value = null;
  formState.metadataUrl = '';
  formState.ssoUrl = '';
  formState.certificate = '';
  spEntityId.value = '';
  formState.idpEntityId = '';
  activeTab.value = METADATA_URL_TAB;
  fingerprint.value = '';

  // the empty save will delete the SAML settings item
  await saveSamlSettings({});
};

const toggleSaml = async value => {
  isEnabled.value = value;
  if (!value) {
    await handleDisable();
  }
};

onMounted(() => {
  loadSamlSettings();
});
</script>

<template>
  <SettingsToggleSection
    :model-value="isEnabled"
    :header="t('SECURITY_SETTINGS.SAML.TITLE')"
    :description="t('SECURITY_SETTINGS.SAML.NOTE')"
    beta
    :hide-toggle="isLoading"
    @update:model-value="toggleSaml"
  >
    <template v-if="isLoading" #hiddenToggle>
      <Spinner class="size-4 text-n-slate-11" />
    </template>
    <template v-if="hasFeature && isEnabled && !isLoading" #editor>
      <SamlInfoSection
        class="mb-5"
        :fingerprint="fingerprint"
        :sp-entity-id="spEntityId"
      />
      <SamlAttributeMap class="mb-5" />

      <form class="grid gap-5" @submit.prevent="handleSubmit">
        <TabBar
          :tabs="tabs"
          :initial-active-tab="activeTab"
          @tab-changed="selectTab"
        />

        <WithLabel
          v-if="usesMetadataUrl"
          name="metadataUrl"
          :label="t('SECURITY_SETTINGS.SAML.METADATA_URL.LABEL')"
          :help-message="t('SECURITY_SETTINGS.SAML.METADATA_URL.HELP')"
          :has-error="v$.metadataUrl.$error"
          :error-message="metadataUrlError"
          required
        >
          <TextInput
            v-model.trim="formState.metadataUrl"
            class="w-full"
            type="url"
            :placeholder="t('SECURITY_SETTINGS.SAML.METADATA_URL.PLACEHOLDER')"
          />
        </WithLabel>

        <template v-else>
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
              :placeholder="
                t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.PLACEHOLDER')
              "
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
        </template>

        <div class="flex gap-2">
          <NextButton
            blue
            type="submit"
            :is-loading="isSubmitting"
            :label="t('SECURITY_SETTINGS.SAML.UPDATE_BUTTON')"
          />
          <NextButton
            v-if="usesMetadataUrl && savedMetadataUrl"
            slate
            faded
            type="button"
            :is-loading="isRefreshing"
            :label="t('SECURITY_SETTINGS.SAML.REFRESH_BUTTON')"
            @click="refreshMetadata"
          />
        </div>
      </form>
    </template>
  </SettingsToggleSection>
</template>
