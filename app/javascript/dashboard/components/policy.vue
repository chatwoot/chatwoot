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
});

const { checkFeatureAllowed, checkPermissions } = usePolicy();

const isFeatureAllowed = computed(() => checkFeatureAllowed(props.featureFlag));
const hasPermission = computed(() => checkPermissions(props.permissions));
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <component :is="as" v-if="isFeatureAllowed && hasPermission">
    <slot />
  </component>
</template>
