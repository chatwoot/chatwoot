<script setup>
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';
import {
  getUserPermissions,
  hasPermissions,
} from '../helper/permissionsHelper';

const props = defineProps({
  as: {
    type: String,
    default: 'div',
  },
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
  if (!props.permissions || !props.permissions.length) {
    return true;
  }

  return hasPermissions(props.permissions, userPermissions.value);
});
</script>

<!-- eslint-disable vue/no-root-v-if -->
<template>
  <component :is="as" v-if="hasPermission">
    <slot />
  </component>
</template>
