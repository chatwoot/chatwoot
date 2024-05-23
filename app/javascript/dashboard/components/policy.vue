<script setup>
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';

const props = defineProps({
  permissions: {
    type: Array,
    required: true,
  },
});

const getters = useStoreGetters();
const user = getters.getCurrentUser();

const hasPermission = computed(() =>
  props.permissions.some(permission => user.permissions.includes(permission))
);
</script>

<template>
  <div v-if="hasPermission">
    <slot />
  </div>
</template>
