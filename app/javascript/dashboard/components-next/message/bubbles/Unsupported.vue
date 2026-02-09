<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import { useInbox } from 'dashboard/composables/useInbox';
import BaseBubble from './Base.vue';

const { inboxId } = useMessageContext();

const { isAFacebookInbox, isAnInstagramChannel, isATiktokChannel } = useInbox(
  inboxId.value
);

const unsupportedMessageKey = computed(() => {
  if (isAFacebookInbox.value)
    return 'CONVERSATION.UNSUPPORTED_MESSAGE_FACEBOOK';
  if (isAnInstagramChannel.value)
    return 'CONVERSATION.UNSUPPORTED_MESSAGE_INSTAGRAM';
  if (isATiktokChannel.value) return 'CONVERSATION.UNSUPPORTED_MESSAGE_TIKTOK';
  return 'CONVERSATION.UNSUPPORTED_MESSAGE';
});
</script>

<template>
  <BaseBubble
    class="px-[var(--bubble-padding-x)] py-[var(--bubble-padding-y)] text-sm"
    data-bubble-name="unsupported"
  >
    {{ $t(unsupportedMessageKey) }}
  </BaseBubble>
</template>
