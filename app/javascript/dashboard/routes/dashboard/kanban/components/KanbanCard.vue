<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['delete']);

const { accountScopedRoute } = useAccount();

const conversationRoute = computed(() =>
  accountScopedRoute('inbox_conversation', {
    conversation_id: props.card.conversationDisplayId,
  })
);
</script>

<template>
  <div
    class="cursor-pointer rounded-md border border-n-weak bg-n-solid-1 p-2.5 shadow-sm transition-colors
      hover:bg-n-alpha-2"
  >
    <div class="flex items-start justify-between gap-2">
      <router-link
        :to="conversationRoute"
        class="min-w-0 text-sm font-semibold leading-5 text-n-slate-12 hover:underline"
      >
        #{{ card.conversationDisplayId }}
      </router-link>
      <Button
        v-tooltip.top="$t('KANBAN.CARD.DELETE')"
        icon="i-lucide-x"
        ghost
        slate
        xs
        class="!size-6 !p-0 shrink-0"
        @click="emit('delete', card)"
      />
    </div>
    <div class="mt-1.5 min-w-0">
      <p class="truncate text-sm font-medium text-n-slate-12">
        {{ card.contact?.name || $t('KANBAN.CARD.UNKNOWN_CONTACT') }}
      </p>
      <p class="truncate text-xs text-n-slate-11">
        {{ card.inbox?.name || $t('KANBAN.CARD.UNKNOWN_INBOX') }}
      </p>
    </div>
    <div class="mt-2.5 flex flex-wrap items-center gap-1.5">
      <span
        class="rounded-sm bg-n-slate-3 px-2 py-0.5 text-xs text-n-slate-11"
      >
        {{ card.conversationStatus }}
      </span>
      <span
        v-if="card.conversationPriority"
        class="rounded-sm bg-n-amber-3 px-2 py-0.5 text-xs text-n-amber-11"
      >
        {{ card.conversationPriority }}
      </span>
    </div>
  </div>
</template>
