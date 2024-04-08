<script setup>
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
import SLAViewDetails from './SLAViewDetails.vue';
defineProps({
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
  slaEvents: {
    type: Array,
    default: () => [],
  },
});
</script>

<template>
  <div
    class="grid content-center items-center h-16 grid-cols-12 gap-4 px-6 py-0 w-full bg-white border-b last:border-b-0 last:rounded-b-xl border-slate-75 dark:border-slate-800/50 dark:bg-slate-900"
  >
    <div
      class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
    >
      <span class="text-slate-700 dark:text-slate-200">
        {{ `#${conversationId} ` }}
      </span>
      <span class="text-slate-600 dark:text-slate-300">with </span>
      <span class="text-slate-700 dark:text-slate-200 capitalize truncate">{{
        conversation.contact.name
      }}</span>
      <card-labels
        class="w-[80%]"
        :conversation-id="conversationId"
        :conversation-labels="conversation.labels"
      />
    </div>
    <div
      class="flex items-center capitalize py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right col-span-2"
    >
      {{ slaName }}
    </div>
    <div class="flex items-center gap-2 col-span-2">
      <user-avatar-with-name
        v-if="conversation.assignee"
        :user="conversation.assignee"
      />
      <span v-else class="text-slate-600 dark:text-slate-200"> --- </span>
    </div>
    <SLAViewDetails :sla-events="slaEvents" />
  </div>
</template>
