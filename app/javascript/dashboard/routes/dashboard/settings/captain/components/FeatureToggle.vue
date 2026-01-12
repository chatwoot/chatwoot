<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { storeToRefs } from 'pinia';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import ModelDropdown from './ModelDropdown.vue';

const props = defineProps({
  featureKey: {
    type: String,
    required: true,
  },
  isAllowed: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(['change', 'modelChange']);

const { t } = useI18n();
const captainConfigStore = useCaptainConfigStore();
const { features } = storeToRefs(captainConfigStore);

const availableModels = computed(() =>
  captainConfigStore.getModelsForFeature(props.featureKey)
);

const isEnabled = ref(false);

const featureConfig = computed(() => features.value[props.featureKey]);

const hasMultipleModels = computed(() => {
  return availableModels.value && availableModels.value.length > 1;
});

const showModelSelector = computed(() => {
  return isEnabled.value && hasMultipleModels.value;
});

const title = computed(() => {
  if (props.featureKey.toUpperCase() === 'AUDIO_TRANSCRIPTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.AUDIO_TRANSCRIPTION.TITLE');
  }
  if (props.featureKey.toUpperCase() === 'HELP_CENTER_SEARCH') {
    return t('CAPTAIN_SETTINGS.FEATURES.HELP_CENTER_SEARCH.TITLE');
  }
  if (props.featureKey.toUpperCase() === 'LABEL_SUGGESTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.LABEL_SUGGESTION.TITLE');
  }
  return '';
});

const description = computed(() => {
  if (props.featureKey.toUpperCase() === 'AUDIO_TRANSCRIPTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.AUDIO_TRANSCRIPTION.DESCRIPTION');
  }
  if (props.featureKey.toUpperCase() === 'HELP_CENTER_SEARCH') {
    return t('CAPTAIN_SETTINGS.FEATURES.HELP_CENTER_SEARCH.DESCRIPTION');
  }
  if (props.featureKey.toUpperCase() === 'LABEL_SUGGESTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.LABEL_SUGGESTION.DESCRIPTION');
  }
  return '';
});

const modelTitle = computed(() => {
  if (props.featureKey.toUpperCase() === 'AUDIO_TRANSCRIPTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.AUDIO_TRANSCRIPTION.MODEL_TITLE');
  }
  if (props.featureKey.toUpperCase() === 'HELP_CENTER_SEARCH') {
    return t('CAPTAIN_SETTINGS.FEATURES.HELP_CENTER_SEARCH.MODEL_TITLE');
  }
  if (props.featureKey.toUpperCase() === 'LABEL_SUGGESTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.LABEL_SUGGESTION.MODEL_TITLE');
  }
  return '';
});

const modelDescription = computed(() => {
  if (props.featureKey.toUpperCase() === 'AUDIO_TRANSCRIPTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.AUDIO_TRANSCRIPTION.MODEL_DESCRIPTION');
  }
  if (props.featureKey.toUpperCase() === 'HELP_CENTER_SEARCH') {
    return t('CAPTAIN_SETTINGS.FEATURES.HELP_CENTER_SEARCH.MODEL_DESCRIPTION');
  }
  if (props.featureKey.toUpperCase() === 'LABEL_SUGGESTION') {
    return t('CAPTAIN_SETTINGS.FEATURES.LABEL_SUGGESTION.MODEL_DESCRIPTION');
  }
  return '';
});

watch(
  featureConfig,
  newConfig => {
    if (newConfig !== undefined) {
      isEnabled.value = !!newConfig.enabled;
    }
  },
  { immediate: true }
);

const toggleFeature = () => {
  emit('change', { feature: props.featureKey, enabled: isEnabled.value });
};

const handleModelChange = ({ feature, model }) => {
  emit('modelChange', { feature, model });
};
</script>

<template>
  <div
    class="p-4 rounded-xl border border-n-weak bg-n-solid-1 flex"
    :class="{
      'flex-col gap-3': showModelSelector,
      'items-center justify-between gap-4': !showModelSelector,
      'opacity-60 pointer-events-none': !isAllowed,
    }"
  >
    <div class="flex items-center justify-between gap-4 flex-1">
      <div class="flex-1 min-w-0">
        <h4 class="text-sm font-medium text-n-slate-12">{{ title }}</h4>
        <p class="text-sm text-n-slate-11 mt-0.5">{{ description }}</p>
      </div>
      <div v-if="isAllowed" class="flex-shrink-0">
        <Switch v-model="isEnabled" @change="toggleFeature" />
      </div>
    </div>
    <div
      v-if="showModelSelector && isAllowed"
      class="flex gap-2 ps-8 model-selector-item"
    >
      <div class="flex-1 min-w-0">
        <h4 class="text-sm font-medium text-n-slate-12">{{ modelTitle }}</h4>
        <p class="text-sm text-n-slate-11 mt-0.5">{{ modelDescription }}</p>
      </div>
      <div class="flex justify-end">
        <ModelDropdown :feature-key="featureKey" @change="handleModelChange" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.model-selector-item {
  position: relative;
}

.model-selector-item::before {
  content: '';
  position: absolute;
  width: 0.125rem;
  height: 50%;
  top: 0;
  left: 0.75rem;
  @apply border-n-weak bg-n-weak;
}

.model-selector-item::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 12px;
  top: calc(50% - 6px);
  left: 0.75rem;
  border-bottom-width: 0.125rem;
  border-left-width: 0.125rem;
  border-right-width: 0px;
  border-top-width: 0px;
  border-radius: 0 0 0 4px;
  @apply border-n-weak;
}

#app[dir='rtl'] .model-selector-item::before {
  left: auto;
  right: 0.75rem;
}

#app[dir='rtl'] .model-selector-item::after {
  left: auto;
  right: 0.75rem;
  border-left-width: 0px;
  border-right-width: 0.125rem;
  border-radius: 0 0 4px 0;
}
</style>
