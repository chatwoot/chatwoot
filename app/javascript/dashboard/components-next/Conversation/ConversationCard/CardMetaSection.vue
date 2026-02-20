<script setup>
import { computed, useTemplateRef } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import CardStatusIcon from './CardStatusIcon.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';

const props = defineProps({
  chat: { type: Object, required: true },
  inbox: { type: Object, required: true },
  showInboxName: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  assignee: { type: Object, default: () => ({}) },
  inline: { type: Boolean, default: false },
  isLabelsEmpty: { type: Boolean, default: false },
});

const slaCardLabel = useTemplateRef('slaCardLabel');

const hasSlaPolicyId = computed(
  () => props.chat?.sla_policy_id || slaCardLabel.value?.hasSlaThreshold
);

const showSection = computed(() => {
  if (props.inline) {
    return (
      hasSlaPolicyId.value ||
      props.chat.priority ||
      (props.showAssignee && props.assignee.name)
    );
  }
  return (
    props.showInboxName ||
    (props.showAssignee && props.assignee.name) ||
    props.chat.priority ||
    props.chat.status ||
    hasSlaPolicyId.value
  );
});
</script>

<template>
  <!-- Full meta section (when not inline) -->
  <div
    v-if="showSection && !inline"
    class="flex items-center justify-between min-w-0 gap-8 h-6 mb-1"
  >
    <div class="flex-1 min-w-0 flex items-center gap-0.5">
      <InboxName v-if="showInboxName" :inbox="inbox" class="min-w-0" />
    </div>
    <div class="flex items-center gap-1.5 flex-shrink-0">
      <CardPriorityIcon
        v-if="chat.priority"
        :priority="chat.priority"
        class="flex-shrink-0"
      />
      <Avatar
        v-if="showAssignee && assignee.name"
        v-tooltip.top="{
          content: assignee.name,
          delay: { show: 500, hide: 0 },
        }"
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="14"
        :status="assignee.availability_status"
        hide-offline-status
        rounded-full
      />
      <CardStatusIcon v-if="chat.status" :status="chat.status" />
    </div>
  </div>

  <!-- Inline meta section (compact mode for cases in inbox and label filter view) -->
  <div
    v-else-if="showSection && inline"
    data-before-slot
    class="flex items-center gap-1.5 flex-shrink-0"
  >
    <div class="flex items-center gap-1.5">
      <CardPriorityIcon
        v-if="chat.priority"
        :priority="chat.priority"
        class="flex-shrink-0"
      />
      <Avatar
        v-if="showAssignee && assignee.name"
        v-tooltip.top="assignee.name"
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="14"
        :status="assignee.availability_status"
        hide-offline-status
        rounded-full
      />
      <CardStatusIcon v-if="chat.status" :status="chat.status" />
    </div>
    <div v-if="hasSlaPolicyId" class="rounded-lg h-2 w-px bg-n-strong mx-0.5" />
    <SLACardLabel v-if="hasSlaPolicyId" ref="slaCardLabel" :chat="chat" />
    <div v-if="!isLabelsEmpty" class="rounded-lg h-2 w-px bg-n-strong mx-0.5" />
  </div>
</template>
