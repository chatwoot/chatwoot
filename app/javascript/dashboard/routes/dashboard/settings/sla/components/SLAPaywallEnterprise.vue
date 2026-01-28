<script setup>
import BaseEmptyState from './BaseEmptyState.vue';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const props = defineProps({
  isSuperAdmin: {
    type: Boolean,
    default: false,
  },
  isOnDaxowCloud: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['upgrade']);
const i18nKey = props.isOnDaxowCloud ? 'PAYWALL' : 'ENTERPRISE_PAYWALL';
</script>

<template>
  <BaseEmptyState>
    <BasePaywallModal
      feature-prefix="SLA"
      :i18n-key="i18nKey"
      :is-on-chatwoot-cloud="isOnDaxowCloud"
      :is-super-admin="isSuperAdmin"
      @upgrade="emit('upgrade')"
    />
  </BaseEmptyState>
</template>
