<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useCaptain } from 'dashboard/composables/useCaptain';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import ModelSelector from './components/ModelSelector.vue';
import FeatureToggle from './components/FeatureToggle.vue';

const { t } = useI18n();
const store = useStore();
const { captainEnabled } = useCaptain();

const uiFlags = useMapGetter('captainConfig/getUIFlags');
const features = useMapGetter('captainConfig/getFeatures');

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
  },
  {
    key: 'copilot',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.COPILOT.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.COPILOT.DESCRIPTION'),
  },
]);

const featureToggles = computed(() => [
  {
    key: 'audio_transcription',
    title: t('CAPTAIN_SETTINGS.FEATURES.AUDIO_TRANSCRIPTION.TITLE'),
    description: t('CAPTAIN_SETTINGS.FEATURES.AUDIO_TRANSCRIPTION.DESCRIPTION'),
  },
  {
    key: 'help_center_search',
    title: t('CAPTAIN_SETTINGS.FEATURES.HELP_CENTER_SEARCH.TITLE'),
    description: t('CAPTAIN_SETTINGS.FEATURES.HELP_CENTER_SEARCH.DESCRIPTION'),
  },
  {
    key: 'label_suggestion',
    title: t('CAPTAIN_SETTINGS.FEATURES.LABEL_SUGGESTION.TITLE'),
    description: t('CAPTAIN_SETTINGS.FEATURES.LABEL_SUGGESTION.DESCRIPTION'),
  },
]);

const hasFeatureToggle = key => {
  return features.value[key] !== undefined;
};

onMounted(() => {
  store.dispatch('captainConfig/fetch');
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="t('CAPTAIN_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('CAPTAIN_SETTINGS.TITLE')"
        :description="t('CAPTAIN_SETTINGS.DESCRIPTION')"
        icon-name="bot"
        feature-name="captain"
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
              :key="feature.key"
              :feature-key="feature.key"
              :title="feature.title"
              :description="feature.description"
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
              v-show="hasFeatureToggle(feature.key)"
              :key="feature.key"
              :feature-key="feature.key"
              :title="feature.title"
              :description="feature.description"
            />
          </div>
        </SectionLayout>
      </div>
      <div v-else class="text-n-slate-11 py-8 text-center">
        {{ t('CAPTAIN_SETTINGS.NOT_ENABLED') }}
      </div>
    </template>
  </SettingsLayout>
</template>
