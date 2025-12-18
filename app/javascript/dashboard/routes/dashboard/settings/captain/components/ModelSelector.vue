<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  featureKey: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['change']);

const { t } = useI18n();
const isOpen = ref(false);

const getModelsForFeature = useMapGetter('captainConfig/getModelsForFeature');
const getDefaultModelForFeature = useMapGetter(
  'captainConfig/getDefaultModelForFeature'
);

const availableModels = computed(() =>
  getModelsForFeature.value(props.featureKey)
);
const defaultModel = computed(() =>
  getDefaultModelForFeature.value(props.featureKey)
);
const selectedModelId = ref(null);

watch(
  defaultModel,
  newDefault => {
    if (newDefault && !selectedModelId.value) {
      selectedModelId.value = newDefault;
    }
  },
  { immediate: true }
);

const selectedModelDetails = computed(() => {
  if (!selectedModelId.value) return null;
  return (
    availableModels.value.find(m => m.id === selectedModelId.value) || null
  );
});

const toggleDropdown = () => {
  isOpen.value = !isOpen.value;
};

const closeDropdown = () => {
  isOpen.value = false;
};

const selectModel = model => {
  selectedModelId.value = model.id;
  emit('change', { feature: props.featureKey, model: model.id });
  closeDropdown();
};

const getCreditLabel = model => {
  const multiplier = model.credit_multiplier || 1;
  return t('CAPTAIN_SETTINGS.MODEL_CONFIG.CREDITS_PER_MESSAGE', {
    credits: multiplier,
  });
};
</script>

<template>
  <div
    class="flex items-center justify-between gap-4 p-4 rounded-xl border border-n-weak bg-n-solid-1"
  >
    <div class="flex-1 min-w-0">
      <h4 class="text-sm font-medium text-n-slate-12">{{ title }}</h4>
      <p class="text-sm text-n-slate-11 mt-0.5">{{ description }}</p>
    </div>
    <div v-on-clickaway="closeDropdown" class="relative flex-shrink-0">
      <button
        type="button"
        class="flex items-center gap-2 px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 hover:bg-n-solid-3 min-w-[180px] justify-between"
        @click="toggleDropdown"
      >
        <span v-if="selectedModelDetails" class="text-n-slate-12">
          {{ selectedModelDetails.display_name }}
        </span>
        <span v-else class="text-n-slate-10">
          {{ t('CAPTAIN_SETTINGS.MODEL_CONFIG.SELECT_MODEL') }}
        </span>
        <Icon
          icon="i-lucide-chevron-down"
          class="size-4 text-n-slate-11 transition-transform"
          :class="{ 'rotate-180': isOpen }"
        />
      </button>
      <div
        v-if="isOpen"
        class="absolute right-0 z-50 w-56 mt-1 overflow-hidden border rounded-xl border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg"
      >
        <div class="py-1">
          <button
            v-for="model in availableModels"
            :key="model.id"
            type="button"
            class="flex flex-col w-full px-3 py-2 text-left hover:bg-n-alpha-1"
            :class="{
              'bg-n-alpha-2': selectedModelId === model.id,
            }"
            @click="selectModel(model)"
          >
            <span class="text-sm font-medium text-n-slate-12">
              {{ model.display_name }}
            </span>
            <span class="text-xs text-n-slate-11">
              {{ getCreditLabel(model) }}
            </span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
