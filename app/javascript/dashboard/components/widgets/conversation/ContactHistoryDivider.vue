<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dateFormat } from 'shared/helpers/timeHelper';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  // Without a link the divider marks the open conversation.
  to: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['navigate']);

const { t } = useI18n();

const label = computed(() => {
  const { id, status, created_at: createdAt } = props.conversation;
  const time = dateFormat(createdAt, 'MMM d, yyyy · h:mm a');
  if (!props.to) return t('CONVERSATION.CONTACT_HISTORY.CURRENT', { id, time });

  return t('CONVERSATION.CONTACT_HISTORY.PAST', {
    id,
    status: t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${status}.TEXT`),
    time,
  });
});
</script>

<template>
  <li class="flex items-center gap-3 my-4 text-xs list-none text-n-slate-11">
    <span class="flex-1 h-px bg-n-weak" />
    <span class="whitespace-nowrap">{{ label }}</span>
    <router-link v-if="to" v-slot="{ href }" :to="to" custom>
      <a
        :href="href"
        class="font-medium text-n-blue-11 hover:underline"
        @click.exact.prevent="emit('navigate')"
      >
        {{ t('CONVERSATION.CONTACT_HISTORY.OPEN') }}
      </a>
    </router-link>
    <span class="flex-1 h-px bg-n-weak" />
  </li>
</template>
