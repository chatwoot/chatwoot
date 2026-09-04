<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dateFormat } from 'shared/helpers/timeHelper';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MessagePreview from './MessagePreview.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  to: {
    type: String,
    required: true,
  },
  direction: {
    type: String,
    required: true,
    validator: value => ['older', 'newer'].includes(value),
  },
});

const { t } = useI18n();

const isOlder = computed(() => props.direction === 'older');

const label = computed(() =>
  isOlder.value
    ? t('CONVERSATION.CONTACT_HISTORY.OLDER')
    : t('CONVERSATION.CONTACT_HISTORY.NEWER')
);

const startedAt = computed(() =>
  dateFormat(props.conversation.created_at, 'MMM d, yyyy')
);

const startedAtWithTime = computed(() =>
  dateFormat(props.conversation.created_at, 'MMM d, yyyy · h:mm a')
);

const lastMessage = computed(() => getLastMessage(props.conversation));
</script>

<template>
  <li class="flex justify-center my-4 list-none">
    <router-link
      v-tooltip.top="startedAtWithTime"
      :to="to"
      class="inline-flex items-center h-8 gap-2 px-3 transition-colors border rounded-full shadow-sm group max-w-lg border-n-weak bg-n-solid-1 hover:border-n-brand focus-visible:outline-none focus-visible:border-n-brand"
    >
      <Icon
        :icon="isOlder ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
        class="flex-shrink-0 transition-transform size-3.5 text-n-slate-11 group-hover:text-n-brand"
        :class="
          isOlder
            ? 'group-hover:-translate-y-0.5'
            : 'group-hover:translate-y-0.5'
        "
      />
      <span class="flex-shrink-0 text-sm font-medium text-n-slate-12">
        {{ label }}
      </span>
      <template v-if="lastMessage">
        <span class="flex-shrink-0 w-px h-3.5 bg-n-strong" />
        <MessagePreview
          :message="lastMessage"
          :show-message-type="false"
          class="min-w-0 text-xs text-n-slate-11"
        />
      </template>
      <span class="flex-shrink-0 text-xs whitespace-nowrap text-n-slate-10">
        {{ startedAt }}
      </span>
    </router-link>
  </li>
</template>
