<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../../provider.js';
import { useFunctionGetter } from 'dashboard/composables/store';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../../constants';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const { t, locale } = useI18n();

const {
  variant,
  contentAttributes,
  shouldGroupWithNext,
  additionalAttributes,
  sender,
  currentUserId,
} = useMessageContext();

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
});

// Show edited indicator inline when meta is hidden (grouped messages)
const isEdited = computed(() => {
  return contentAttributes.value?.isEdited === true;
});

const previousContent = computed(() => {
  return contentAttributes.value?.previousContent || '';
});

const shouldShowEditedIndicator = computed(() => {
  return isEdited.value && shouldGroupWithNext.value;
});

// Scheduled message indicator
const isScheduledMessage = computed(
  () => !!additionalAttributes.value?.scheduledMessageId
);
const scheduledBy = computed(() => additionalAttributes.value?.scheduledBy);
const scheduledById = computed(() => scheduledBy.value?.id);
const scheduledByType = computed(() =>
  scheduledBy.value?.type ? String(scheduledBy.value.type) : ''
);
const scheduledByTypeNormalized = computed(() =>
  scheduledByType.value.toLowerCase()
);
const scheduledByAgent = useFunctionGetter(
  'agents/getAgentById',
  scheduledById
);

const isScheduledByCurrentUser = computed(() => {
  if (!scheduledById.value || !currentUserId.value) return false;
  return Number(scheduledById.value) === Number(currentUserId.value);
});

const scheduledAt = computed(() => additionalAttributes.value?.scheduledAt);
const scheduledAtTimestamp = computed(() => {
  if (!scheduledAt.value) return null;
  return Math.floor(scheduledAt.value);
});

const scheduledAtLabel = computed(() => {
  if (!scheduledAtTimestamp.value) {
    return t('SCHEDULED_MESSAGES.ITEM.NO_SCHEDULE');
  }
  const date = new Date(scheduledAtTimestamp.value * 1000);
  const now = new Date();

  const options = {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  };

  if (date.getFullYear() !== now.getFullYear()) {
    options.year = 'numeric';
  }

  return date.toLocaleString(locale.value.replace('_', '-'), options);
});

const scheduledByLabel = computed(() => {
  if (!isScheduledMessage.value) return '';
  if (isScheduledByCurrentUser.value) {
    const userName = scheduledByAgent.value?.name;
    return t('SCHEDULED_MESSAGES.META.AUTHOR_YOU', { name: userName });
  }
  if (scheduledByTypeNormalized.value.includes('automation')) {
    const automationLabel = t('SCHEDULED_MESSAGES.META.AUTOMATION');
    if (scheduledBy.value?.name) {
      return `${scheduledBy.value.name} (${automationLabel})`;
    }
    return automationLabel;
  }
  if (scheduledByAgent.value?.name) {
    return scheduledByAgent.value.name;
  }
  if (sender.value?.name) {
    return sender.value.name;
  }
  return t('SCHEDULED_MESSAGES.META.UNKNOWN_AUTHOR');
});

const scheduledTooltip = computed(() => {
  if (!isScheduledMessage.value) return '';
  return t('SCHEDULED_MESSAGES.META.TOOLTIP', {
    time: scheduledAtLabel.value,
    author: scheduledByLabel.value,
  });
});

const shouldShowScheduledIndicator = computed(() => {
  return isScheduledMessage.value && shouldGroupWithNext.value;
});

const iconColorClass = computed(() => {
  return variant.value === MESSAGE_VARIANTS.PRIVATE
    ? 'text-n-amber-12/50'
    : 'text-n-slate-11';
});
</script>

<template>
  <span class="inline">
    <span
      v-dompurify-html="formattedContent"
      class="prose prose-bubble [&_.prosemirror-mention-contact]:bg-n-blue-3 [&_.prosemirror-mention-contact]:rounded [&_.prosemirror-mention-contact]:px-1 [&_.prosemirror-mention-contact]:font-medium"
    />
    <span
      v-if="shouldShowScheduledIndicator"
      v-tooltip.top="{
        content: scheduledTooltip,
        delay: { show: 300, hide: 0 },
      }"
      :class="iconColorClass"
      class="inline-flex items-center ml-1 align-middle"
    >
      <Icon icon="i-lucide-alarm-clock" class="size-3" />
    </span>
    <span
      v-if="shouldShowEditedIndicator"
      v-tooltip.top="{
        content: previousContent,
        delay: { show: 300, hide: 0 },
      }"
      :class="iconColorClass"
      class="inline-flex items-center ml-1 align-middle"
    >
      <Icon icon="i-lucide-pencil" class="size-3" />
    </span>
  </span>
</template>
