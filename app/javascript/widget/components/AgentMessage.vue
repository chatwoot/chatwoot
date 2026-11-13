<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import UserMessage from 'widget/components/UserMessage.vue';
import AgentMessageBubble from 'widget/components/AgentMessageBubble.vue';
import MessageReplyButton from 'widget/components/MessageReplyButton.vue';
import { messageStamp } from 'shared/helpers/timeHelper';
import ImageBubble from 'widget/components/ImageBubble.vue';
import VideoBubble from 'widget/components/VideoBubble.vue';
import FileBubble from 'widget/components/FileBubble.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { isAutoTranslatedReply } from 'widget/helpers/translations';
import { isASubmittedFormMessage } from 'shared/helpers/MessageTypeHelper';
import ReplyToChip from 'widget/components/ReplyToChip.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

const props = defineProps({
  message: {
    type: Object,
    default: () => ({}),
  },
  replyTo: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const failedAttachmentIds = ref({});
const channelConfig = computed(() => window.chatwootWebChannel);
const useInboxAvatarForBot = computed(() =>
  channelConfig.value.enabledFeatures.includes('use_inbox_avatar_for_bot')
);
const messageContentAttributes = computed(() => {
  const { content_attributes: attributes = {} } = props.message;
  return attributes;
});
const hasAttachments = computed(() => !!props.message.attachments?.length);
const contentType = computed(() => props.message.content_type ?? '');
const messageType = computed(() => props.message.message_type ?? 1);
const shouldDisplayAgentMessage = computed(() => {
  if (
    contentType.value === 'input_select' &&
    messageContentAttributes.value.submitted_values &&
    !props.message.content
  ) {
    return false;
  }
  return props.message.content;
});
const readableTime = computed(() => {
  const { created_at: createdAt = '' } = props.message;
  return messageStamp(createdAt, 'LLL d yyyy, h:mm a');
});
const agentName = computed(() => {
  if (props.message.sender) {
    return props.message.sender.available_name || props.message.sender.name;
  }
  if (props.message.additional_attributes?.sender_name) {
    return props.message.additional_attributes.sender_name;
  }
  if (useInboxAvatarForBot.value) {
    return channelConfig.value.websiteName;
  }
  return t('UNREAD_VIEW.BOT');
});
const avatarUrl = computed(() => {
  const displayImage = useInboxAvatarForBot.value
    ? channelConfig.value.avatarUrl
    : '/assets/images/chatwoot_bot.png';

  if (props.message.message_type === MESSAGE_TYPE.TEMPLATE) {
    return displayImage;
  }
  if (props.message.sender) {
    return props.message.sender.avatar_url;
  }
  return props.message.additional_attributes?.sender_avatar_url || displayImage;
});
const hasRecordedResponse = computed(
  () =>
    messageContentAttributes.value.submitted_email ||
    (messageContentAttributes.value.submitted_values &&
      !['form', 'input_csat'].includes(contentType.value))
);
const responseMessage = computed(() => {
  if (messageContentAttributes.value.submitted_email) {
    return { content: messageContentAttributes.value.submitted_email };
  }
  if (
    messageContentAttributes.value.submitted_values &&
    contentType.value === 'input_select'
  ) {
    const [selectionOption = {}] =
      messageContentAttributes.value.submitted_values;
    return { content: selectionOption.title || selectionOption.value };
  }
  return '';
});
const isASubmittedForm = computed(() => isASubmittedFormMessage(props.message));
const submittedFormValues = computed(() =>
  messageContentAttributes.value.submitted_values.map(submittedValue => ({
    id: submittedValue.name,
    content: submittedValue.value,
  }))
);
const wrapClass = computed(() => ({
  'has-text': shouldDisplayAgentMessage.value,
}));
const hasReplyTo = computed(
  () => props.replyTo && (props.replyTo.content || props.replyTo.attachments)
);
const isAwaitingTranslation = computed(
  () => !!messageContentAttributes.value.translation_pending
);
const isAutoTranslated = computed(() => isAutoTranslatedReply(props.message));

watch(
  () => props.message,
  () => {
    failedAttachmentIds.value = {};
  }
);

const onMediaLoadError = attachmentId => {
  failedAttachmentIds.value[attachmentId] = true;
};
const toggleReply = () => {
  emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, props.message);
};
</script>

<template>
  <div
    class="agent-message-wrap group"
    :class="{
      'has-response': hasRecordedResponse || isASubmittedForm,
    }"
  >
    <div v-if="!isASubmittedForm" class="agent-message">
      <div class="avatar-wrap">
        <div class="user-thumbnail-box">
          <Avatar
            v-if="message.showAvatar || hasRecordedResponse"
            :src="avatarUrl"
            :size="24"
            :name="agentName"
            rounded-full
          />
        </div>
      </div>
      <div class="message-wrap">
        <div v-if="hasReplyTo" class="flex mt-2 mb-1 text-xs">
          <ReplyToChip :reply-to="replyTo" />
        </div>
        <div class="flex w-full gap-1">
          <div
            class="space-y-2"
            :class="{
              'w-full':
                contentType === 'form' &&
                !messageContentAttributes?.submitted_values,
            }"
          >
            <AgentMessageBubble
              v-if="shouldDisplayAgentMessage"
              :content-type="contentType"
              :message-content-attributes="messageContentAttributes"
              :message-id="message.id"
              :message-type="messageType"
              :message="message.content"
              :translating="isAwaitingTranslation"
              :translated="isAutoTranslated"
            />
            <div
              v-if="hasAttachments"
              class="space-y-2 chat-bubble has-attachment agent bg-n-background dark:bg-n-solid-3"
              :class="wrapClass"
            >
              <div
                v-for="attachment in message.attachments"
                :key="attachment.id"
              >
                <ImageBubble
                  v-if="
                    attachment.file_type === 'image' &&
                    !failedAttachmentIds[attachment.id]
                  "
                  :url="attachment.data_url"
                  :thumb="attachment.data_url"
                  :readable-time="readableTime"
                  @error="onMediaLoadError(attachment.id)"
                />

                <VideoBubble
                  v-else-if="
                    attachment.file_type === 'video' &&
                    !failedAttachmentIds[attachment.id]
                  "
                  :url="attachment.data_url"
                  :readable-time="readableTime"
                  @error="onMediaLoadError(attachment.id)"
                />

                <audio
                  v-else-if="attachment.file_type === 'audio'"
                  controls
                  class="h-10 dark:invert"
                >
                  <source :src="attachment.data_url" />
                </audio>
                <FileBubble v-else :url="attachment.data_url" />
              </div>
            </div>
          </div>
          <div class="flex flex-col justify-end">
            <MessageReplyButton
              class="transition-opacity delay-75 opacity-0 group-hover:opacity-100 sm:opacity-0"
              @click="toggleReply"
            />
          </div>
        </div>
        <p
          v-if="message.showAvatar || hasRecordedResponse"
          class="agent-name text-n-slate-11"
        >
          {{ agentName }}
        </p>
      </div>
    </div>

    <UserMessage v-if="hasRecordedResponse" :message="responseMessage" />
    <div v-if="isASubmittedForm">
      <UserMessage
        v-for="submittedValue in submittedFormValues"
        :key="submittedValue.id"
        :message="submittedValue"
      />
    </div>
  </div>
</template>
