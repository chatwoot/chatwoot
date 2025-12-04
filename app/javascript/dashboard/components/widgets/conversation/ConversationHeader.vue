<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import BackButton from '../BackButton.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MoreActions from './MoreActions.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useInbox } from 'dashboard/composables/useInbox';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showBackButton: {
    type: Boolean,
    default: false,
  },
  isOnExpandedView: {
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

const { uiSettings } = useUISettings();

const isSidePanelOpen = computed(
  () =>
    uiSettings.value.is_contact_sidebar_open ||
    uiSettings.value.is_copilot_panel_open ||
    false
);

const breakpoint = computed(() => {
  const base = props.isOnExpandedView ? 'md' : 'lg';
  const open = props.isOnExpandedView ? 'lg' : 'xl';
  return isSidePanelOpen.value ? open : base;
});

const responsiveClasses = computed(() => ({
  header: `${breakpoint.value}:flex-row ${breakpoint.value}:items-center`,
  left: `${breakpoint.value}:flex-1 ${breakpoint.value}:basis-0`,
  right: `${breakpoint.value}:flex-1 ${breakpoint.value}:basis-0 ${breakpoint.value}:justify-end`,
}));

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const chatMetadata = computed(() => props.chat.meta);

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

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

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

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);
</script>

<template>
  <div
    ref="conversationHeader"
    class="flex flex-col items-start gap-x-6 gap-y-2 w-full min-w-0 pt-3 pb-2 ltr:pl-4 rtl:pr-4 ltr:pr-1 rtl:pl-1"
    :class="responsiveClasses.header"
  >
    <div
      class="flex items-center gap-2 min-w-0 w-full"
      :class="responsiveClasses.left"
    >
      <BackButton v-if="showBackButton" :back-url="backButtonUrl" />

      <div class="flex items-center gap-1 min-w-0 ltr:mr-2 rtl:ml-2">
        <span class="text-base font-medium text-n-slate-12 truncate min-w-0">
          {{ currentContact.name }}
        </span>
        <Icon
          v-if="!isHMACVerified"
          v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
          icon="i-lucide-triangle-alert"
          class="text-n-amber-10 size-3.5 shrink-0"
        />
      </div>
    </div>

    <div
      class="flex items-center gap-2 min-w-0 w-full"
      :class="responsiveClasses.right"
    >
      <div
        v-if="isSnoozed"
        v-tooltip.top="{
          content: snoozedDisplayText,
          delay: { show: 500, hide: 0 },
        }"
        class="flex items-center gap-1 min-w-0 shrink"
      >
        <Icon
          icon="i-lucide-bell-off"
          class="text-n-slate-11 size-3.5 shrink-0"
        />
        <span class="text-xs text-n-slate-11 font-420 truncate min-w-0">
          {{ snoozedDisplayText }}
        </span>
      </div>

      <div v-if="isSnoozed" class="w-px h-3 rounded-lg bg-n-strong shrink-0" />

      <SLACardLabel
        v-if="hasSlaPolicyId"
        :chat="chat"
        show-extended-info
        :parent-width="width"
        class="p-1 shrink-0"
      />

      <div
        v-if="hasSlaPolicyId"
        class="w-px h-3 rounded-lg bg-n-strong ltr:mx-2 rtl:mx-2 shrink-0"
      />

      <MoreActions :conversation-id="currentChat.id" class="shrink-0" />
    </div>
  </div>
</template>
