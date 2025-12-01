<script setup>
import { computed } from 'vue';

import MessageMeta from '../MessageMeta.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

const { variant, orientation, inReplyTo, shouldGroupWithNext } =
  useMessageContext();
const { t } = useI18n();

const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]:
    'bg-[rgb(var(--bubble-agent-bg))] text-[rgb(var(--bubble-agent-text))]',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-[rgb(var(--bubble-private-bg))] text-[rgb(var(--bubble-private-text))] [&_.prosemirror-mention-node]:font-semibold',
  [MESSAGE_VARIANTS.USER]:
    'bg-[rgb(var(--bubble-user-bg))] text-[rgb(var(--bubble-user-text))]',
  [MESSAGE_VARIANTS.ACTIVITY]: 'bg-n-alpha-1 text-n-slate-11 text-sm',
  [MESSAGE_VARIANTS.BOT]:
    'bg-[rgb(var(--bubble-bot-bg))] text-[rgb(var(--bubble-bot-text))]',
  [MESSAGE_VARIANTS.TEMPLATE]:
    'bg-[rgb(var(--bubble-bot-bg))] text-[rgb(var(--bubble-bot-text))]',
  [MESSAGE_VARIANTS.ERROR]: 'bg-n-ruby-4 text-n-ruby-12',
  [MESSAGE_VARIANTS.EMAIL]: 'w-full',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-n-solid-amber/70 border border-dashed border-n-amber-12 text-n-amber-12',
};

const orientationMap = {
  [ORIENTATION.LEFT]:
    'left-bubble rounded-[var(--bubble-radius)] ltr:rounded-bl-[var(--bubble-radius-sm)] rtl:rounded-br-[var(--bubble-radius-sm)]',
  [ORIENTATION.RIGHT]:
    'right-bubble rounded-[var(--bubble-radius)] ltr:rounded-br-[var(--bubble-radius-sm)] rtl:rounded-bl-[var(--bubble-radius-sm)]',
  [ORIENTATION.CENTER]: 'rounded-[var(--bubble-radius-md)]',
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
    classToApply.push('rounded-[var(--bubble-radius-lg)]');
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

const metaColorClass = computed(() => {
  const metaClassMap = {
    [MESSAGE_VARIANTS.AGENT]: 'text-[rgb(var(--bubble-agent-meta))]',
    [MESSAGE_VARIANTS.USER]: 'text-[rgb(var(--bubble-user-meta))]',
    [MESSAGE_VARIANTS.PRIVATE]:
      'text-[rgb(var(--bubble-private-meta))] opacity-50',
    [MESSAGE_VARIANTS.BOT]: 'text-[rgb(var(--bubble-bot-meta))]',
    [MESSAGE_VARIANTS.TEMPLATE]: 'text-[rgb(var(--bubble-bot-meta))]',
    [MESSAGE_VARIANTS.EMAIL]: 'text-[rgb(var(--bubble-agent-meta))]',
  };
  return metaClassMap[variant.value] || 'text-[rgb(var(--bubble-agent-meta))]';
});

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
    class="text-sm"
    :class="[
      messageClass,
      {
        'max-w-lg': variant !== MESSAGE_VARIANTS.EMAIL,
      },
    ]"
  >
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
        metaColorClass,
      ]"
      class="mt-2"
    />
  </div>
</template>
