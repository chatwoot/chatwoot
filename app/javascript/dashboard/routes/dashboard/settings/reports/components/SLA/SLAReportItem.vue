<script setup>
import { computed } from 'vue';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
import SLAViewDetails from './SLAViewDetails.vue';
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
  slaEvents: {
    type: Array,
    default: () => [],
  },
});

const conversationLabels = computed(() => {
  return props.conversation.labels
    ? props.conversation.labels.split(',').map(item => item.trim())
    : [];
});

const routerParams = computed(() => ({
  name: 'inbox_conversation',
  params: { conversation_id: props.conversationId },
}));
</script>

<template>
  <div
    class="grid items-center content-center w-full h-16 grid-cols-12 gap-4 px-6 py-0 border-b last:border-b-0 last:rounded-b-xl border-n-weak"
  >
    <div
      class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-n-slate-12 rtl:text-right"
    >
      <router-link :to="routerParams" class="text-n-slate-12 hover:underline">
        {{ `#${conversationId}` }}
      </router-link>
      <span class="text-n-slate-11">
        {{ $t('SLA_REPORTS.WITH') }}
      </span>
      <span class="capitalize truncate text-n-slate-12">{{
        conversation.contact.name
      }}</span>
      <CardLabels
        v-if="conversationLabels.length"
        class="w-[60%]"
        :conversation-id="conversationId"
        :conversation-labels="conversationLabels"
      />
    </div>
    <div
      class="flex items-center capitalize py-2 px-0 text-sm tracking-[0.5] text-n-slate-12 text-left rtl:text-right col-span-2"
    >
      {{ slaName }}
    </div>
    <div class="flex items-center col-span-2 gap-2">
      <UserAvatarWithName
        v-if="conversation.assignee"
        :user="conversation.assignee"
      />
      <span v-else class="text-n-slate-11"> --- </span>
    </div>
    <SLAViewDetails :sla-events="slaEvents" />
  </div>
</template>
