<script setup>
import { computed } from 'vue';
import { I18nT } from 'vue-i18n';
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
  return 'CONVERSATION.UNSUPPORTED_MESSAGE';
});
</script>

<template>
  <BaseBubble class="px-4 py-3 text-sm" data-bubble-name="unsupported">
    <template v-if="isAWhatsAppChannel">
      <p class="m-0 font-semibold">
        {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE_WHATSAPP_TITLE') }}
      </p>
      <p class="mt-2 mb-0">
        {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE_WHATSAPP') }}
      </p>
      <I18nT
        keypath="CONVERSATION.UNSUPPORTED_MESSAGE_WHATSAPP_DETAILS"
        tag="p"
        scope="global"
        class="mt-2 mb-0"
      >
        <template #documentation>
          <a
            :href="WHATSAPP_UNSUPPORTED_MESSAGE_HELP_URL"
            target="_blank"
            rel="noopener noreferrer"
            class="text-current underline underline-offset-2 hover:no-underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
          >
            {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE_WHATSAPP_LEARN_MORE') }}
          </a>
        </template>
      </I18nT>
    </template>
    <p v-else class="m-0">{{ $t(unsupportedMessageKey) }}</p>
  </BaseBubble>
</template>
