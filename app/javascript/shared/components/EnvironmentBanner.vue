<template>
  <div v-if="isStaging" class="bg-amber-600 text-white text-sm px-4 py-2 text-centre font-medium">
    <div class="flex items-centre justify-centre gap-2">
      <i class="ri-alert-line"></i>
      <span>STAGING Environment - Data may be reset without notice</span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const isStaging = computed(() => {
  return window.chatwootConfig?.railsEnv === 'staging' || 
         window.location.hostname.includes('staging');
});
</script>