<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const formattedDate = computed(() => {
  if (!props.conversation.createdAt) return '';
  return format(new Date(props.conversation.createdAt * 1000), 'MMM d, yyyy');
});

const conversationTitle = computed(() => {
  return (
    props.conversation.meta?.channel ||
    props.conversation.inboxName ||
    t('CONVERSATION.HISTORY.PREVIOUS_CONVERSATION')
  );
});
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
      <span>{{ conversationTitle }}</span>
      <span class="text-n-slate-9 select-none" aria-hidden="true">|</span>
      <span class="text-n-slate-9">
        {{ t('CONVERSATION.HISTORY.CONVERSATION_ID', { id: conversation.id }) }}
      </span>
      <template v-if="formattedDate">
        <span class="text-n-slate-9 select-none" aria-hidden="true">|</span>
        <span class="text-n-slate-9">{{ formattedDate }}</span>
      </template>
    </span>
    <span class="flex-1 h-px bg-n-weak" />
  </li>
</template>
