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

const { shouldShow } = usePolicy();

const show = computed(() =>
  shouldShow(props.featureFlag, props.permissions, props.installationTypes)
);

// const { checkFeatureAllowed, checkPermissions } = usePolicy();

// const isFeatureAllowed = computed(() => checkFeatureAllowed(props.featureFlag));
// const hasPermission = computed(() => checkPermissions(props.permissions));
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <!-- <component :is="as" v-if="isFeatureAllowed && hasPermission"> -->
  <!-- REVIEW:CV4.0.2 One of these condition should remain, room for refactoring -->
  <!-- REVIEW:CV4.0.2 commented out is the cv4.0.2 version -->
  <component :is="as" v-if="show">
    <slot />
  </component>
</template>
