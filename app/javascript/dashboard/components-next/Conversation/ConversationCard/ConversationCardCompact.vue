<script setup>
import { computed } from 'vue';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import CardMetaSection from './CardMetaSection.vue';
import CardAvatar from './CardAvatar.vue';
import CardHeader from './CardHeader.vue';
import CardContent from './CardContent.vue';
import CardLabels from './CardLabels.vue';

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

const lastMessageInChat = computed(() => getLastMessage(props.chat));
const showLabelsSection = computed(() => props.chat.labels?.length > 0);
const showExpandedPreview = computed(
  () => props.compact && !showLabelsSection.value
);

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const unreadCount = computed(() => props.chat?.unread_count);

const onSelectConversation = checked => {
  emit('selectConversation', checked);
};
</script>

<template>
  <div
    class="relative flex items-start flex-grow-0 flex-shrink-0 w-auto max-w-full cursor-pointer group transition-all duration-200"
    :class="{
      'active animate-card-select bg-n-alpha-1 dark:bg-n-alpha-3': isActiveChat,
      'selected bg-n-slate-2 dark:bg-n-slate-3': selected,
      'px-0 py-3': compact,
      'px-2 pt-2.5 pb-3 hover:bg-n-alpha-1 rounded-lg': !compact,
    }"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <div class="min-w-0 w-full">
      <CardMetaSection
        v-if="!isInboxView"
        :chat="chat"
        :inbox="inbox"
        :show-inbox-name="showInboxName"
        :show-assignee="showAssignee"
        :assignee="assignee"
      />

      <div
        class="grid gap-2.5 items-start"
        :class="{
          'mt-0.5 grid-cols-1': compact,
          'grid-cols-[auto,1fr]': !compact,
        }"
      >
        <CardAvatar
          v-if="!compact"
          :contact="currentContact"
          :selected="selected"
          :enable-selection="enableSelection"
          :hide-thumbnail="hideThumbnail"
          @select-conversation="onSelectConversation"
        />

        <div class="min-w-0 flex flex-col gap-1.5">
          <div class="min-w-0 flex flex-col gap-px">
            <CardHeader
              v-if="!compact"
              :contact-name="currentContact.name"
              :timestamp="chat.timestamp"
              :created-at="chat.created_at"
            />

            <CardContent
              :last-message="lastMessageInChat"
              :voice-call-status="voiceCallData.status"
              :voice-call-direction="voiceCallData.direction"
              :unread-count="unreadCount"
              :show-expanded-preview="showExpandedPreview"
            />
          </div>

          <CardLabels
            v-if="showLabelsSection || isInboxView"
            :conversation-labels="chat.labels"
          >
            <template v-if="isInboxView" #before>
              <CardMetaSection
                :chat="chat"
                :inbox="inbox"
                :show-assignee="showAssignee"
                :assignee="assignee"
                :is-labels-empty="chat.labels.length === 0"
                inline
              />
            </template>
          </CardLabels>
        </div>
      </div>
    </div>
  </div>
</template>
