<script setup>
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';
import { hasPermissions } from '../helper/permissionsHelper';
const props = defineProps({
  permissions: {
    type: Array,
    required: true,
  },
});

const getters = useStoreGetters();
const user = getters.getCurrentUser.value;
const hasPermission = computed(() =>
  hasPermissions(props.permissions, user.permissions)
);
</script>

<template>
  <div v-if="hasPermission">
    <slot />
  </div>
</template>
