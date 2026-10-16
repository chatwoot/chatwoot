<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import { useInbox } from 'dashboard/composables/useInbox';
import BaseBubble from './Base.vue';

const WHATSAPP_UNSUPPORTED_MESSAGE_HELP_URL =
  'https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users#linked-devices';

const { inboxId } = useMessageContext();

const {
  isAFacebookInbox,
  isAnInstagramChannel,
  isATiktokChannel,
  isAWhatsAppChannel,
} = useInbox(inboxId.value);

const unsupportedMessageKey = computed(() => {
  if (isAFacebookInbox.value)
    return 'CONVERSATION.UNSUPPORTED_MESSAGE_FACEBOOK';
  if (isAnInstagramChannel.value)
    return 'CONVERSATION.UNSUPPORTED_MESSAGE_INSTAGRAM';
  if (isATiktokChannel.value) return 'CONVERSATION.UNSUPPORTED_MESSAGE_TIKTOK';
  if (isAWhatsAppChannel.value)
    return 'CONVERSATION.UNSUPPORTED_MESSAGE_WHATSAPP';
  return 'CONVERSATION.UNSUPPORTED_MESSAGE';
});
</script>

<template>
  <BaseBubble class="px-4 py-3 text-sm" data-bubble-name="unsupported">
    <p class="m-0">{{ $t(unsupportedMessageKey) }}</p>
    <a
      v-if="isAWhatsAppChannel"
      :href="WHATSAPP_UNSUPPORTED_MESSAGE_HELP_URL"
      target="_blank"
      rel="noopener noreferrer"
      class="inline-flex items-center gap-1 mt-2 text-xs text-current underline underline-offset-2 hover:no-underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
    >
      {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE_WHATSAPP_LEARN_MORE') }}
      <span class="i-lucide-external-link size-3" aria-hidden="true" />
    </a>
  </BaseBubble>
</template>
