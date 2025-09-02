<template>
  <div v-if="showBanner" class="sticky top-0 z-50 bg-red-600 border-b-2 border-red-800 p-4 text-sm shadow-lg">
    <div class="flex items-start">
      <div class="flex-shrink-0">
        <i class="ri-alert-fill text-white text-xl animate-pulse"></i>
      </div>
      <div class="ml-3 flex-1">
        <h3 class="text-white font-bold text-base">⚠️ PERMANENT RISK: Unofficial WhatsApp Connection</h3>
        <p class="mt-2 text-red-100 leading-relaxed">
          This third-party WhatsApp integration carries a <strong>permanent risk of service disruption</strong>. 
          Your WhatsApp business number could be suspended without notice. WeaveCode strongly recommends 
          migrating to the official WhatsApp Business Cloud API immediately for guaranteed reliability and compliance.
        </p>
        <div class="mt-3 flex items-center space-x-4">
          <a 
            :href="faqUrl" 
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center px-4 py-2 bg-white text-red-700 font-semibold rounded-md hover:bg-red-50 transition-colors duration-200"
          >
            <i class="ri-external-link-line mr-2"></i>
            Migration Guide & FAQ
          </a>
          <span class="text-red-200 text-xs font-medium">
            This warning cannot be dismissed until official API is connected
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  channel: {
    type: Object,
    default: null
  },
  faqUrl: {
    type: String,
    default: 'https://weavecode.co.uk/faq/whatsapp-official-api'
  }
});

const showBanner = computed(() => {
  if (!props.channel) return false;
  
  // Show banner if this is a WhatsApp channel using unofficial/third-party provider
  // 'default' provider is 360Dialog (unofficial), 'whatsapp_cloud' is official
  return props.channel.channel_type === 'Channel::Whatsapp' && 
         props.channel.provider !== 'whatsapp_cloud';
});
</script>