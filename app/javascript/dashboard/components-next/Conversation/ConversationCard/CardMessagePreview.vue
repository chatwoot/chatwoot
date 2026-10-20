<script setup>
import { computed } from 'vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import MessagePreview from './MessagePreview.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const lastNonActivityMessage = computed(() =>
  useSnakeCase(props.conversation.lastNonActivityMessage ?? {}, { deep: true })
);

const assignee = computed(() => {
  const { meta: { assignee: agent = {} } = {} } = props.conversation;
  return {
    name: agent.name ?? agent.availableName,
    thumbnail: agent.thumbnail,
    status: agent.availabilityStatus,
  };
});

const unreadMessagesCount = computed(() => {
  const { unreadCount } = props.conversation;
  return unreadCount;
});
</script>

<template>
  <div class="flex items-end w-full gap-2 pb-1">
    <MessagePreview
      :message="lastNonActivityMessage"
      multi-line
      class="w-full"
      :class="unreadMessagesCount > 0 ? 'text-n-slate-12' : 'text-n-slate-11'"
    />
    <div class="flex items-center flex-shrink-0 gap-2 pb-2">
      <Avatar
        v-if="assignee.name"
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="20"
        :status="assignee.status"
        rounded-full
      />
      <div
        v-if="unreadMessagesCount > 0"
        class="inline-flex items-center justify-center rounded-full size-5 bg-n-brand"
      >
        <span class="text-xs font-semibold text-white">
          {{ unreadMessagesCount }}
        </span>
      </div>
    </div>
  </div>
</template>
