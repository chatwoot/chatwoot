<script setup>
import { computed, ref } from 'vue';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { useRouter, useRoute } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardMessagePreview from './CardMessagePreview.vue';
import CardMessagePreviewWithMeta from './CardMessagePreviewWithMeta.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  contact: {
    type: Object,
    required: true,
  },
  stateInbox: {
    type: Object,
    required: true,
  },
  accountLabels: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();

const router = useRouter();
const route = useRoute();

const cardMessagePreviewWithMetaRef = ref(null);

const currentContact = computed(() => props.contact);

const currentContactName = computed(() => currentContact.value?.name);
const currentContactThumbnail = computed(() => currentContact.value?.thumbnail);
const currentContactStatus = computed(
  () => currentContact.value?.availabilityStatus
);

const inbox = computed(() => props.stateInbox);

const inboxName = computed(() => inbox.value?.name);

const inboxIcon = computed(() => {
  const { channelType, medium } = inbox.value;
  return getInboxIconByType(channelType, medium);
});

const lastActivityAt = computed(() => {
  const timestamp = props.conversation?.timestamp;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

const showMessagePreviewWithoutMeta = computed(() => {
  const { labels = [] } = props.conversation;
  return (
    !cardMessagePreviewWithMetaRef.value?.hasSlaThreshold && labels.length === 0
  );
});

// Human assistance requested indicator
const isHumanAssistanceRequested = computed(
  () =>
    props.conversation.custom_attributes?.human_assistance_requested === true
);

// Check if a human is handling the conversation (handoff active or has human assignee)
const isHumanHandling = computed(() => {
  return (
    props.conversation.custom_attributes?.aloo_handoff_active === true ||
    props.conversation.meta?.assignee != null
  );
});

const humanAssistanceTooltip = computed(() =>
  t('CONVERSATION.ALOO.HUMAN_ASSISTANCE_REQUESTED_LIST_TOOLTIP')
);

const onCardClick = e => {
  const path = frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: props.conversation.id,
    })
  );

  if (e.metaKey || e.ctrlKey) {
    window.open(
      window.chatwootConfig.hostURL + path,
      '_blank',
      'noopener noreferrer nofollow'
    );
    return;
  }
  router.push({ path });
};
</script>

<template>
  <div
    role="button"
    class="flex w-full gap-3 px-3 py-4 transition-all duration-300 ease-in-out cursor-pointer"
    @click="onCardClick"
  >
    <Avatar
      :name="currentContactName"
      :src="currentContactThumbnail"
      :size="24"
      :status="currentContactStatus"
      rounded-full
    />
    <div class="flex flex-col w-full gap-1 min-w-0">
      <div class="flex items-center justify-between h-6 gap-2">
        <h4 class="text-base font-medium truncate text-n-slate-12">
          {{ currentContactName }}
        </h4>
        <div class="flex items-center gap-2">
          <span
            v-if="isHumanAssistanceRequested && !isHumanHandling"
            v-tooltip.left="humanAssistanceTooltip"
            class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-amber-3 size-5"
          >
            <Icon
              icon="i-lucide-hand"
              class="flex-shrink-0 text-n-amber-11 size-3"
            />
          </span>
          <CardPriorityIcon :priority="conversation.priority || null" />
          <div
            v-tooltip.left="inboxName"
            class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-5"
          >
            <Icon
              :icon="inboxIcon"
              class="flex-shrink-0 text-n-slate-11 size-3"
            />
          </div>
          <span class="text-sm text-n-slate-10">
            {{ lastActivityAt }}
          </span>
        </div>
      </div>
      <CardMessagePreview
        v-show="showMessagePreviewWithoutMeta"
        :conversation="conversation"
      />
      <CardMessagePreviewWithMeta
        v-show="!showMessagePreviewWithoutMeta"
        ref="cardMessagePreviewWithMetaRef"
        :conversation="conversation"
        :account-labels="accountLabels"
      />
    </div>
  </div>
</template>
