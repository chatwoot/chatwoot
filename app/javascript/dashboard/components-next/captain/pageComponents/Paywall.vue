<script setup>
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const emit = defineEmits(['upgrade']);
</script>

<template>
  <div
    class="w-full max-w-[960px] mx-auto h-full max-h-[448px] grid place-content-center"
  >
    <BasePaywallModal
      class="mx-auto"
      feature-prefix="CAPTAIN"
      i18n-key="PAYWALL"
      is-on-chatwoot-cloud
      @upgrade="emit('upgrade')"
    />
  </div>
</template>
