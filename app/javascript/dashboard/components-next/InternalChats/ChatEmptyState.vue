<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  variant: {
    type: String,
    default: 'select',
    validator: value =>
      ['select', 'empty_thread', 'no_rooms', 'loading'].includes(value),
  },
});

const { t } = useI18n();

const config = computed(() => {
  const map = {
    select: {
      title: t('INTERNAL_CHATS.EMPTY.SELECT_TITLE'),
      useConversationArt: true,
    },
    empty_thread: {
      title: t('INTERNAL_CHATS.EMPTY.THREAD_TITLE'),
      useConversationArt: false,
    },
    no_rooms: {
      title: t('INTERNAL_CHATS.EMPTY.NO_ROOMS_TITLE'),
      useConversationArt: true,
    },
    loading: {
      title: t('INTERNAL_CHATS.LOADING_THREAD'),
      useConversationArt: false,
    },
  };
  return map[props.variant] || map.select;
});
</script>

<template>
  <div
    class="flex h-full min-h-0 w-full min-w-0 flex-1 flex-col items-center justify-center bg-n-surface-1 px-6 text-center"
  >
    <template v-if="variant === 'loading'">
      <span
        class="i-lucide-loader-circle mb-3 size-8 animate-spin text-n-slate-10"
        aria-hidden="true"
      />
      <span class="text-sm font-medium text-n-slate-12">
        {{ config.title }}
      </span>
    </template>

    <template v-else-if="config.useConversationArt">
      <img
        class="m-4 w-32 hidden dark:block"
        src="dashboard/assets/images/no-chat-dark.svg"
        alt=""
      />
      <img
        class="m-4 w-32 block dark:hidden"
        src="dashboard/assets/images/no-chat.svg"
        alt=""
      />
      <span class="text-sm font-medium text-n-slate-12">
        {{ config.title }}
      </span>
    </template>

    <template v-else>
      <span class="text-sm font-medium text-n-slate-12">
        {{ config.title }}
      </span>
    </template>
  </div>
</template>
