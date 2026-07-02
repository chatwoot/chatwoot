<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { formatTime } from '@chatwoot/utils';
import format from 'date-fns/format';
import fromUnixTime from 'date-fns/fromUnixTime';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';

const props = defineProps({
  record: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const route = useRoute();

const conversation = computed(() => props.record.conversation || {});
const message = computed(() => props.record.message || {});
const isMessageRecord = computed(() => props.record.record_type === 'message');
const isEventBackedConversationRecord = computed(
  () => !isMessageRecord.value && !!props.record.event_name
);
const conversationDisplayId = computed(() => conversation.value.display_id);
const conversationNumber = computed(() => `#${conversationDisplayId.value}`);
const messageDirection = computed(() => message.value.message_type);

const formatTimestamp = timestamp => {
  if (!timestamp) return '';

  return format(fromUnixTime(timestamp), 'dd MMM yyyy, h:mm a');
};

const compactTimestamp = timestamp => {
  if (!timestamp) return '';

  return shortTimestamp(dynamicTime(timestamp)).trim();
};

const metricValue = computed(() => {
  const value = props.record.metric_value;
  if (value === null || value === undefined) return '';

  return formatTime(value) || `${value}`;
});

const previewText = computed(() => {
  if (message.value.content) return message.value.content;
  if (conversation.value.last_message?.content) {
    return conversation.value.last_message.content;
  }

  return t('REPORT.DRILLDOWN.NO_MESSAGE_CONTENT');
});

const showPreview = computed(() => {
  return isMessageRecord.value || conversation.value.last_message;
});

const messageCreatedTooltip = computed(() =>
  t('REPORT.DRILLDOWN.MESSAGE_CREATED_AT', {
    time: formatTimestamp(message.value.created_at),
  })
);

const eventOccurredTooltip = computed(() =>
  t('REPORT.DRILLDOWN.EVENT_OCCURRED_AT', {
    time: formatTimestamp(props.record.occurred_at),
  })
);

const directionDetails = computed(() => {
  const direction = messageDirection.value;
  if (!direction) return null;

  const isIncoming = direction === 'incoming';
  return {
    icon: isIncoming ? 'i-lucide-arrow-down-left' : 'i-lucide-arrow-up-right',
    tooltip: isIncoming
      ? t('REPORT.DRILLDOWN.INCOMING_MESSAGE')
      : t('REPORT.DRILLDOWN.OUTGOING_MESSAGE'),
  };
});

const conversationPath = computed(() => {
  if (!conversationDisplayId.value) return '';

  const path = conversationUrl({
    accountId: route.params.accountId,
    id: conversationDisplayId.value,
  });
  const params =
    isMessageRecord.value && message.value.id
      ? { messageId: message.value.id }
      : null;

  return frontendURL(path, params);
});

const contactPath = computed(() => {
  if (!conversation.value.contact_id) return '';

  return frontendURL(
    `accounts/${route.params.accountId}/contacts/${conversation.value.contact_id}`
  );
});

const inboxPath = computed(() => {
  if (!conversation.value.inbox_id) return '';

  return frontendURL(
    `accounts/${route.params.accountId}/inbox/${conversation.value.inbox_id}`
  );
});

const agentPath = computed(() => {
  if (!conversation.value.assignee_id) return '';

  return frontendURL(
    `accounts/${route.params.accountId}/reports/agents/${conversation.value.assignee_id}`
  );
});

const metadataItems = computed(() => [
  {
    key: 'contact',
    icon: 'i-lucide-contact',
    label:
      conversation.value.contact_name || t('REPORT.DRILLDOWN.UNKNOWN_CONTACT'),
    path: contactPath.value,
  },
  {
    key: 'inbox',
    icon: 'i-lucide-inbox',
    label: conversation.value.inbox_name || t('REPORT.DRILLDOWN.UNKNOWN_INBOX'),
    path: inboxPath.value,
  },
  {
    key: 'agent',
    icon: 'i-lucide-user-round',
    label:
      conversation.value.assignee_name ||
      t('REPORT.DRILLDOWN.UNASSIGNED_AGENT'),
    path: agentPath.value,
  },
]);

const metadataAttributes = item => {
  if (!item.path) return {};

  return {
    href: item.path,
    target: '_blank',
    rel: 'noopener noreferrer',
  };
};

const metadataItemClass = item => [
  'flex min-w-0 items-center gap-1 text-n-slate-10',
  item.path ? 'group hover:text-n-blue-11 hover:underline' : '',
];

const metadataIconClass = item => [
  'size-3 shrink-0 text-n-slate-9',
  item.path ? 'group-hover:text-n-blue-11' : '',
];

const stopMetadataLinkClick = (event, item) => {
  if (item.path) {
    event.stopPropagation();
  }
};

const openInNewTab = url => {
  if (!url) return;

  window.open(url, '_blank', 'noopener,noreferrer');
};

const openRecord = () => {
  openInNewTab(conversationPath.value);
};
</script>

<template>
  <article
    role="link"
    tabindex="0"
    class="cursor-pointer rounded-md border border-n-weak bg-n-solid-2 p-3 hover:bg-n-alpha-1 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
    @click="openRecord"
    @keydown.enter.self.prevent="openRecord"
    @keydown.space.self.prevent="openRecord"
  >
    <div class="flex items-start justify-between gap-2">
      <div class="min-w-0">
        <div
          class="flex items-center gap-2 text-sm font-medium leading-5 text-n-slate-12"
        >
          <span>{{ conversationNumber }}</span>
          <span
            v-if="conversation.status"
            class="rounded bg-n-alpha-2 px-1.5 py-0.5 text-xs capitalize text-n-slate-11"
          >
            {{ conversation.status }}
          </span>
          <span
            v-if="directionDetails"
            v-tooltip.top="directionDetails.tooltip"
            :aria-label="directionDetails.tooltip"
            class="flex size-5 items-center justify-center rounded bg-n-alpha-2 text-n-slate-11"
          >
            <Icon :icon="directionDetails.icon" class="size-3" />
          </span>
          <span
            v-if="metricValue"
            class="rounded bg-n-alpha-2 px-1.5 py-0.5 text-xs text-n-slate-11"
          >
            {{ metricValue }}
          </span>
        </div>
      </div>
      <div
        class="ml-2 flex shrink-0 items-center justify-end gap-1 text-right text-xs leading-4 text-n-slate-10"
      >
        <span
          v-if="isMessageRecord"
          v-tooltip.left="messageCreatedTooltip"
          :aria-label="messageCreatedTooltip"
          class="whitespace-nowrap"
        >
          {{ compactTimestamp(message.created_at) }}
        </span>
        <TimeAgo
          v-else
          :is-auto-refresh-enabled="false"
          :conversation-id="conversation.id"
          :last-activity-timestamp="conversation.last_activity_at"
          :created-at-timestamp="conversation.created_at"
          class="font-440 !text-xs !text-n-slate-10"
        />
        <span
          v-if="isEventBackedConversationRecord"
          v-tooltip.left="eventOccurredTooltip"
          :aria-label="eventOccurredTooltip"
          class="whitespace-nowrap rounded bg-n-alpha-2 px-1 py-0.5 text-[11px] leading-4 text-n-slate-10"
        >
          {{ compactTimestamp(record.occurred_at) }}
        </span>
      </div>
    </div>

    <p
      v-if="showPreview"
      class="mt-2 line-clamp-1 text-sm leading-5 text-n-slate-12"
    >
      {{ previewText }}
    </p>

    <div class="mt-2 grid grid-cols-3 gap-2">
      <component
        :is="item.path ? 'a' : 'span'"
        v-for="item in metadataItems"
        :key="item.key"
        class="text-body-main"
        v-bind="metadataAttributes(item)"
        :class="metadataItemClass(item)"
        @click="stopMetadataLinkClick($event, item)"
      >
        <Icon :icon="item.icon" :class="metadataIconClass(item)" />
        <span class="truncate">{{ item.label }}</span>
      </component>
    </div>
  </article>
</template>
