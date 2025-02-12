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

const { checkFeatureAllowed, checkPermissions, checkInstallationType } =
  usePolicy();

const isFeatureAllowed = computed(() => checkFeatureAllowed(props.featureFlag));
const hasPermission = computed(() => checkPermissions(props.permissions));
const matchesInstallationType = computed(() =>
  checkInstallationType(props.installationTypes)
);
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <component
    :is="as"
    v-if="isFeatureAllowed && hasPermission && matchesInstallationType"
  >
    <slot />
  </component>
</template>
