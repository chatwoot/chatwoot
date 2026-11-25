<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { fromUnixTime } from 'date-fns';
import { formatRelative } from 'shared/helpers/localizedDate';
import { useMapGetter } from 'dashboard/composables/store';
import { getContrastingTextColor } from '@chatwoot/utils';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import ConversationAPI from 'dashboard/api/conversations';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  displayId: {
    type: String,
    required: true,
  },
  accountId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const router = useRouter();
const allLabels = useMapGetter('labels/getLabels');
const allInboxes = useMapGetter('inboxes/getInboxes');

// Module-level cache shared across all instances
const conversationCache = new Map();

const conversation = ref(null);
const fetchFailed = ref(false);

const contactName = computed(
  () => conversation.value?.meta?.sender?.name || ''
);
const contactThumbnail = computed(
  () => conversation.value?.meta?.sender?.thumbnail || ''
);
const inboxName = computed(() => {
  const inboxId = conversation.value?.inbox_id;
  if (!inboxId) return '';
  return allInboxes.value?.find(inbox => inbox.id === inboxId)?.name || '';
});
const assigneeName = computed(
  () => conversation.value?.meta?.assignee?.name || ''
);
const status = computed(() => conversation.value?.status || '');
const lastActivityAt = computed(() => {
  const ts = conversation.value?.last_activity_at;
  if (!ts) return '';
  return formatRelative(fromUnixTime(ts));
});
const lastMessageObj = computed(() => {
  return (
    conversation.value?.last_non_activity_message ||
    conversation.value?.messages?.[0] ||
    null
  );
});

const lastMessage = computed(() => {
  if (!lastMessageObj.value) return '';
  return lastMessageObj.value.content || '';
});

const isLastMessageOutgoing = computed(() => {
  return lastMessageObj.value?.message_type === 1;
});

const labels = computed(() => {
  const names = conversation.value?.labels || [];
  return names.map(name => {
    const record = allLabels.value.find(l => l.title === name);
    const color = record?.color || '#1f93ff';
    return { name, color, textColor: getContrastingTextColor(color) };
  });
});
const priority = computed(() => conversation.value?.priority || '');

const priorityConfig = computed(() => {
  const map = {
    urgent: { icon: 'i-lucide-alert-circle', class: 'text-n-ruby-11' },
    high: { icon: 'i-lucide-arrow-up', class: 'text-n-ruby-11' },
    medium: { icon: 'i-lucide-minus', class: 'text-n-amber-11' },
    low: { icon: 'i-lucide-arrow-down', class: 'text-n-blue-11' },
  };
  return map[priority.value] || null;
});

const statusConfig = computed(() => {
  const map = {
    open: {
      label: t('INTERNAL_CHAT.CONVERSATION_MENTION.STATUS.OPEN'),
      class: 'bg-n-teal-3 text-n-teal-11',
    },
    resolved: {
      label: t('INTERNAL_CHAT.CONVERSATION_MENTION.STATUS.RESOLVED'),
      class: 'bg-n-slate-3 text-n-slate-11',
    },
    pending: {
      label: t('INTERNAL_CHAT.CONVERSATION_MENTION.STATUS.PENDING'),
      class: 'bg-n-amber-3 text-n-amber-11',
    },
    snoozed: {
      label: t('INTERNAL_CHAT.CONVERSATION_MENTION.STATUS.SNOOZED'),
      class: 'bg-n-blue-3 text-n-blue-11',
    },
  };
  return map[status.value] || map.open;
});

const conversationLink = computed(() =>
  frontendURL(
    conversationUrl({ accountId: props.accountId, id: props.displayId })
  )
);

function navigate() {
  router.push(conversationLink.value);
}

async function fetchConversation() {
  const cached = conversationCache.get(props.displayId);
  if (cached) {
    conversation.value = cached;
    return;
  }

  try {
    const { data } = await ConversationAPI.show(props.displayId);
    if (data) {
      conversationCache.set(props.displayId, data);
      conversation.value = data;
    }
  } catch {
    fetchFailed.value = true;
  }
}

onMounted(fetchConversation);
</script>

<template>
  <div>
    <div
      v-if="fetchFailed"
      class="mt-2 flex items-center gap-2 rounded-lg border border-n-slate-5 bg-n-alpha-1 px-3 py-2.5 text-sm text-n-slate-10"
    >
      <Icon icon="i-lucide-lock" class="size-4 flex-shrink-0" />
      <span>
        {{ t('INTERNAL_CHAT.CONVERSATION_MENTION.NO_ACCESS') }}
      </span>
    </div>
    <a
      v-else-if="conversation"
      :href="conversationLink"
      class="mt-2 block rounded-lg border border-n-slate-5 bg-n-solid-2 px-3 py-2.5 text-sm no-underline hover:bg-n-alpha-1 transition-colors"
      @click.exact.prevent="navigate"
    >
      <!-- Top row: contact + id + status -->
      <div class="flex items-center gap-2">
        <Avatar
          :name="contactName"
          :src="contactThumbnail"
          :size="28"
          rounded-full
        />
        <div class="min-w-0 flex-1">
          <span class="font-medium text-n-slate-12">{{ contactName }}</span>
          <span class="ml-1 text-n-slate-10">
            {{ t('INTERNAL_CHAT.CONVERSATION_MENTION.PREFIX') }}{{ displayId }}
          </span>
        </div>
        <Icon
          v-if="priorityConfig"
          :icon="priorityConfig.icon"
          class="size-3.5 flex-shrink-0"
          :class="priorityConfig.class"
        />
        <span
          class="flex-shrink-0 rounded-full px-1.5 py-0.5 text-xs font-medium"
          :class="statusConfig.class"
        >
          {{ statusConfig.label }}
        </span>
      </div>

      <!-- Labels -->
      <div v-if="labels.length" class="mt-1.5 flex flex-wrap gap-1">
        <span
          v-for="label in labels"
          :key="label.name"
          :style="{
            backgroundColor: label.color,
            color: label.textColor,
          }"
          class="rounded-full px-1.5 py-0.5 text-[10px] font-medium"
        >
          {{ label.name }}
        </span>
      </div>

      <!-- Last message preview -->
      <div
        v-if="lastMessage"
        class="mt-1.5 flex items-start gap-1 text-xs text-n-slate-10 leading-relaxed"
      >
        <Icon
          :icon="
            isLastMessageOutgoing
              ? 'i-lucide-arrow-right'
              : 'i-lucide-arrow-left'
          "
          class="mt-0.5 size-3 flex-shrink-0"
          :class="isLastMessageOutgoing ? 'text-n-blue-11' : 'text-n-slate-10'"
        />
        <span class="line-clamp-2">{{ lastMessage }}</span>
      </div>

      <!-- Bottom row: inbox + assignee + time -->
      <div class="mt-1.5 flex items-center gap-2 text-xs text-n-slate-10">
        <span v-if="inboxName" class="truncate max-w-32">{{ inboxName }}</span>
        <span v-if="inboxName && assigneeName" class="h-3 w-px bg-n-slate-7" />
        <span v-if="assigneeName" class="truncate max-w-32">
          {{ assigneeName }}
        </span>
        <span class="ml-auto flex-shrink-0">{{ lastActivityAt }}</span>
        <Icon
          icon="i-lucide-external-link"
          class="size-3 text-n-slate-9 flex-shrink-0"
        />
      </div>
    </a>
  </div>
</template>
