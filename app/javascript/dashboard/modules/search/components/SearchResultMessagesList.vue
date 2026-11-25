<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { isBelowMessageSearchMinimum } from '../helpers/messageSearchMinimum';
import Icon from 'dashboard/components-next/icon/Icon.vue';

import SearchResultMessageItem from './SearchResultMessageItem.vue';
import SearchResultSection from './SearchResultSection.vue';
import MessageContent from './MessageContent.vue';

const props = defineProps({
  messages: {
    type: Array,
    default: () => [],
  },
  query: {
    type: String,
    default: '',
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  showTitle: {
    type: Boolean,
    default: true,
  },
});
const { t } = useI18n();

const accountId = useMapGetter('getCurrentAccountId');
const globalConfig = useMapGetter('globalConfig/get');

const minimumLength = computed(
  () => globalConfig.value?.messageSearchMinQueryLength
);
const isBelowMinimum = computed(() =>
  isBelowMessageSearchMinimum(props.query, minimumLength.value)
);

const getName = message => {
  return message && message.sender && message.sender.name
    ? message.sender.name
    : t('SEARCH.BOT_LABEL');
};
</script>

<template>
  <SearchResultSection
    :title="$t('SEARCH.SECTION.MESSAGES')"
    :empty="!messages.length && !isBelowMinimum"
    :query="query"
    :show-title="showTitle"
    :is-fetching="isFetching"
  >
    <div
      v-if="isBelowMinimum"
      class="flex items-start justify-center px-4 py-6 rounded-xl bg-n-slate-2 dark:bg-n-solid-1"
    >
      <Icon
        icon="i-lucide-info"
        class="text-n-slate-11 size-4 flex-shrink-0 mt-[3px]"
      />
      <p class="mx-2 my-0 text-center text-n-slate-11">
        {{ t('SEARCH.MESSAGE_MIN_QUERY_LENGTH', { count: minimumLength }) }}
      </p>
    </div>
    <ul v-if="messages.length" class="space-y-3 list-none">
      <li v-for="message in messages" :key="message.id">
        <SearchResultMessageItem
          :id="message.conversationId"
          :account-id="accountId"
          :inbox-id="message.inboxId"
          :created-at="message.createdAt"
          :message-id="message.id"
          :is-private="message.private"
          :attachments="message.attachments"
        >
          <MessageContent
            :author="getName(message)"
            :message="message"
            :search-term="query"
          />
        </SearchResultMessageItem>
      </li>
    </ul>
  </SearchResultSection>
</template>
