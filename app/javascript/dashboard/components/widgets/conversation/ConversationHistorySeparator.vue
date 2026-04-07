<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  accountId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();

const formattedDate = computed(() => {
  if (!props.conversation.createdAt) return '';
  return new Intl.DateTimeFormat(navigator.language, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(new Date(props.conversation.createdAt * 1000));
});

const inboxObject = computed(() => ({
  channel_type: props.conversation.inboxName,
}));

const conversationLink = computed(() =>
  frontendURL(
    conversationUrl({ accountId: props.accountId, id: props.conversation.id })
  )
);
</script>

<template>
  <li
    class="list-none flex items-center gap-3 px-4 py-3 my-2 select-none"
    aria-hidden="true"
  >
    <span class="flex-1 h-px bg-n-weak" />
    <span
      class="flex items-center gap-1.5 text-xs font-medium text-n-slate-11 whitespace-nowrap"
    >
      <ChannelIcon :inbox="inboxObject" class="size-3.5 flex-shrink-0" />
      <span class="text-n-slate-9 select-none" aria-hidden="true">|</span>
      <a
        :href="conversationLink"
        target="_blank"
        rel="noopener noreferrer"
        class="text-n-slate-9 hover:underline"
      >
        {{ t('CONVERSATION.HISTORY.CONVERSATION_ID', { id: conversation.id }) }}
      </a>
      <template v-if="formattedDate">
        <span class="text-n-slate-9 select-none" aria-hidden="true">|</span>
        <span class="text-n-slate-9">{{ formattedDate }}</span>
      </template>
    </span>
    <span class="flex-1 h-px bg-n-weak" />
  </li>
</template>
