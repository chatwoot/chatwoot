<script setup>
import { computed } from 'vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import { IS_INSTAGRAM_WHATSAPP_INBOX_CREATION_DISABLED } from 'dashboard/constants/globals';

const hasWhatsappAppId = computed(() => {
  return (
    !IS_INSTAGRAM_WHATSAPP_INBOX_CREATION_DISABLED &&
    window.chatwootConfig?.whatsappAppId &&
    window.chatwootConfig.whatsappAppId !== 'none'
  );
});
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div class="px-6 py-5 rounded-2xl border border-n-weak">
      <WhatsappEmbeddedSignup
        v-if="hasWhatsappAppId"
        enable-calling-on-complete
      />
      <CloudWhatsapp v-else enable-calling-on-complete />
    </div>
  </div>
</template>
