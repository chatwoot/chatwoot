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
  featureAccess: {
    type: String,
    default: null,
  },
});

const { shouldShow, checkFeatureAccess } = usePolicy();

const show = computed(
  () =>
    checkFeatureAccess(props.featureAccess) &&
    shouldShow(props.featureFlag, props.permissions, props.installationTypes)
);
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <component :is="as" v-if="show">
    <slot />
  </component>
</template>
