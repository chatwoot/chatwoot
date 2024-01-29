<script setup>
// import { defineProps } from 'vue';

import PriorityIcon from './components/PriorityIcon.vue';
import StatusIcon from './components/StatusIcon.vue';
import InboxNameAndId from './components/InboxNameAndId.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

// const props = defineProps({
//   notificationItem: {
//     type: Object,
//     default: () => {},
//   },
// });

const assigneeMeta = {
  thumbnail: '',
  name: 'Michael Johnson',
};
const { thumbnail, name } = assigneeMeta || {};
const status = 'open';
const priority = 'high';
const inboxTypeMessage = 'Mentioned by Michael';
const inboxMessage = 'What is the best way to get started?';
const inbox = {
  inbox_id: 16787,
  inbox_name: 'Chatwoot Support',
};
</script>

<template>
  <div
    class="flex max-w-[360px] flex-col pl-5 pr-3 gap-2.5 py-3 w-full bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-500 hover:bg-slate-25 dark:hover:bg-slate-800 cursor-pointer"
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
            class="font-medium text-slate-800 dark:text-slate-100 text-xs overflow-hidden text-ellipsis whitespace-nowrap"
          >
            {{ inboxTypeMessage }}<span v-if="inboxTypeMessage">:</span>
            <span class="font-normal">{{ inboxMessage }}</span>
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
