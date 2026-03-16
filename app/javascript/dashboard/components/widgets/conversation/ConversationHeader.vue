<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import BackButton from '../BackButton.vue';
import InboxName from '../InboxName.vue';
import MoreActions from './MoreActions.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useInbox } from 'dashboard/composables/useInbox';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showBackButton: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const conversationHeader = ref(null);
const { width } = useElementSize(conversationHeader);
const { isAWebWidgetInbox } = useInbox();

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const chatMetadata = computed(() => props.chat.meta || {});

const backButtonUrl = computed(() => {
  const {
    params: { inbox_id: inboxId, label, teamId, id: customViewId },
    name,
  } = route;

  const conversationTypeMap = {
    conversation_through_mentions: 'mention',
    conversation_through_unattended: 'unattended',
  };
  return conversationListPageURL({
    accountId: accountId.value,
    inboxId,
    label,
    teamId,
    conversationType: conversationTypeMap[name],
    customViewId,
  });
});

const isHMACVerified = computed(() => {
  if (!isAWebWidgetInbox.value) {
    return true;
  }
  return chatMetadata.value.hmac_verified;
});

const currentContact = computed(() => {
  const senderId = props.chat?.meta?.sender?.id;
  if (!senderId) {
    return {
      name: '-',
      thumbnail: '',
      availability_status: '',
    };
  }

  return (
    store.getters['contacts/getContact'](senderId) || {
      name: '-',
      thumbnail: '',
      availability_status: '',
    }
  );
});

const isSnoozed = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.SNOOZED
);

const snoozedDisplayText = computed(() => {
  const { snoozed_until: snoozedUntil } = currentChat.value;
  if (snoozedUntil) {
    return `${t('CONVERSATION.HEADER.SNOOZED_UNTIL')} ${snoozedReopenTime(snoozedUntil)}`;
  }
  return t('CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_REPLY');
});

const inbox = computed(() => {
  const { inbox_id: inboxId } = props.chat;
  return store.getters['inboxes/getInbox'](inboxId);
});

const hasMultipleInboxes = computed(
  () => store.getters['inboxes/getInboxes'].length > 1
);

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

const assignedAgentName = computed(
  () =>
    chatMetadata.value?.assignee?.name ||
    t('CONVERSATION_SIDEBAR.SELECT.PLACEHOLDER')
);

const assignedTeamName = computed(
  () =>
    chatMetadata.value?.team?.name ||
    t('CONVERSATION_SIDEBAR.SELECT.PLACEHOLDER')
);

const priorityLabel = computed(() => {
  const priority = currentChat.value?.priority;

  if (priority === 'urgent') return t('CONVERSATION.PRIORITY.OPTIONS.URGENT');
  if (priority === 'high') return t('CONVERSATION.PRIORITY.OPTIONS.HIGH');
  if (priority === 'medium') return t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM');
  if (priority === 'low') return t('CONVERSATION.PRIORITY.OPTIONS.LOW');

  return t('CONVERSATION.PRIORITY.OPTIONS.NONE');
});

const inboxChipText = computed(
  () => `${t('SIDEBAR.INBOX')} ${inbox.value?.name || '-'}`
);

const assigneeChipText = computed(
  () => `${t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')} ${assignedAgentName.value}`
);

const teamChipText = computed(
  () => `${t('CONVERSATION_SIDEBAR.TEAM_LABEL')} ${assignedTeamName.value}`
);

const priorityChipText = computed(
  () => `${t('CONVERSATION.PRIORITY.TITLE')} ${priorityLabel.value}`
);
</script>

<template>
  <div
    ref="conversationHeader"
    class="flex flex-col gap-2 justify-between w-full min-w-0 px-3 py-2 border-b border-n-weak bg-n-solid-1"
  >
    <div class="flex items-center justify-between gap-2 min-w-0">
      <div class="flex items-center min-w-0 gap-2">
        <BackButton
          v-if="showBackButton"
          :back-url="backButtonUrl"
          class="ltr:mr-1 rtl:ml-1"
        />
        <Avatar
          :name="currentContact.name"
          :src="currentContact.thumbnail"
          :size="32"
          :status="currentContact.availability_status"
          hide-offline-status
          rounded-full
        />
        <div class="flex flex-col min-w-0">
          <div class="flex items-center gap-1 min-w-0">
            <span class="text-sm font-semibold truncate text-n-slate-12">
              {{ currentContact.name }}
            </span>
            <fluent-icon
              v-if="!isHMACVerified"
              v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
              size="14"
              class="text-n-amber-10 min-w-[14px]"
              icon="warning"
            />
          </div>
          <div class="flex items-center gap-2 text-xs text-n-slate-10 min-w-0">
            <InboxName v-if="hasMultipleInboxes" :inbox="inbox" class="!mx-0" />
            <span v-if="isSnoozed" class="font-medium text-n-amber-10 truncate">
              {{ snoozedDisplayText }}
            </span>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-2 shrink-0">
        <SLACardLabel
          v-if="hasSlaPolicyId"
          :chat="chat"
          show-extended-info
          :parent-width="width"
          class="hidden md:flex"
        />
        <MoreActions :conversation-id="currentChat.id" />
      </div>
    </div>

    <div class="flex flex-wrap items-center gap-2 text-xs">
      <span
        class="px-2 py-1 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11"
      >
        {{ inboxChipText }}
      </span>
      <span
        class="px-2 py-1 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11"
      >
        {{ assigneeChipText }}
      </span>
      <span
        class="px-2 py-1 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11"
      >
        {{ teamChipText }}
      </span>
      <span
        class="px-2 py-1 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11"
      >
        {{ priorityChipText }}
      </span>
    </div>
  </div>
</template>
