<script setup>
import { computed, useTemplateRef } from 'vue';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import CardAvatar from './CardAvatar.vue';
import CardContent from './CardContent.vue';
import CardLabels from './CardLabels.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import Avatar from 'next/avatar/Avatar.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';
import CardStatusIcon from './CardStatusIcon.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  chat: { type: Object, required: true },
  currentContact: { type: Object, required: true },
  assignee: { type: Object, default: () => ({}) },
  inbox: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
  isActiveChat: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  showInboxName: { type: Boolean, default: false },
  isInboxView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'selectConversation',
  'deSelectConversation',
  'click',
  'contextmenu',
]);

const lastMessageInChat = computed(() => getLastMessage(props.chat));
const showLabelsSection = computed(() => props.chat.labels?.length > 0);

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const unreadCount = computed(() => props.chat.unread_count);

const slaCardLabel = useTemplateRef('slaCardLabel');

const hasSlaPolicyId = computed(
  () => props.chat?.sla_policy_id || slaCardLabel.value?.hasSlaThreshold
);

const selectedModel = computed({
  get: () => props.selected,
  set: value => {
    if (value) {
      emit('selectConversation', value);
    } else {
      emit('deSelectConversation', value);
    }
  },
});
</script>

<template>
  <div
    class="relative cursor-pointer group transition-all duration-200 grid gap-4 items-center px-2 h-12"
    :class="{
      'active animate-card-select bg-n-alpha-1 dark:bg-n-alpha-3': isActiveChat,
      'selected bg-n-slate-2 dark:bg-n-slate-3': selected,
      'hover:bg-n-alpha-1 rounded-lg': !isActiveChat && !selected,
      'grid-cols-[minmax(0,2fr)_minmax(0,1fr)]': showLabelsSection,
      'grid-cols-[minmax(0,2fr)_max-content]': !showLabelsSection,
    }"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <!-- LEFT SECTION -->
    <div class="flex items-center gap-2 min-w-0 flex-1">
      <div class="flex items-center justify-center flex-shrink-0" @click.stop>
        <Checkbox v-model="selectedModel" />
      </div>

      <div class="w-px h-3 bg-n-slate-6 flex-shrink-0" />

      <div class="w-4 flex items-center justify-center flex-shrink-0">
        <CardPriorityIcon :priority="chat.priority" show-empty />
      </div>

      <div class="w-4 flex items-center justify-center flex-shrink-0">
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
        <Icon
          v-else
          icon="i-woot-empty-assignee"
          class="size-4 text-n-slate-7"
        />
      </div>

      <div class="w-4 flex items-center justify-center flex-shrink-0">
        <CardStatusIcon :status="chat.status" show-empty />
      </div>

      <div class="w-px h-3 bg-n-slate-6 flex-shrink-0" />

      <div v-if="!isInboxView" class="w-20 flex-shrink-0">
        <InboxName v-if="showInboxName" :inbox="inbox" class="min-w-0" />
      </div>

      <span
        class="text-xs outline outline-1 -outline-offset-1 outline-n-weak px-1.5 rounded-md h-6 text-n-slate-11 font-440 min-w-14 flex-shrink-0 inline-flex items-center justify-center truncate"
      >
        {{ chat.id }}
      </span>

      <div class="flex-shrink-0">
        <CardAvatar
          :contact="currentContact"
          :selected="false"
          :enable-selection="false"
          :hide-thumbnail="false"
        />
      </div>

      <h4
        class="text-sm my-0 capitalize truncate text-n-slate-12 font-medium w-32 flex-shrink-0"
      >
        {{ currentContact.name }}
      </h4>

      <CardContent
        :last-message="lastMessageInChat"
        :voice-call-status="voiceCallData.status"
        :voice-call-direction="voiceCallData.direction"
        :unread-count="unreadCount"
        :show-expanded-preview="false"
      />
    </div>

    <!-- RIGHT SECTION -->
    <div class="flex items-center justify-end gap-2 flex-shrink-0">
      <div v-if="showLabelsSection" class="min-w-0 w-full">
        <CardLabels
          :conversation-labels="chat.labels"
          disable-toggle
          class="my-0 [&>div]:justify-end"
        />
      </div>

      <div v-if="hasSlaPolicyId" class="flex-shrink-0">
        <SLACardLabel ref="slaCardLabel" :chat="chat" />
      </div>

      <div class="flex-shrink-0 w-[4.375rem] text-end">
        <TimeAgo
          :last-activity-timestamp="chat.timestamp"
          :created-at-timestamp="chat.created_at"
          class="font-440 !text-xs text-n-slate-11"
        />
      </div>
    </div>
  </div>
</template>
