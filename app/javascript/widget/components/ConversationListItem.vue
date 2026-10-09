<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getContrastingTextColor } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { relativeDayTimestamp } from 'shared/helpers/timeHelper';
import { MESSAGE_TYPE } from 'widget/helpers/constants';

const props = defineProps({
  conversation: { type: Object, required: true },
});

defineEmits(['select']);

const { t } = useI18n();
const { getPlainText } = useMessageFormatter();
const widgetColor = useMapGetter('appConfig/getWidgetColor');

const channelConfig = window.chatwootWebChannel;
const useInboxAvatarForBot = channelConfig.enabledFeatures.includes(
  'use_inbox_avatar_for_bot'
);
const botAvatarUrl = useInboxAvatarForBot
  ? channelConfig.avatarUrl
  : '/assets/images/chatwoot_bot.png';

const isResolved = computed(() => props.conversation.status === 'resolved');
const unreadCount = computed(() => props.conversation.unread_count);
const lastMessage = computed(() => props.conversation.last_message);
const isVisitorMessage = computed(
  () => lastMessage.value?.message_type === MESSAGE_TYPE.INCOMING
);

// Same identity rules as the agent bubbles on the messages screen.
const senderName = computed(() => {
  const { sender } = lastMessage.value || {};
  if (sender) return sender.available_name || sender.name;
  return useInboxAvatarForBot
    ? channelConfig.websiteName
    : t('UNREAD_VIEW.BOT');
});
const senderAvatarUrl = computed(() => {
  const message = lastMessage.value || {};
  if (message.message_type === MESSAGE_TYPE.TEMPLATE) return botAvatarUrl;
  return message.sender?.avatar_url || botAvatarUrl;
});

const preview = computed(() => {
  const message = lastMessage.value;
  if (!message) return '';
  const content = message.content
    ? getPlainText(message.content)
    : t('CONVERSATIONS.ATTACHMENT');
  return isVisitorMessage.value ? `${t('YOU')}: ${content}` : content;
});

const timestamp = computed(() =>
  relativeDayTimestamp(props.conversation.last_activity_at, t('YESTERDAY'))
);
</script>

<template>
  <button
    type="button"
    class="flex flex-col w-full gap-0.5 outline-none text-start focus-visible:bg-n-alpha-2"
    @click="$emit('select', conversation.id)"
  >
    <span class="flex items-center w-full gap-3">
      <span class="flex items-center flex-1 min-w-0 gap-2">
        <span class="shrink-0 text-sm font-medium leading-5 text-n-slate-12">
          {{ `#${conversation.id}` }}
        </span>
        <span
          v-if="isResolved"
          class="inline-flex items-center gap-0.5 px-1.5 rounded-full shrink-0 text-xxs font-medium leading-4 bg-n-teal-3 text-n-teal-11"
        >
          <i class="i-lucide-check size-2.5" aria-hidden="true" />
          {{ $t('CONVERSATIONS.RESOLVED') }}
        </span>
      </span>
      <span class="text-sm leading-5 shrink-0 text-n-slate-11">
        {{ timestamp }}
      </span>
    </span>
    <span class="flex items-center w-full gap-2">
      <span class="flex-1 min-w-0 text-sm leading-5 truncate text-n-slate-12">
        {{ preview }}
      </span>
      <span class="flex items-center h-5 gap-1.5 shrink-0">
        <span
          v-if="unreadCount"
          class="flex items-center justify-center h-5 px-1.5 text-xs font-semibold rounded-full min-w-5"
          :style="{
            backgroundColor: widgetColor,
            color: getContrastingTextColor(widgetColor),
          }"
        >
          <span aria-hidden="true">{{ unreadCount }}</span>
          <span class="sr-only">
            {{ $t('CONVERSATIONS.UNREAD_COUNT', unreadCount) }}
          </span>
        </span>
        <Avatar
          v-if="lastMessage && !isVisitorMessage"
          :src="senderAvatarUrl"
          :name="senderName"
          :size="20"
          rounded-full
        />
      </span>
    </span>
  </button>
</template>
