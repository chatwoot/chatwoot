<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { storeToRefs } from 'pinia';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useConfig } from 'dashboard/composables/useConfig';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import ModelSelector from './components/ModelSelector.vue';
import FeatureToggle from './components/FeatureToggle.vue';
import CaptainPaywall from 'next/captain/pageComponents/Paywall.vue';

const { t } = useI18n();
const { captainEnabled } = useCaptain();
const { isEnterprise, enterprisePlanName } = useConfig();
const { isOnChatwootCloud } = useAccount();

const captainConfigStore = useCaptainConfigStore();
const { uiFlags } = storeToRefs(captainConfigStore);

const isLoading = computed(() => uiFlags.value.isFetching);

const modelFeatures = computed(() => [
  {
    key: 'editor',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.EDITOR.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.EDITOR.DESCRIPTION'),
  },
  {
    key: 'assistant',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.ASSISTANT.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.ASSISTANT.DESCRIPTION'),
    enterprise: true,
  },
  {
    key: 'copilot',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.COPILOT.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.COPILOT.DESCRIPTION'),
    enterprise: true,
  },
]);

const featureToggles = computed(() => [
  {
    key: 'label_suggestion',
  },
  {
    key: 'help_center_search',
    enterprise: true,
  },
  {
    key: 'audio_transcription',
    enterprise: true,
  },
]);

const shouldShowFeature = feature => {
  // Cloud will always see these features as long as captain is enabled
  if (isOnChatwootCloud.value && captainEnabled) {
    return true;
  }

  if (feature.enterprise) {
    // if the app is in enterprise mode, then we can show the feature
    // this is not the installation plan, but when the enterprise folder is missing
    return isEnterprise;
  }

  return true;
};

const isFeatureAccessible = feature => {
  // Cloud will always see these features as long as captain is enabled
  if (isOnChatwootCloud.value && captainEnabled) {
    return true;
  }

  if (feature.enterprise) {
    // plan is shown, but is it accessible?
    // This ensures that the instance has purchased the enterprise license, and only then we allow
    // access
    return isEnterprise && enterprisePlanName === 'enterprise';
  }

  return true;
};

async function handleFeatureToggle({ feature, enabled }) {
  try {
    await captainConfigStore.updatePreferences({
      captain_features: { [feature]: enabled },
    });
    useAlert(t('CAPTAIN_SETTINGS.API.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN_SETTINGS.API.ERROR'));
    captainConfigStore.fetch();
  }
}

async function handleModelChange({ feature, model }) {
  try {
    await captainConfigStore.updatePreferences({
      captain_models: { [feature]: model },
    });
    useAlert(t('CAPTAIN_SETTINGS.API.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN_SETTINGS.API.ERROR'));
    captainConfigStore.fetch();
  }
}

onMounted(() => {
  captainConfigStore.fetch();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :no-records-message="t('CAPTAIN_SETTINGS.NOT_ENABLED')"
    :loading-message="t('CAPTAIN_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('CAPTAIN_SETTINGS.TITLE')"
        :description="t('CAPTAIN_SETTINGS.DESCRIPTION')"
        :link-text="t('CAPTAIN_SETTINGS.LINK_TEXT')"
        icon-name="captain"
        feature-name="captain_billing"
      />
    </template>
    <template #body>
      <div v-if="captainEnabled" class="flex flex-col gap-1">
        <!-- Model Configuration Section -->
        <SectionLayout
          :title="t('CAPTAIN_SETTINGS.MODEL_CONFIG.TITLE')"
          :description="t('CAPTAIN_SETTINGS.MODEL_CONFIG.DESCRIPTION')"
        >
          <div class="grid gap-4">
            <ModelSelector
              v-for="feature in modelFeatures"
              v-show="shouldShowFeature(feature)"
              :key="feature.key"
              :is-allowed="isFeatureAccessible(feature)"
              :feature-key="feature.key"
              :title="feature.title"
              :description="feature.description"
              @change="handleModelChange"
            />
          </div>
        </SectionLayout>

        <!-- Features Section -->
        <SectionLayout
          :title="t('CAPTAIN_SETTINGS.FEATURES.TITLE')"
          :description="t('CAPTAIN_SETTINGS.FEATURES.DESCRIPTION')"
          with-border
        >
          <div class="grid gap-4">
            <FeatureToggle
              v-for="feature in featureToggles"
              v-show="shouldShowFeature(feature)"
              :key="feature.key"
              :is-allowed="isFeatureAccessible(feature)"
              :feature-key="feature.key"
              @change="handleFeatureToggle"
              @model-change="handleModelChange"
            />
          </div>
        </SectionLayout>
      </div>
      <div v-else>
        <CaptainPaywall />
      </div>
    </template>
  </SettingsLayout>
</template>
