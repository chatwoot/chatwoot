<script setup>
import { computed, useTemplateRef } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import CardStatusIcon from './CardStatusIcon.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';

const props = defineProps({
  chat: { type: Object, required: true },
  inbox: { type: Object, required: true },
  showInboxName: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  assignee: { type: Object, default: () => ({}) },
});

const slaCardLabel = useTemplateRef('slaCardLabel');

const hasSlaPolicyId = computed(
  () => props.chat?.sla_policy_id || slaCardLabel.value?.hasSlaThreshold
);

const showSection = computed(() => {
  return (
    props.showInboxName ||
    (props.showAssignee && props.assignee.name) ||
    props.chat.priority ||
    hasSlaPolicyId.value
  );
});
</script>

<template>
  <div
    v-if="showSection"
    class="flex items-center justify-between min-w-0 gap-8 h-6 mb-1"
  >
    <div class="flex-1 min-w-0 flex items-center gap-0.5">
      <InboxName v-if="showInboxName" :inbox="inbox" class="min-w-0" />
      <div
        v-if="showInboxName && hasSlaPolicyId"
        class="rounded-lg h-3 w-px bg-n-strong mx-1"
      />
      <SLACardLabel v-if="hasSlaPolicyId" ref="slaCardLabel" :chat="chat" />
    </div>
    <div class="flex items-center gap-1.5 flex-shrink-0">
      <CardPriorityIcon
        v-if="chat.priority"
        :priority="chat.priority"
        class="flex-shrink-0 [&>svg]:size-4"
      />
      <Avatar
        v-if="showAssignee && assignee.name"
        v-tooltip.top="{
          content: assignee.name,
          delay: { show: 1000, hide: 0 },
        }"
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="16"
        :status="assignee.availability_status"
        hide-offline-status
        rounded-full
      />
      <CardStatusIcon
        v-if="chat.status"
        :status="chat.status"
        class="[&>svg]:size-[1.18rem]"
      />
    </div>
  </div>
  <template v-else />
</template>
