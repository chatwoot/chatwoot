<script setup>
import { computed, ref } from 'vue';

import MessageMeta from '../MessageMeta.vue';
import ApplePayloadModal from '../modals/ApplePayloadModal.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION, MESSAGE_TYPES } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

const {
  variant,
  orientation,
  inReplyTo,
  shouldGroupWithNext,
  messageType,
  id, // eslint-disable-line no-unused-vars
  inboxId,
  appleMspPayload,
  status,
  contentAttributes,
} = useMessageContext();
const { t } = useI18n();

const getInbox = useMapGetter('inboxes/getInbox');
const inbox = computed(() => getInbox.value(inboxId.value));

const showPayloadModal = ref(false);

const isAppleMessagesChannel = computed(() => {
  return inbox.value?.channel_type === 'Channel::AppleMessagesForBusiness';
});

const hasApplePayloadData = computed(() => {
  return (
    isAppleMessagesChannel.value &&
    (appleMspPayload.value || contentAttributes.value)
  );
});

const openPayloadModal = () => {
  showPayloadModal.value = true;
};

const closePayloadModal = () => {
  showPayloadModal.value = false;
};

const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]: 'bg-n-solid-blue text-n-slate-12',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-n-solid-amber text-n-amber-12 [&_.prosemirror-mention-node]:font-semibold',
  [MESSAGE_VARIANTS.USER]: 'bg-n-slate-4 text-n-slate-12',
  [MESSAGE_VARIANTS.ACTIVITY]: 'bg-n-alpha-1 text-n-slate-11 text-sm',
  [MESSAGE_VARIANTS.BOT]: 'bg-n-solid-iris text-n-slate-12',
  [MESSAGE_VARIANTS.TEMPLATE]: 'bg-n-solid-iris text-n-slate-12',
  [MESSAGE_VARIANTS.ERROR]: 'bg-n-ruby-4 text-n-ruby-12',
  [MESSAGE_VARIANTS.EMAIL]: 'w-full',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-n-solid-amber/70 border border-dashed border-n-amber-12 text-n-amber-12',
};

const orientationMap = {
  [ORIENTATION.LEFT]:
    'left-bubble rounded-xl ltr:rounded-bl-sm rtl:rounded-br-sm',
  [ORIENTATION.RIGHT]:
    'right-bubble rounded-xl ltr:rounded-br-sm rtl:rounded-bl-sm',
  [ORIENTATION.CENTER]: 'rounded-md',
};

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap[variant.value]];

  if (variant.value !== MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push(orientationMap[orientation.value]);
  } else {
    classToApply.push('rounded-lg');
  }

  return classToApply;
});

const scrollToMessage = () => {
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, {
    messageId: inReplyTo.value.id,
  });
};

const shouldShowMeta = computed(
  () =>
    !props.hideMeta &&
    !shouldGroupWithNext.value &&
    variant.value !== MESSAGE_VARIANTS.ACTIVITY
);

const replyToPreview = computed(() => {
  if (!inReplyTo) return '';

  const { content, attachments } = inReplyTo.value;

  if (content) return content;
  if (attachments?.length) {
    const firstAttachment = attachments[0];
    const fileType = firstAttachment.fileType ?? firstAttachment.file_type;

    return t(`CHAT_LIST.ATTACHMENTS.${fileType}.CONTENT`);
  }

  return t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND');
});
</script>

<template>
  <div
    class="text-sm relative"
    :class="[
      messageClass,
      {
        'max-w-lg': variant !== MESSAGE_VARIANTS.EMAIL,
      },
    ]"
  >
    <button
      v-if="hasApplePayloadData"
      v-tooltip.top-start="'View Apple Messages payload'"
      class="absolute top-1 ltr:right-1 rtl:left-1 z-10 p-1 rounded-full bg-n-alpha-2 hover:bg-n-alpha-3 transition-colors"
      @click.stop="openPayloadModal"
    >
      <fluent-icon icon="info" size="14" class="text-n-slate-11" />
    </button>
    <div
      v-if="inReplyTo"
      class="p-2 -mx-1 mb-2 rounded-lg cursor-pointer bg-n-alpha-black1"
      @click="scrollToMessage"
    >
      <span class="break-all line-clamp-2">
        {{ replyToPreview }}
      </span>
    </div>
    <slot />
    <MessageMeta
      v-if="shouldShowMeta"
      :class="[
        flexOrientationClass,
        variant === MESSAGE_VARIANTS.EMAIL ? 'px-3 pb-3' : '',
        variant === MESSAGE_VARIANTS.PRIVATE
          ? 'text-n-amber-12/50'
          : 'text-n-slate-11',
      ]"
      class="mt-2"
    />
    <Teleport to="body">
      <ApplePayloadModal
        v-model:show="showPayloadModal"
        :payload="appleMspPayload"
        :status="status"
        :content-attributes="contentAttributes"
        @close="closePayloadModal"
      />
    </Teleport>
  </div>
</template>
