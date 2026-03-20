<script setup>
import { computed, nextTick, onMounted, ref, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useToggle } from '@vueuse/core';
import { fromUnixTime } from 'date-fns';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { buildRecurrenceDescription } from 'dashboard/helper/recurrenceHelpers';

const props = defineProps({
  scheduledMessage: {
    type: Object,
    required: true,
  },
  writtenBy: {
    type: String,
    required: true,
  },
  allowEdit: {
    type: Boolean,
    default: false,
  },
  allowDelete: {
    type: Boolean,
    default: false,
  },
  collapsible: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete', 'stop']);
const noteContentRef = useTemplateRef('noteContentRef');
const [isExpanded, toggleExpanded] = useToggle();
const showToggle = ref(false);
const showHistory = ref(false);
const showStopConfirm = ref(false);
const { t, locale } = useI18n();
const { formatMessage } = useMessageFormatter();
const route = useRoute();
const router = useRouter();

const normalizedLocale = computed(() => locale.value.replace('_', '-'));

const isRecurring = computed(() =>
  Boolean(props.scheduledMessage?.recurrence_rule)
);

const statusConfig = {
  draft: {
    labelKey: 'SCHEDULED_MESSAGES.STATUS.DRAFT',
    class: 'bg-n-slate-9/10 text-n-slate-12',
  },
  pending: {
    labelKey: 'SCHEDULED_MESSAGES.STATUS.PENDING',
    class: 'bg-n-brand/10 text-n-blue-text',
  },
  sent: {
    labelKey: 'SCHEDULED_MESSAGES.STATUS.SENT',
    class: 'bg-n-teal-9/10 text-n-teal-11',
  },
  failed: {
    labelKey: 'SCHEDULED_MESSAGES.STATUS.FAILED',
    class: 'bg-n-ruby-9/10 text-n-ruby-11',
  },
  active: {
    labelKey: 'SCHEDULED_MESSAGES.RECURRENCE.STATUS_ACTIVE',
    class: 'bg-n-brand/10 text-n-blue-text',
  },
  completed: {
    labelKey: 'SCHEDULED_MESSAGES.RECURRENCE.STATUS_COMPLETED',
    class: 'bg-n-slate-3 text-n-slate-11',
  },
  cancelled: {
    labelKey: 'SCHEDULED_MESSAGES.RECURRENCE.STATUS_CANCELLED',
    class: 'bg-n-ruby-3 text-n-ruby-11',
  },
};

const author = computed(() => props.scheduledMessage?.author || null);
const authorType = computed(() => props.scheduledMessage?.author_type);
const isUserAuthor = computed(
  () => authorType.value === 'User' && Boolean(author.value?.id)
);
const avatarSrc = computed(() => {
  if (isUserAuthor.value) {
    return author.value?.thumbnail || '';
  }
  return '/assets/images/chatwoot_bot.png';
});
const avatarName = computed(() => {
  if (isUserAuthor.value) {
    return author.value?.name || t('CONVERSATION.BOT');
  }
  return t('CONVERSATION.BOT');
});
const status = computed(() => props.scheduledMessage?.status || 'draft');
const statusBadge = computed(() => {
  const config = statusConfig[status.value] || statusConfig.draft;
  return {
    class: config.class,
    // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
    label: t(config.labelKey),
  };
});

const recurrenceDescription = computed(() => {
  if (!isRecurring.value) return '';
  return buildRecurrenceDescription(
    props.scheduledMessage.recurrence_rule,
    t,
    normalizedLocale.value
  );
});

const scheduledAt = computed(() => {
  if (isRecurring.value) {
    const pending =
      props.scheduledMessage.pending_scheduled_message ||
      props.scheduledMessage.scheduled_messages?.find(
        sm => sm.status === 'pending'
      );
    return pending?.scheduled_at || null;
  }
  return props.scheduledMessage?.scheduled_at;
});

const formattedScheduledTime = computed(() => {
  if (!scheduledAt.value) return '';
  const date = fromUnixTime(scheduledAt.value);
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

  return date.toLocaleString(normalizedLocale.value, options);
});

const templateName = computed(() => {
  const templateParams = props.scheduledMessage?.template_params || {};
  return templateParams.name || templateParams.id;
});

const hasTemplate = computed(() => Boolean(templateName.value));

const attachment = computed(() => props.scheduledMessage?.attachment);
const attachmentName = computed(() => attachment.value?.filename);
const attachmentUrl = computed(() => attachment.value?.file_url);
const shouldShowAttachmentLine = computed(() => Boolean(attachmentName.value));

const previewContent = computed(() => {
  if (props.scheduledMessage?.content) {
    return props.scheduledMessage.content;
  }
  if (templateName.value) {
    return t('SCHEDULED_MESSAGES.ITEM.TEMPLATE_PREVIEW', {
      name: templateName.value,
    });
  }
  if (attachmentName.value) {
    return '';
  }
  return t('SCHEDULED_MESSAGES.ITEM.EMPTY_PREVIEW');
});

const hasPreviewContent = computed(() => Boolean(previewContent.value));

const formattedContent = computed(() => formatMessage(previewContent.value));

// Recurring: completed children history
const completedChildren = computed(() => {
  if (!isRecurring.value) return [];
  const children = props.scheduledMessage.scheduled_messages || [];
  return children
    .filter(m => ['sent', 'failed'].includes(m.status))
    .sort((a, b) => (b.scheduled_at || 0) - (a.scheduled_at || 0));
});

const hasCompletedChildren = computed(() => completedChildren.value.length > 0);

const formatChildTime = childScheduledAt => {
  if (!childScheduledAt) return '';
  const date = new Date(childScheduledAt * 1000);
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
  return date.toLocaleString(normalizedLocale.value, options);
};

const canNavigateToChild = child =>
  child.status === 'sent' && Boolean(child.message_id);

const scrollToChildMessage = child => {
  if (!canNavigateToChild(child)) return;
  router.replace({
    ...route,
    query: { ...route.query, messageId: child.message_id },
  });
};

const checkOverflow = () => {
  if (!props.collapsible) {
    showToggle.value = false;
    return;
  }

  const el = noteContentRef.value;
  if (el && !isExpanded.value) {
    showToggle.value = el.scrollHeight > el.clientHeight;
  }
};

const onEdit = () => emit('edit', props.scheduledMessage);
const onDelete = () => {
  if (isRecurring.value) {
    showStopConfirm.value = true;
  } else {
    emit('delete', props.scheduledMessage);
  }
};
const confirmStop = () => {
  emit('stop', props.scheduledMessage);
  showStopConfirm.value = false;
};

const canScrollToMessage = computed(
  () =>
    !isRecurring.value &&
    props.scheduledMessage?.status === 'sent' &&
    Boolean(props.scheduledMessage?.message_id)
);

const scrollToMessage = () => {
  if (!canScrollToMessage.value) return;
  const messageId = props.scheduledMessage.message_id;
  router.replace({
    ...route,
    query: { ...route.query, messageId },
  });
};

onMounted(() => {
  checkOverflow();
});

watch(previewContent, () => {
  nextTick(checkOverflow);
});
</script>

<template>
  <div
    class="flex flex-col gap-3 border-b border-n-strong py-3 group/scheduled rounded-md transition-colors"
    :class="{
      'cursor-pointer hover:bg-n-alpha-1': canScrollToMessage,
    }"
    :title="
      canScrollToMessage
        ? t('SCHEDULED_MESSAGES.ITEM.GO_TO_MESSAGE')
        : undefined
    "
    @click="scrollToMessage"
  >
    <!-- Recurrence description header -->
    <div
      v-if="isRecurring"
      class="flex items-center gap-1.5 text-xs text-n-slate-11"
    >
      <Icon icon="i-lucide-repeat" class="size-3 shrink-0" />
      <span class="truncate">{{ recurrenceDescription }}</span>
    </div>

    <div class="flex items-center gap-3">
      <Avatar
        :name="avatarName"
        :src="avatarSrc"
        :size="30"
        rounded-full
        class="shrink-0"
      />

      <div class="flex-1 min-w-0">
        <p
          class="text-sm font-medium text-n-slate-12 mb-0.5 line-clamp-1"
          :title="writtenBy"
        >
          {{ writtenBy }}
        </p>
        <p
          v-if="formattedScheduledTime"
          class="flex items-center gap-1 text-xs text-n-slate-11 mb-0"
        >
          <Icon icon="i-lucide-alarm-clock" class="size-3 shrink-0" />
          {{
            isRecurring
              ? t('SCHEDULED_MESSAGES.RECURRENCE.NEXT_SEND', {
                  time: formattedScheduledTime,
                })
              : formattedScheduledTime
          }}
        </p>
        <p v-else class="text-xs text-n-slate-11 mb-0">
          {{ t('SCHEDULED_MESSAGES.ITEM.NO_SCHEDULE') }}
        </p>
      </div>

      <div class="flex flex-col items-center gap-2 shrink-0">
        <span
          class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
          :class="statusBadge.class"
        >
          {{ statusBadge.label }}
        </span>
        <div
          v-if="allowEdit || allowDelete"
          class="flex items-center gap-1 opacity-0 group-hover/scheduled:opacity-100"
        >
          <Button
            v-if="allowEdit"
            variant="faded"
            color="slate"
            size="xs"
            icon="i-lucide-pencil"
            @click.stop="onEdit"
          />
          <Button
            v-if="allowDelete"
            variant="faded"
            color="ruby"
            size="xs"
            :icon="isRecurring ? 'i-lucide-square' : 'i-lucide-trash'"
            @click.stop="onDelete"
          />
        </div>
      </div>
    </div>

    <p
      v-if="hasPreviewContent"
      ref="noteContentRef"
      v-dompurify-html="formattedContent"
      class="mb-0 prose-sm prose-p:text-sm prose-p:leading-relaxed prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
      :class="{
        'line-clamp-4': collapsible && !isExpanded,
      }"
    />

    <div v-if="hasPreviewContent && collapsible && showToggle">
      <Button
        variant="faded"
        color="blue"
        size="xs"
        :icon="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="() => toggleExpanded()"
      >
        <template v-if="isExpanded">
          {{ t('SCHEDULED_MESSAGES.ITEM.COLLAPSE') }}
        </template>
        <template v-else>
          {{ t('SCHEDULED_MESSAGES.ITEM.EXPAND') }}
        </template>
      </Button>
    </div>

    <div
      v-if="hasTemplate"
      class="flex items-center gap-1.5 text-xs text-n-slate-11"
    >
      <Icon icon="i-lucide-zap" class="size-3 shrink-0" />
      <span class="truncate">
        {{
          t('SCHEDULED_MESSAGES.ITEM.TEMPLATE_LABEL', {
            name: templateName,
          })
        }}
      </span>
    </div>

    <div
      v-if="shouldShowAttachmentLine"
      class="flex items-center gap-1.5 text-xs text-n-slate-11"
    >
      <Icon icon="i-lucide-paperclip" class="size-3 shrink-0" />
      <a
        v-if="attachmentUrl"
        :href="attachmentUrl"
        target="_blank"
        rel="noopener noreferrer"
        class="truncate hover:underline"
      >
        {{
          t('SCHEDULED_MESSAGES.ITEM.ATTACHMENT_LABEL', {
            filename: attachmentName,
          })
        }}
      </a>
      <span v-else class="truncate">
        {{
          t('SCHEDULED_MESSAGES.ITEM.ATTACHMENT_LABEL', {
            filename: attachmentName,
          })
        }}
      </span>
    </div>

    <!-- Recurring: sent/failed history toggle -->
    <div v-if="isRecurring && hasCompletedChildren" class="text-xs">
      <button
        class="flex items-center gap-1 text-n-slate-10 hover:text-n-slate-12 cursor-pointer transition-colors"
        @click.stop="showHistory = !showHistory"
      >
        <Icon
          :icon="showHistory ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
          class="size-3"
        />
        <span>
          {{
            t('SCHEDULED_MESSAGES.RECURRENCE.OCCURRENCES_SENT', {
              count: completedChildren.length,
            })
          }}
        </span>
      </button>
    </div>

    <!-- Recurring: expanded history list -->
    <div
      v-if="isRecurring && showHistory && hasCompletedChildren"
      class="flex flex-col gap-1 border-t border-n-weak pt-2"
    >
      <div
        v-for="child in completedChildren"
        :key="child.id"
        class="flex items-center justify-between gap-2 rounded-lg px-2 py-1.5 text-xs transition-colors"
        :class="{
          'cursor-pointer hover:bg-n-alpha-2': canNavigateToChild(child),
        }"
        @click.stop="scrollToChildMessage(child)"
      >
        <div class="flex items-center gap-2 min-w-0">
          <Icon
            :icon="
              child.status === 'sent'
                ? 'i-lucide-check-circle'
                : 'i-lucide-x-circle'
            "
            class="size-3 shrink-0"
            :class="
              child.status === 'sent' ? 'text-n-teal-11' : 'text-n-ruby-11'
            "
          />
          <span class="text-n-slate-11">
            {{ formatChildTime(child.scheduled_at) }}
          </span>
        </div>
        <span
          class="inline-flex items-center rounded-full px-1.5 py-0.5 text-[10px] font-medium shrink-0"
          :class="
            child.status === 'sent'
              ? 'bg-n-teal-9/10 text-n-teal-11'
              : 'bg-n-ruby-9/10 text-n-ruby-11'
          "
        >
          {{
            t(
              child.status === 'sent'
                ? 'SCHEDULED_MESSAGES.STATUS.SENT'
                : 'SCHEDULED_MESSAGES.STATUS.FAILED'
            )
          }}
        </span>
      </div>
    </div>

    <!-- Stop recurrence confirmation modal -->
    <woot-modal
      v-if="isRecurring"
      v-model:show="showStopConfirm"
      size="small"
      @close="() => (showStopConfirm = false)"
    >
      <div class="flex w-full flex-col gap-4 px-6 py-6">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.STOP_CONFIRM.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.STOP_CONFIRM.MESSAGE') }}
        </p>
        <div class="flex items-center justify-end gap-3">
          <Button
            variant="faded"
            color="slate"
            :label="t('SCHEDULED_MESSAGES.RECURRENCE.STOP_CONFIRM.CANCEL')"
            @click="showStopConfirm = false"
          />
          <Button
            variant="solid"
            color="ruby"
            :label="t('SCHEDULED_MESSAGES.RECURRENCE.STOP_CONFIRM.CONFIRM')"
            @click="confirmStop"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
