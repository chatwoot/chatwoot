<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownBody from 'dashboard/components-next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'dashboard/components-next/dropdown-menu/base/DropdownItem.vue';
import { provideDropdownContext } from 'dashboard/components-next/dropdown-menu/base/provider.js';

const props = defineProps({
  featureKey: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['change']);
const { isOnChatwootCloud } = useAccount();

const PROVIDER_ICONS = {
  openai: 'i-ri-openai-fill',
  anthropic: 'i-ri-anthropic-line',
  mistral: 'i-logos-mistral-icon',
  gemini: 'i-woot-gemini',
};

const iconForModel = model => {
  return PROVIDER_ICONS[model.provider];
};

const { t } = useI18n();
const captainConfigStore = useCaptainConfigStore();
const isOpen = ref(false);

const availableModels = computed(() =>
  captainConfigStore.getModelsForFeature(props.featureKey)
);

const recommendedModelId = computed(() =>
  captainConfigStore.getDefaultModelForFeature(props.featureKey)
);

const selectedModel = computed(() =>
  captainConfigStore.getSelectedModelForFeature(props.featureKey)
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
  <div v-on-clickaway="closeDropdown" class="relative flex-shrink-0">
    <button
      type="button"
      class="flex items-center gap-2 px-3 py-2 text-sm border rounded-lg border-n-weak dark:bg-n-solid-2 dark:hover:bg-n-solid-3 bg-n-alpha-2 hover:bg-n-alpha-1 min-w-[180px] justify-between"
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
      class="absolute right-0 top-full mt-1 min-w-64 z-50 max-h-96 [&>ul]:max-h-96 [&>ul]:overflow-y-scroll"
    >
      <DropdownItem
        v-for="model in availableModels"
        :key="model.id"
        :click="() => selectModel(model)"
        class="rounded-lg dark:hover:bg-n-solid-3 hover:bg-n-alpha-1"
        :class="{
          'dark:bg-n-solid-3 bg-n-alpha-1': selectedModelId === model.id,
          'pointer-events-none opacity-60': model.coming_soon,
        }"
      >
        <div class="flex gap-2 w-full">
          <Icon :icon="iconForModel(model)" class="size-4 flex-shrink-0" />
          <div class="flex flex-col w-full text-left gap-1">
            <div
              class="text-sm w-full font-medium leading-none text-n-slate-12 flex items-baseline justify-between"
            >
              {{ model.display_name }}
              <span
                v-if="model.id === recommendedModelId"
                class="text-[10px] uppercase text-n-iris-11 border border-1 border-n-iris-10 leading-none rounded-lg px-1 py-0.5"
              >
                {{ t('GENERAL.PREFERRED') }}
              </span>
            </div>
            <span v-if="model.coming_soon" class="text-xs text-n-slate-11">
              {{ t('CAPTAIN_SETTINGS.MODEL_CONFIG.COMING_SOON') }}
            </span>
            <span v-else-if="isOnChatwootCloud" class="text-xs text-n-slate-11">
              {{ getCreditLabel(model) }}
            </span>
          </div>
        </div>
      </DropdownItem>
    </DropdownBody>
  </div>
</template>
