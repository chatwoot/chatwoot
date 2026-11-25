<script setup>
import { computed, onBeforeUnmount, ref } from 'vue';
import { I18nT, useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import { useInbox } from 'dashboard/composables/useInbox';
import { useAlert } from 'dashboard/composables';
import MessageApi from 'dashboard/api/inbox/message';
import BaseBubble from './Base.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const WHATSAPP_UNSUPPORTED_MESSAGE_HELP_URL =
  'https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users#linked-devices';

const { id, conversationId, inboxId, content, contentAttributes } =
  useMessageContext();
const { t } = useI18n();

const {
  isAFacebookInbox,
  isAnInstagramChannel,
  isATiktokChannel,
  isAWhatsAppCloudChannel,
} = useInbox(inboxId.value);

const isMasked = computed(() => !!contentAttributes.value?.isMasked);
const isViewOnce = computed(() => !!contentAttributes.value?.isViewOnce);
// Both are WhatsApp withholding the content from linked devices, which no other copy explains.
const isWithheld = computed(() => isMasked.value || isViewOnce.value);

// A file of an imported history arrives without its bytes. While it waits the bubble
// offers to fetch it; once the provider has said it no longer has it, the bubble says so
// instead of offering a download that cannot work. The file itself replaces this bubble
// when it lands, through the message update.
const isPendingHistoryFile = computed(
  () =>
    !!contentAttributes.value?.historyMedia &&
    !!contentAttributes.value?.pendingMedia
);
const isUnavailableHistoryFile = computed(
  () =>
    !contentAttributes.value?.historyMedia &&
    !!contentAttributes.value?.pendingMedia
);

// After a request is accepted the button rests for this long and then comes back: the
// download runs in the background, and one that fails for good while the provider is
// down leaves the file pending with nothing else to ask for it.
const RETRY_AFTER_MS = 2 * 60 * 1000;
const requesting = ref(false);
const requested = ref(false);
let retryTimer = null;
onBeforeUnmount(() => clearTimeout(retryTimer));
const fetchFile = async () => {
  requesting.value = true;
  try {
    await MessageApi.fetchMedia(conversationId.value, id.value);
    requested.value = true;
    clearTimeout(retryTimer);
    retryTimer = setTimeout(() => {
      requested.value = false;
    }, RETRY_AFTER_MS);
    useAlert(t('CONVERSATION.HISTORY_MEDIA.REQUESTED'));
  } catch (error) {
    useAlert(t('CONVERSATION.HISTORY_MEDIA.ERROR'));
  } finally {
    requesting.value = false;
  }
};

const unsupportedMessageKey = computed(() => {
  // WhatsApp withholds verification codes from linked devices: the row is empty
  // because the content never arrived, not because the type is unknown.
  if (isMasked.value) return 'CONVERSATION.MASKED_MESSAGE_WHATSAPP';
  if (isViewOnce.value) return 'CONVERSATION.VIEW_ONCE_MESSAGE_WHATSAPP';
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
    <!-- The caption is the readable part of a history file, and it outlives the file. -->
    <p
      v-if="(isPendingHistoryFile || isUnavailableHistoryFile) && content"
      class="mt-0 mb-2 whitespace-pre-wrap"
      data-history-media="caption"
    >
      {{ content }}
    </p>
    <div
      v-if="isPendingHistoryFile"
      class="flex flex-col items-start gap-2"
      data-history-media="pending"
    >
      <p class="m-0">{{ $t('CONVERSATION.HISTORY_MEDIA.PENDING') }}</p>
      <NextButton
        faded
        slate
        xs
        icon="i-lucide-download"
        :is-loading="requesting"
        :disabled="requesting || requested"
        :label="$t('CONVERSATION.HISTORY_MEDIA.DOWNLOAD')"
        @click="fetchFile"
      />
    </div>
    <p
      v-else-if="isUnavailableHistoryFile"
      class="m-0"
      data-history-media="unavailable"
    >
      {{ $t('CONVERSATION.HISTORY_MEDIA.UNAVAILABLE') }}
    </p>
    <!-- The Coexistence copy names Meta; a paired-session provider falls back to the generic text. -->
    <template v-else-if="isAWhatsAppCloudChannel && !isWithheld">
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
