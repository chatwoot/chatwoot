<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dateFormat } from 'shared/helpers/timeHelper';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MessagePreview from './MessagePreview.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  to: {
    type: String,
    required: true,
  },
  direction: {
    type: String,
    required: true,
    validator: value => ['older', 'newer'].includes(value),
  },
});

const emit = defineEmits(['navigate']);

const { t } = useI18n();

const isOlder = computed(() => props.direction === 'older');

const label = computed(() =>
  isOlder.value
    ? t('CONVERSATION.CONTACT_HISTORY.OLDER')
    : t('CONVERSATION.CONTACT_HISTORY.NEWER')
);

const startedAt = computed(() =>
  dateFormat(props.conversation.created_at, 'MMM d, yyyy')
);

const tooltip = computed(() =>
  t(
    isOlder.value
      ? 'CONVERSATION.CONTACT_HISTORY.OLDER_WITH'
      : 'CONVERSATION.CONTACT_HISTORY.NEWER_WITH',
    {
      name:
        props.conversation.meta?.sender?.name ||
        t('CONVERSATION.CONTACT_HISTORY.CUSTOMER'),
      time: dateFormat(props.conversation.created_at, 'MMM d, yyyy · h:mm a'),
    }
  )
);

// An email's first paragraph is the reply; the forwarded and quoted parts follow it.
const lastMessage = computed(() => {
  const message = getLastMessage(props.conversation);
  if (!message?.content) return message;

  return { ...message, content: message.content.trim().split(/\n\s*\n/)[0] };
});
</script>

<template>
  <li class="flex justify-center my-4 list-none">
    <router-link v-slot="{ href }" :to="to" custom>
      <a
        v-tooltip.top="tooltip"
        :href="href"
        class="inline-flex items-center h-8 gap-2 px-3 transition-colors border rounded-full shadow-sm group min-w-0 max-w-[min(32rem,100%)] border-n-weak bg-n-solid-1 hover:border-n-brand focus-visible:outline-none focus-visible:border-n-brand"
        @click.exact.prevent="emit('navigate')"
      >
        <Icon
          :icon="isOlder ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
          class="flex-shrink-0 transition-transform size-3.5 text-n-slate-11 group-hover:text-n-brand"
          :class="
            isOlder
              ? 'group-hover:-translate-y-0.5'
              : 'group-hover:translate-y-0.5'
          "
        />
        <span class="min-w-0 text-sm font-medium truncate text-n-slate-12">
          {{ label }}
        </span>
        <div
          v-if="lastMessage"
          class="flex items-center gap-2 min-w-0 max-w-[9rem] shrink-[999] overflow-hidden"
        >
          <span class="flex-shrink-0 w-px h-3.5 bg-n-strong" />
          <MessagePreview
            :message="lastMessage"
            :show-message-type="false"
            class="min-w-0 text-xs text-n-slate-11"
          />
        </div>
        <span class="flex-shrink-0 text-xs whitespace-nowrap text-n-slate-10">
          {{ startedAt }}
        </span>
      </a>
    </router-link>
  </li>
</template>
