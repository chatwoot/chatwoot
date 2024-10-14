<script setup>
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

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
  featureFlag: {
    type: String,
    default: null,
  },
});

const user = useMapGetter('getCurrentUser');
const isFeatureEnabled = useMapGetter('accounts/isFeatureEnabledonAccount');
const { accountId } = useAccount();

const userPermissions = computed(() => {
  return getUserPermissions(user.value, accountId.value);
});

const isFeatureAllowed = computed(() => {
  if (!props.featureFlag) return true;

  return isFeatureEnabled.value(accountId.value, props.featureFlag);
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
  <component :is="as" v-if="isFeatureAllowed && hasPermission">
    <slot />
  </component>
</template>
