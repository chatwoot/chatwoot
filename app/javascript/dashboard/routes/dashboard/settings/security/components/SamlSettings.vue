<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
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

const ssoUrl = ref('');
const certificate = ref('');
const fingerprint = ref('');
const spEntityId = ref('');
const roleMappings = ref({});
const isEnabled = ref(false);
const isSubmitting = ref(false);
const isLoading = ref(true);

const hasFeature = computed(() => isCloudFeatureEnabled('saml'));

const loadSamlSettings = async () => {
  if (!hasFeature.value) return;

  try {
    isLoading.value = true;
    const response = await samlSettingsAPI.get();
    const settings = response.data;

    if (settings.sso_url) {
      ssoUrl.value = settings.sso_url;
      certificate.value = settings.certificate || '';
      spEntityId.value = settings.sp_entity_id || '';
      roleMappings.value = settings.role_mappings || {};
      fingerprint.value = settings.fingerprint || '';
      isEnabled.value = ssoUrl.value !== '';
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

    if (isEnabled.value && ssoUrl.value) {
      // Create or update settings
      const existingSettings = await samlSettingsAPI.get().catch(() => null);

      if (existingSettings?.data?.id) {
        await samlSettingsAPI.update(settings);
      } else {
        await samlSettingsAPI.create(settings);
      }

      useAlert(t('SECURITY_SETTINGS.SAML.API.SUCCESS'));
    } else {
      // Disable/delete settings
      await samlSettingsAPI.delete();
      useAlert(t('SECURITY_SETTINGS.SAML.API.DISABLED'));
    }
  } catch (error) {
    useAlert(t('SECURITY_SETTINGS.SAML.API.ERROR'));
    throw error;
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (!ssoUrl.value || !certificate.value) {
    useAlert(t('SECURITY_SETTINGS.SAML.VALIDATION.REQUIRED_FIELDS'));
    return;
  }

  const settings = {
    sso_url: ssoUrl.value,
    certificate: certificate.value,
    sp_entity_id: spEntityId.value,
    role_mappings: roleMappings.value,
  };

  await saveSamlSettings(settings);
};

const handleDisable = async () => {
  ssoUrl.value = '';
  certificate.value = '';
  spEntityId.value = '';
  fingerprint.value = '';
  roleMappings.value = {};

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
    :hide-content="!hasFeature || !isEnabled || isLoading"
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

    <SamlInfoSection class="mb-5" :fingerprint="fingerprint" />
    <SamlAttributeMap class="mb-5" />

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        :label="t('SECURITY_SETTINGS.SAML.SSO_URL.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.SSO_URL.HELP')"
        required
      >
        <TextInput
          v-model="ssoUrl"
          class="w-full"
          type="url"
          :placeholder="t('SECURITY_SETTINGS.SAML.SSO_URL.PLACEHOLDER')"
          required
        />
      </WithLabel>

      <WithLabel
        :label="t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.HELP')"
      >
        <TextInput
          v-model="spEntityId"
          class="w-full"
          :placeholder="t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.PLACEHOLDER')"
        />
      </WithLabel>

      <WithLabel
        :label="t('SECURITY_SETTINGS.SAML.CERTIFICATE.LABEL')"
        :help-message="t('SECURITY_SETTINGS.SAML.CERTIFICATE.HELP')"
        required
      >
        <TextArea
          v-model="certificate"
          class="w-full"
          rows="8"
          :placeholder="t('SECURITY_SETTINGS.SAML.CERTIFICATE.PLACEHOLDER')"
          required
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
