<script setup>
import { computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Avatar from 'next/avatar/Avatar.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
import SLACardLabel from 'dashboard/components/widgets/conversation/components/SLACardLabel.vue';

const props = defineProps({
  conversation: {
    type: Object,
    default: null,
  },
});

const store = useStore();

const chatMetadata = computed(() => props.conversation?.meta || {});

const senderId = computed(() => chatMetadata.value.sender?.id);

const currentContact = computed(() => {
  return senderId.value
    ? store.getters['contacts/getContact'](senderId.value)
    : {};
});

const inboxId = computed(() => props.conversation?.inbox_id);

const inbox = computed(() => {
  return inboxId.value ? store.getters['inboxes/getInbox'](inboxId.value) : {};
});

const activeInbox = useMapGetter('getSelectedInbox');
const inboxesList = useMapGetter('inboxes/getInboxes');

const showInboxName = computed(() => {
  return !activeInbox.value && inboxesList.value.length > 1;
});

const hasSlaPolicyId = computed(() => props.conversation?.sla_policy_id);

const showLabelsSection = computed(() => {
  return props.conversation?.labels?.length > 0 || hasSlaPolicyId.value;
});

const assignee = computed(() => props.conversation?.meta?.assignee || {});

const showAssignee = computed(() => assignee.value && assignee.value.name);
</script>

<template>
  <div class="flex flex-col pb-2 overflow-auto">
    <div
      class="relative flex flex-col items-start px-4 py-2 cursor-pointer group hover:bg-opacity-50 border border-n-weak mt-3 shadow outline-1 outline outline-n-container group/cardLayout rounded-2xl bg-n-solid-2"
      draggable="true"
    >
      <div
        class="flex items-center w-full mt-3 text-xs font-medium text-gray-400"
      >
        <div class="flex items-center w-full mb-3">
          <Avatar
            :name="currentContact.name"
            :src="currentContact.thumbnail"
            :size="32"
            :status="currentContact.availability_status"
            rounded-full
            hide-offline-status
          />
          <div class="flex flex-col flex-1 min-w-0 ml-2">
            <h4 class="text-sm font-semibold text-n-slate-12 truncate">
              {{ currentContact.name }}
            </h4>
            <InboxName v-if="showInboxName" :inbox="inbox" class="text-xs" />
          </div>
        </div>
      </div>

      <!-- Labels Section -->
      <div v-if="showLabelsSection" class="w-full mb-3">
        <CardLabels
          :conversation-labels="conversation.labels"
          class="mt-0.5 mb-0"
        >
          <template v-if="hasSlaPolicyId" #before>
            <SLACardLabel :chat="conversation" class="ltr:mr-1 rtl:ml-1" />
          </template>
        </CardLabels>
      </div>
      <div class="flex w-full">
        <div class="flex items-center mr-2">
          <fluent-icon icon="calendar" size="14" class="text-n-slate-10" />
          <TimeAgo
            :last-activity-timestamp="conversation.timestamp"
            :created-at-timestamp="conversation.created_at"
            class="ml-1"
          />
        </div>

        <div
          v-if="showAssignee && assignee.name"
          class="text-n-slate-11 text-xs font-medium leading-3 py-0.5 px-0 inline-flex items-center truncate"
        >
          <fluent-icon icon="person" size="12" class="text-n-slate-11" />
          {{ assignee.name }}
        </div>
      </div>
    </div>
  </div>
</template>
