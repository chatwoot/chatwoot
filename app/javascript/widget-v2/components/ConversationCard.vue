<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';
import { getAiState } from 'widget-v2/helpers/conversationHelpers';
import { formatRelativeDay } from 'widget-v2/helpers/time';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

const props = defineProps({
  conversation: { type: Object, required: true },
});

const { t } = useI18n();
const configStore = useConfigStore();

const aiState = computed(() =>
  getAiState(props.conversation, configStore.hasAiAgent)
);

const displayName = computed(() => {
  if (aiState.value === 'ai') {
    return configStore.aiAgent?.name || t('AI_STATE.AI_DEFAULT_NAME');
  }
  return (
    props.conversation.assignee?.name ||
    configStore.channel.website_name ||
    t('AI_STATE.HUMAN_DEFAULT_NAME')
  );
});

const avatarUrl = computed(() => {
  if (aiState.value === 'ai') return configStore.aiAgent?.avatar_url;
  return (
    props.conversation.assignee?.avatar_url || configStore.channel.avatar_url
  );
});

const preview = computed(() => {
  const message = props.conversation.last_message;
  if (!message) return '';
  if (message.content) return message.content.replace(/\s+/g, ' ');
  return message.attachments?.length ? '📎' : '';
});

const timestamp = computed(() =>
  formatRelativeDay(
    props.conversation.last_activity_at || props.conversation.created_at,
    { today: t('COMMON.TODAY'), yesterday: t('COMMON.YESTERDAY') }
  )
);

const unread = computed(() => props.conversation.unread_count || 0);
</script>

<template>
  <button
    type="button"
    class="flex items-center w-full gap-3 px-4 py-3 text-left transition-colors bg-cw-background hover:bg-cw-surface outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary"
  >
    <BaseAvatar :src="avatarUrl" :name="displayName" :size="40" />

    <span class="flex-1 min-w-0">
      <span class="flex items-center gap-2">
        <span class="text-sm font-medium text-cw-text truncate">
          {{ displayName }}
        </span>
        <span
          v-if="aiState === 'ai'"
          class="inline-flex items-center gap-0.5 shrink-0 text-xxs font-medium text-cw-primary bg-cw-primary-soft px-1.5 py-0.5 rounded-full"
        >
          <span class="i-lucide-sparkles" />
          {{ $t('COMMON.AI_BADGE') }}
        </span>
        <span class="ml-auto shrink-0 text-xxs text-cw-text-faint">
          {{ timestamp }}
        </span>
      </span>
      <span class="flex items-center gap-2 mt-0.5">
        <span
          class="text-xs truncate"
          :class="unread ? 'text-cw-text font-medium' : 'text-cw-text-muted'"
        >
          <template v-if="conversation.status === 'resolved'">
            {{ $t('CONVERSATIONS.RESOLVED') }} · {{ preview }}
          </template>
          <template v-else>{{ preview }}</template>
        </span>
        <span
          v-if="unread"
          class="ml-auto shrink-0 min-w-4 h-4 px-1 flex items-center justify-center rounded-full bg-cw-primary text-cw-primary-foreground text-xxs font-semibold"
        >
          {{ unread > 9 ? '9+' : unread }}
        </span>
      </span>
    </span>
  </button>
</template>
