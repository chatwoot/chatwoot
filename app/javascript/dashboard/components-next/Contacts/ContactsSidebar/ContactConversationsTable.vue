<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useStatusLabel } from 'dashboard/composables/useStatusLabel';
import { formatAttributeValue } from 'dashboard/composables/useFeaturedAttributes';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import {
  buildConversationHistoryColumns,
  isCustomColumnKey,
  attributeKeyFromColumn,
} from 'dashboard/helper/contactConversationTableColumns';

const props = defineProps({
  conversations: { type: Array, default: () => [] },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '-' },
});

const emit = defineEmits(['update:sort']);

const EMPTY = '--';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { getStatusLabel } = useStatusLabel();

const getAttributesByModel = useMapGetter('attributes/getAttributesByModel');
const stateInbox = useMapGetter('inboxes/getInboxById');

const conversationAttributeDefs = computed(() => {
  const getter = getAttributesByModel.value;
  return typeof getter === 'function'
    ? getter('conversation_attribute') || []
    : [];
});

const columns = computed(() => {
  const defs = buildConversationHistoryColumns(conversationAttributeDefs.value);
  return defs.map(col => ({
    ...col,
    label:
      col.label || t(`CONTACTS_LAYOUT.SIDEBAR.HISTORY.COLUMNS.${col.labelKey}`),
  }));
});

const isSortedBy = key => {
  const col = columns.value.find(c => c.key === key);
  return col?.sortKey ? props.activeSort === col.sortKey : false;
};

const sortIcon = key => {
  if (!isSortedBy(key)) return 'i-lucide-arrow-up-down';
  return props.activeOrdering === '-'
    ? 'i-lucide-arrow-down'
    : 'i-lucide-arrow-up';
};

const handleHeaderClick = column => {
  if (!column.sortable || !column.sortKey) return;
  const isSame = props.activeSort === column.sortKey;
  let order = '';
  if (isSame) {
    order = props.activeOrdering === '-' ? '' : '-';
  } else if (
    column.sortKey === 'last_activity_at' ||
    column.sortKey === 'created_at' ||
    column.sortKey === 'priority'
  ) {
    order = '-';
  }
  emit('update:sort', { sort: column.sortKey, order });
};

const formatTimestamp = timestamp => {
  if (!timestamp) return EMPTY;
  return dynamicTime(timestamp);
};

const inboxName = conversation => {
  const inboxId = conversation.inboxId ?? conversation.inbox_id;
  return stateInbox.value(inboxId)?.name || EMPTY;
};

const assigneeName = conversation => {
  const meta = conversation.meta || {};
  return meta.assignee?.name || meta.assignee?.availableName || EMPTY;
};

const priorityLabel = priority => {
  if (!priority) return EMPTY;
  const key = `CONVERSATION.PRIORITY.OPTIONS.${String(priority).toUpperCase()}`;
  const label = t(key);
  return label === key ? priority : label;
};

const customAttrValue = (conversation, column) => {
  const attrs =
    conversation.customAttributes || conversation.custom_attributes || {};
  const key = column.attributeKey || attributeKeyFromColumn(column.key);
  const raw = attrs[key];
  if (raw === undefined || raw === null || raw === '') return EMPTY;
  return formatAttributeValue(raw, column.displayType);
};

const cellText = (conversation, column) => {
  switch (column.key) {
    case 'id':
      return `#${conversation.id}`;
    case 'status':
      return (
        getStatusLabel(conversation.status) || conversation.status || EMPTY
      );
    case 'inbox':
      return inboxName(conversation);
    case 'assignee':
      return assigneeName(conversation);
    case 'priority':
      return priorityLabel(conversation.priority);
    case 'last_activity_at':
      return formatTimestamp(
        conversation.lastActivityAt || conversation.timestamp
      );
    case 'created_at':
      return formatTimestamp(conversation.createdAt);
    default:
      if (isCustomColumnKey(column.key)) {
        return customAttrValue(conversation, column);
      }
      return EMPTY;
  }
};

const openConversation = conversation => {
  const path = frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: conversation.id,
    })
  );
  router.push(path);
};

const onRowKeydown = (event, conversation) => {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault();
    openConversation(conversation);
  }
};
</script>

<template>
  <div
    class="relative z-0 flex min-h-0 w-full flex-1 flex-col overflow-auto rounded-xl border border-n-weak"
  >
    <table class="w-max min-w-full border-separate border-spacing-0">
      <thead>
        <tr>
          <th
            v-for="column in columns"
            :key="column.key"
            class="sticky top-0 z-[1] border-b border-n-weak bg-n-surface-2 py-2 px-3 text-start text-xs font-medium text-n-slate-11 whitespace-nowrap"
            :class="{
              'cursor-pointer select-none hover:text-n-slate-12':
                column.sortable,
            }"
            @click="handleHeaderClick(column)"
          >
            <span class="inline-flex items-center gap-1">
              {{ column.label }}
              <span
                v-if="column.sortable"
                class="size-3.5 shrink-0"
                :class="sortIcon(column.key)"
              />
            </span>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="conversation in conversations"
          :key="conversation.id"
          class="group cursor-pointer"
          tabindex="0"
          @click="openConversation(conversation)"
          @keydown="onRowKeydown($event, conversation)"
        >
          <td
            v-for="column in columns"
            :key="`${conversation.id}-${column.key}`"
            class="border-b border-n-weak py-2 px-3 text-sm text-n-slate-12 whitespace-nowrap bg-n-surface-1 group-hover:bg-n-slate-2 dark:group-hover:bg-n-solid-2"
          >
            {{ cellText(conversation, column) }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
