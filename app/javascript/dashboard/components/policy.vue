<script setup>
import { usePolicy } from 'dashboard/composables/usePolicy';
import { computed } from 'vue';

const props = defineProps({
  as: {
    type: String,
    default: 'div',
  },
  permissions: {
    type: Array,
    required: true,
  },
  featureFlag: {
    type: String,
    default: null,
  },
  installationTypes: {
    type: Array,
    default: null,
  },
});

const {
  checkFeatureAllowed,
  checkPermissions,
  isPremiumFeature,
  checkInstallationType,
} = usePolicy();

const isFeatureFlagEnabled = computed(() =>
  checkFeatureAllowed(props.featureFlag)
);
const isPremium = computed(() => isPremiumFeature(props.featureFlag));
const hasPermission = computed(() => checkPermissions(props.permissions));
const matchesInstallationType = computed(() =>
  checkInstallationType(props.installationTypes)
);

const show = computed(
  () =>
    (isFeatureFlagEnabled.value || isPremium.value) &&
    hasPermission.value &&
    matchesInstallationType.value
);
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <component :is="as" v-if="show">
    <slot />
  </component>
</template>
