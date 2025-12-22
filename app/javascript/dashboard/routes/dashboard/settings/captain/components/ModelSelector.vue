<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownBody from 'dashboard/components-next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'dashboard/components-next/dropdown-menu/base/DropdownItem.vue';
import { provideDropdownContext } from 'dashboard/components-next/dropdown-menu/base/provider.js';

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
const getSelectedModelForFeature = useMapGetter(
  'captainConfig/getSelectedModelForFeature'
);

const availableModels = computed(() =>
  getModelsForFeature.value(props.featureKey)
);
const selectedModel = computed(() =>
  getSelectedModelForFeature.value(props.featureKey)
);
const selectedModelId = ref(null);

watch(
  selectedModel,
  newSelected => {
    if (newSelected) {
      selectedModelId.value = newSelected;
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

const getCreditLabel = model => {
  const multiplier = model.credit_multiplier || 1;
  return t('CAPTAIN_SETTINGS.MODEL_CONFIG.CREDITS_PER_MESSAGE', {
    credits: multiplier,
  });
};

const toggleDropdown = () => {
  isOpen.value = !isOpen.value;
};

const closeDropdown = () => {
  isOpen.value = false;
};

provideDropdownContext({
  isOpen,
  toggle: () => toggleDropdown(),
  closeMenu: closeDropdown,
});

const selectModel = model => {
  selectedModelId.value = model.id;
  emit('change', { feature: props.featureKey, model: model.id });
  closeDropdown();
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
      <DropdownBody
        v-if="isOpen"
        class="absolute right-0 top-full mt-1 min-w-56 z-50"
      >
        <DropdownItem
          v-for="model in availableModels"
          :key="model.id"
          :click="() => selectModel(model)"
          class="rounded-lg hover:bg-n-alpha-1"
          :class="{ 'bg-n-alpha-2': selectedModelId === model.id }"
        >
          <div class="flex flex-col w-full text-left">
            <span class="text-sm font-medium text-n-slate-12">
              {{ model.display_name }}
            </span>
            <span class="text-xs text-n-slate-11">
              {{ getCreditLabel(model) }}
            </span>
          </div>
        </DropdownItem>
      </DropdownBody>
    </div>
  </div>
</template>
