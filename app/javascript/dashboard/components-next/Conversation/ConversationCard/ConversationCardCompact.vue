<script setup>
import { computed, useTemplateRef } from 'vue';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import CardAvatar from './CardAvatar.vue';
import CardContent from './CardContent.vue';
import CardLabels from './CardLabelsV5.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';

const props = defineProps({
  chat: { type: Object, required: true },
  currentContact: { type: Object, required: true },
  assignee: { type: Object, default: () => ({}) },
  inbox: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
  isActiveChat: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  showInboxName: { type: Boolean, default: false },
  hideThumbnail: { type: Boolean, default: false },
  enableSelection: { type: Boolean, default: true },
  isInboxView: { type: Boolean, default: false },
});

const emit = defineEmits(['selectConversation', 'click', 'contextmenu']);

const slaCardLabel = useTemplateRef('slaCardLabel');

const lastMessageInChat = computed(() => getLastMessage(props.chat));

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const unreadCount = computed(() => props.chat?.unread_count);
const hasUnread = computed(() => unreadCount.value > 0);

const hasSlaPolicyId = computed(
  () => props.chat?.sla_policy_id || slaCardLabel.value?.hasSlaThreshold
);

const showLabelsSection = computed(
  () => props.chat.labels?.length > 0 || hasSlaPolicyId.value
);

const showMetaSection = computed(
  () =>
    (!props.isInboxView && props.showInboxName) ||
    (props.showAssignee && props.assignee?.name) ||
    props.chat.priority
);

const onSelectConversation = checked => {
  emit('selectConversation', checked);
};
</script>

<template>
  <div
    class="relative flex items-start max-w-full cursor-pointer group transition-colors duration-150 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3"
    :class="{
      'active animate-card-select bg-n-background border-n-weak': isActiveChat,
      'bg-n-slate-2': selected,
      'px-0': compact,
      'px-2 rounded-lg': !compact,
    }"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <div class="relative">
      <CardAvatar
        v-if="!compact && !hideThumbnail"
        :contact="currentContact"
        :selected="selected"
        :enable-selection="enableSelection"
        :hide-thumbnail="hideThumbnail"
        :class="showMetaSection ? 'mt-8' : 'mt-4'"
        @select-conversation="onSelectConversation"
      />
    </div>

    <div
      class="px-0 py-3 border-b group-hover:border-transparent flex-1 border-n-slate-3 min-w-0"
    >
      <div
        v-if="showMetaSection"
        class="flex items-center min-w-0 gap-1"
        :class="{
          'ltr:ml-2 rtl:mr-2': !compact,
          'mx-2': compact,
        }"
      >
        <InboxName
          v-if="showInboxName && !isInboxView"
          :inbox="inbox"
          class="flex-1 min-w-0"
        />
        <div
          v-if="showAssignee || chat.priority"
          class="flex items-center gap-2 flex-shrink-0 h-4"
          :class="{
            'flex-1 justify-between': isInboxView || !showInboxName,
          }"
        >
          <span
            v-if="showAssignee && assignee.name"
            class="text-n-slate-11 text-label-small px-0 inline-flex items-center truncate gap-0.5 max-w-36"
          >
            <Icon icon="i-lucide-user-round" class="text-n-slate-11 size-3" />
            {{ assignee.name }}
          </span>
          <CardPriorityIcon
            v-if="chat.priority"
            :priority="chat.priority"
            class="flex-shrink-0"
          />
        </div>
      </div>

      <div class="inline-flex items-center justify-between w-full">
        <h4
          class="text-heading-3 mx-2 capitalize pt-0.5 truncate flex-1 min-w-0 text-n-slate-12"
          :class="hasUnread ? '!font-520' : ''"
        >
          {{ currentContact.name }}
        </h4>

        <span class="text-label-small text-n-slate-11">
          <TimeAgo
            :last-activity-timestamp="chat.timestamp"
            :created-at-timestamp="chat.created_at"
          />
        </span>
      </div>

      <div class="ltr:ml-2 rtl:mr-2 leading-6 h-6 min-w-0">
        <CardContent
          :last-message="lastMessageInChat"
          :voice-call-status="voiceCallData.status"
          :voice-call-direction="voiceCallData.direction"
          :unread-count="unreadCount"
        />
      </div>

      <CardLabels
        v-if="showLabelsSection"
        :labels="chat.labels"
        class="mt-0.5 mx-2"
      >
        <template v-if="hasSlaPolicyId" #before>
          <SLACardLabel ref="slaCardLabel" :chat="chat" data-before-slot />
        </template>
      </CardLabels>
    </div>
  </div>
</template>
