<script setup>
import { computed } from 'vue';

import MessageMeta from '../MessageMeta.vue';
import ReactionsBadge from '../ReactionsBadge.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION, SENDER_TYPES } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

const {
  variant,
  orientation,
  inReplyTo,
  shouldGroupWithNext,
  isPrivate,
  sender,
  senderType,
} = useMessageContext();
const { t } = useI18n();

// CUSTOMIZAÇÃO_SYNAPSEOS — paleta s-* aplicada aos variants de bubble.
// Notas privadas emitidas por AgentBot (Otto, Luís) ganham destaque visual próprio.
const isAgentBotNote = computed(() => {
  if (!isPrivate.value) return false;
  const senderKind = sender.value?.type ?? senderType.value;
  return senderKind === SENDER_TYPES.AGENT_BOT;
});

const agentBotName = computed(() => sender.value?.name ?? '');

const aiAriaLabel = computed(() =>
  t('CONVERSATION.PRIVATE_NOTE.AI_ARIA', { agent: agentBotName.value })
);

// CUSTOMIZAÇÃO_SYNAPSEOS — paleta Dexi aplicada aos bubbles.
// Agente = cyan-soft (identidade da plataforma, acessível, texto escuro).
// Cliente = surface branca com borda (estrutural, neutro).
// Nota privada = âmbar (destaque atenção).
// Bot/template = brand-soft com texto cyan-700 (semântica de AI).
// Activity = pill central neutra e visualmente rebaixada.
const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]:
    'bg-s-accent-100 text-s-primary border border-s-accent-500/20',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-s-warning-soft text-s-warning-text border border-s-warning/30 [&_.prosemirror-mention-node]:font-semibold',
  [MESSAGE_VARIANTS.USER]: 'bg-s-surface text-s-primary border border-s-border',
  [MESSAGE_VARIANTS.ACTIVITY]:
    'bg-s-subtle text-s-muted text-xs border border-s-border',
  [MESSAGE_VARIANTS.BOT]:
    'bg-s-brand-soft text-s-brand-text border border-s-accent-500/20',
  [MESSAGE_VARIANTS.TEMPLATE]:
    'bg-s-brand-soft text-s-brand-text border border-s-accent-500/20',
  [MESSAGE_VARIANTS.ERROR]:
    'bg-s-error-soft text-s-error-text border border-s-error/20',
  [MESSAGE_VARIANTS.EMAIL]: 'w-full',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-s-warning-soft/70 border border-dashed border-s-warning-text text-s-warning-text',
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
  const classToApply = [];

  if (isAgentBotNote.value) {
    // Softer amber + dashed amber border to separate AI notes from human ones.
    classToApply.push(
      'bg-n-amber-3 text-n-amber-12 border border-dashed border-n-amber-8 [&_.prosemirror-mention-node]:font-semibold'
    );
  } else {
    classToApply.push(varaintBaseMap[variant.value]);
  }

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

  if (content) return new MessageFormatter(content).formattedMessage;
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
    :role="isAgentBotNote ? 'note' : null"
    :aria-label="isAgentBotNote ? aiAriaLabel : null"
  >
    <div
      v-if="isAgentBotNote"
      class="flex items-center justify-between gap-2 mb-2 pb-2 border-b border-dashed border-n-amber-8/60"
    >
      <div
        class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-n-amber-5 text-n-amber-12 text-xs font-medium"
      >
        <span class="i-lucide-sparkles size-3" aria-hidden="true" />
        <span>
          {{
            $t('CONVERSATION.PRIVATE_NOTE.AI_BADGE', {
              agent: agentBotName,
            })
          }}
        </span>
      </div>
      <div
        class="inline-flex items-center gap-1 text-[11px] uppercase tracking-wide text-n-amber-11"
      >
        <span class="i-lucide-bot size-3" aria-hidden="true" />
        <span>{{ $t('CONVERSATION.PRIVATE_NOTE.AI_LABEL') }}</span>
      </div>
    </div>
    <div
      v-if="inReplyTo"
      class="p-2 -mx-1 mb-2 rounded-lg cursor-pointer bg-s-primary/10"
      @click="scrollToMessage"
    >
      <div
        v-dompurify-html="replyToPreview"
        class="prose prose-bubble line-clamp-2"
      />
    </div>
    <slot />
    <ReactionsBadge />
    <MessageMeta
      v-if="shouldShowMeta"
      :class="[
        flexOrientationClass,
        variant === MESSAGE_VARIANTS.EMAIL ? 'px-3 pb-3' : '',
        variant === MESSAGE_VARIANTS.PRIVATE
          ? 'text-s-warning-text/50'
          : 'text-s-muted',
      ]"
      class="mt-2"
    />
  </div>
</template>
