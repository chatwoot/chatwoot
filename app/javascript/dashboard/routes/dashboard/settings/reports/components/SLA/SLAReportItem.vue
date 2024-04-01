<script setup>
import { computed } from 'vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
import UserAvatar from './UserAvatar.vue';
const props = defineProps({
  slaName: {
    type: String,
    required: true,
  },
  conversationId: {
    type: Number,
    required: true,
  },
  conversation: {
    type: Object,
    required: true,
  },
});

const assigneeName = computed(() => props.conversation.assignee?.name);
</script>

<template>
  <div
    class="grid content-center items-center h-16 grid-cols-12 gap-4 px-6 py-0 w-full bg-white border-b border-slate-75 dark:border-slate-800/50 dark:bg-slate-900"
  >
    <div
      class="flex items-center capitalize py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 text-left rtl:text-right col-span-2"
    >
      {{ slaName }}
    </div>
    <div
      class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
    >
      <span class="text-slate-700 dark:text-slate-100">
        {{ `#${conversationId} ` }}
      </span>
      <span class="text-slate-600 dark:text-slate-100">with </span>
      <span class="text-slate-700 dark:text-slate-100 capitalize truncate">{{
        conversation.contact.name
      }}</span>
      <card-labels
        class="w-[80%]"
        :conversation-id="conversationId"
        :conversation-labels="conversation.labels"
      />
    </div>
    <div class="flex items-center gap-2 col-span-2">
      <user-avatar v-if="assigneeName" :user-name="assigneeName" src="" />
      <span
        v-if="assigneeName"
        class="text-slate-600 dark:text-slate-200 capitalize truncate"
      >
        {{ assigneeName }}
      </span>
      <span
        v-if="!assigneeName"
        class="text-slate-600 dark:text-slate-200 capitalize truncate"
      >
        ---
      </span>
    </div>

    <div
      class="flex items-center col-span-2 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
    >
      <woot-button color-scheme="secondary" variant="link">
        View details
      </woot-button>
    </div>
  </div>
</template>
