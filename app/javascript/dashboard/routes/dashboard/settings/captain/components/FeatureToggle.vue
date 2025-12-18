<script setup>
import { ref, computed, watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import Switch from 'dashboard/components-next/switch/Switch.vue';

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

const features = useMapGetter('captainConfig/getFeatures');

const isEnabled = ref(false);

const featureConfig = computed(() => features.value[props.featureKey]);

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
</script>

<template>
  <div
    class="flex items-center justify-between gap-4 p-4 rounded-xl border border-n-weak bg-n-solid-1"
  >
    <div class="flex-1 min-w-0">
      <h4 class="text-sm font-medium text-n-slate-12">{{ title }}</h4>
      <p class="text-sm text-n-slate-11 mt-0.5">{{ description }}</p>
    </div>
    <div class="flex-shrink-0">
      <Switch v-model="isEnabled" @change="toggleFeature" />
    </div>
  </div>
</template>
