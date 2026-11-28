<script setup>
import { computed, ref, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { getContrastingTextColor } from '@chatwoot/utils';
import CustomButton from 'shared/components/Button.vue';
import FooterReplyTo from 'widget/components/FooterReplyTo.vue';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { sendEmailTranscript } from 'widget/api/conversation';
import { useRouter } from 'vue-router';
import { IFrameHelper } from '../helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';
import { emitter } from 'shared/helpers/mitt';

const TRANSCRIPT_COOLDOWN_MS = 15000;

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const inReplyTo = ref(null);
const isSendingTranscript = ref(false);
const transcriptCooldown = ref(false);
let transcriptCooldownTimer = null;

const conversationAttributes = computed(
  () => store.getters['conversationAttributes/getConversationParams']
);
const widgetColor = computed(() => store.getters['appConfig/getWidgetColor']);
const conversationSize = computed(
  () => store.getters['conversation/getConversationSize']
);
const currentUser = computed(() => store.getters['contacts/getCurrentUser']);
const isWidgetStyleFlat = computed(
  () => store.getters['appConfig/isWidgetStyleFlat']
);
const textColor = computed(() => getContrastingTextColor(widgetColor.value));
const hideReplyBox = computed(() => {
  const { allowMessagesAfterResolved } = window.chatwootWebChannel;
  const { status } = conversationAttributes.value;
  return !allowMessagesAfterResolved && status === 'resolved';
});
const hasEmail = computed(
  () => currentUser.value && currentUser.value.has_email
);
const showEmailTranscriptButton = computed(() => hasEmail.value);
const hasReplyTo = computed(
  () =>
    inReplyTo.value && (inReplyTo.value.content || inReplyTo.value.attachments)
);

const handleSendMessage = async content => {
  await store.dispatch('conversation/sendMessage', {
    content,
    replyTo: inReplyTo.value ? inReplyTo.value.id : null,
  });
  // reset replyTo message after sending
  inReplyTo.value = null;
  // Update conversation attributes on new conversation
  if (conversationSize.value === 0) {
    store.dispatch('conversationAttributes/getAttributes');
  }
};

// A large file selection is sent as several messages; the later ones pass
// back the reply target returned here, since the preview clears after one.
// A reply picked while a later batch is still uploading stays in the preview.
const handleSendAttachment = async (
  attachment,
  replyTo = inReplyTo.value ? inReplyTo.value.id : null
) => {
  await store.dispatch('conversation/sendAttachment', { attachment, replyTo });
  if (inReplyTo.value?.id === replyTo) inReplyTo.value = null;
  return replyTo;
};

const startNewConversation = () => {
  router.replace({ name: 'prechat-form' });
  IFrameHelper.sendMessage({
    event: 'onEvent',
    eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
    data: { hasConversation: true },
  });
};

const toggleReplyTo = message => {
  inReplyTo.value = message;
};

const startTranscriptCooldown = () => {
  transcriptCooldown.value = true;
  clearTimeout(transcriptCooldownTimer);
  transcriptCooldownTimer = setTimeout(() => {
    transcriptCooldown.value = false;
  }, TRANSCRIPT_COOLDOWN_MS);
};

const sendTranscript = async () => {
  if (
    !hasEmail.value ||
    isSendingTranscript.value ||
    transcriptCooldown.value
  ) {
    return;
  }
  isSendingTranscript.value = true;
  try {
    await sendEmailTranscript();
    startTranscriptCooldown();
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'),
      type: 'success',
    });
  } catch (error) {
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'),
    });
  } finally {
    isSendingTranscript.value = false;
  }
};

onMounted(() => {
  emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, toggleReplyTo);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, toggleReplyTo);
  clearTimeout(transcriptCooldownTimer);
});
</script>

<template>
  <footer
    v-if="!hideReplyBox"
    class="relative z-50 mb-1"
    :class="{
      'rounded-lg': !isWidgetStyleFlat,
      'pt-2.5 shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.05)] dark:shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.15)] rounded-t-none':
        hasReplyTo,
    }"
  >
    <FooterReplyTo
      v-if="hasReplyTo"
      :in-reply-to="inReplyTo"
      @dismiss="inReplyTo = null"
    />
    <ChatInputWrap
      class="shadow-sm"
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
    />
  </footer>
  <div v-else>
    <CustomButton
      class="font-medium"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startNewConversation"
    >
      {{ $t('START_NEW_CONVERSATION') }}
    </CustomButton>
    <CustomButton
      v-if="showEmailTranscriptButton"
      type="clear"
      class="font-normal"
      :disabled="isSendingTranscript || transcriptCooldown"
      @click="sendTranscript"
    >
      {{ $t('EMAIL_TRANSCRIPT.BUTTON_TEXT') }}
    </CustomButton>
  </div>
</template>
