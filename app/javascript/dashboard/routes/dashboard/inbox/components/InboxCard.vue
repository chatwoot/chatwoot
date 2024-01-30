<script setup>
import { defineProps } from 'vue';
import PriorityIcon from './PriorityIcon.vue';
import StatusIcon from './StatusIcon.vue';
import InboxNameAndId from './InboxNameAndId.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

const props = defineProps({
  notificationItem: {
    type: Object,
    default: () => {},
  },
});

const { primary_actor: primaryActor } = props.notificationItem || {};
const { priority, status, meta } = primaryActor || {};
const { assignee: assigneeMeta } = meta || {};
const { thumbnail, name } = assigneeMeta || {};

const inboxTypeMessage = 'Mentioned by Michael';
const inboxMessage = 'What is the best way to get started?';
const inbox = {
  inbox_id: 16787,
  inbox_name: 'Chatwoot Support',
};
</script>

<template>
  <div
    class="flex flex-col pl-5 pr-3 gap-2.5 py-3 w-full bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800/50 hover:bg-slate-25 dark:hover:bg-slate-800 cursor-pointer"
  >
    <div class="flex relative items-center justify-between w-full">
      <div
        class="absolute -left-3.5 flex w-2 h-2 rounded bg-woot-500 dark:bg-woot-500"
      />
      <InboxNameAndId :inbox="inbox" />
      <div class="flex gap-2">
        <PriorityIcon :priority="priority" />
        <StatusIcon :status="status" />
      </div>
    </div>

    <div class="flex flex-row justify-between items-center w-full">
      <div class="flex gap-1.5 items-center max-w-[80%]">
        <Thumbnail
          v-if="assigneeMeta"
          :src="thumbnail"
          :username="name"
          size="20px"
        />
        <div class="flex min-w-0">
          <span
            class="font-medium text-slate-800 dark:text-slate-100 text-sm overflow-hidden text-ellipsis whitespace-nowrap"
          >
            {{ inboxTypeMessage
            }}<span v-if="inboxTypeMessage" class="text-sm">:</span>
            <span class="font-normal text-sm">{{ inboxMessage }}</span>
          </span>
        </div>
      </div>
      <span
        class="font-medium text-slate-600 dark:text-slate-300 text-xs whitespace-nowrap"
      >
        10h ago
      </span>
    </div>
  </div>
</template>
