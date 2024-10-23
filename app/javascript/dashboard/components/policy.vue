<script setup>
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';
import {
  getUserPermissions,
  hasPermissions,
} from '../helper/permissionsHelper';

const props = defineProps({
  permissions: {
    type: Array,
    required: true,
  },
});

const getters = useStoreGetters();
const user = computed(() => getters.getCurrentUser.value);
const accountId = computed(() => getters.getCurrentAccountId.value);
const userPermissions = computed(() => {
  return getUserPermissions(user.value, accountId.value);
});
const hasPermission = computed(() => {
  return hasPermissions(props.permissions, userPermissions.value);
});
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <div v-if="hasPermission">
    <slot />
  </div>
</template>
