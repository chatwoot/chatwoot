<template>
  <div v-if="showBanner" class="bg-red-50 border-l-4 border-red-400 p-4 text-sm">
    <div class="flex items-start">
      <div class="flex-shrink-0">
        <i class="ri-alert-line text-red-400 text-lg"></i>
      </div>
      <div class="ml-3 flex-1">
        <h3 class="text-red-800 font-medium">WhatsApp Unofficial Connection Risk</h3>
        <p class="mt-1 text-red-700">
          This third-party WhatsApp integration carries a permanent risk of disruption. 
          WeaveCode recommends switching to the official WhatsApp Business API for reliability.
          API costs are your responsibility.
        </p>
        <div class="mt-3">
          <a 
            :href="faqUrl" 
            target="_blank"
            rel="noopener noreferrer"
            class="text-red-800 font-medium underline hover:text-red-900"
          >
            Learn about official WhatsApp API migration →
          </a>
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
  return props.channel.channel_type === 'Channel::Whatsapp' && 
         props.channel.provider !== 'whatsapp_cloud' &&
         props.channel.provider !== 'default'; // assuming 'default' is official
});
</script>