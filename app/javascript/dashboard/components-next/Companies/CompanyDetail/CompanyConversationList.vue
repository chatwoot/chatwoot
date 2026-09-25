<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { fromUnixTime, isToday, isYesterday } from 'date-fns';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';
import { dateFormat } from 'shared/helpers/timeHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import ConversationCardExpanded from 'dashboard/components-next/Conversation/ConversationCard/ConversationCardExpanded.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversations: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  hasMore: { type: Boolean, default: false },
  // True when filters are applied, to tailor the empty state.
  filtered: { type: Boolean, default: false },
  emptyMessage: { type: String, default: '' },
});

const emit = defineEmits(['loadMore']);

const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();
const contactById = useMapGetter('contacts/getContact');
const inboxById = useMapGetter('inboxes/getInbox');

const dayLabel = time => {
  const date = fromUnixTime(time);
  if (isToday(date)) return t('COMPANIES.DETAIL.ACTIVITY.TODAY');
  if (isYesterday(date)) return t('COMPANIES.DETAIL.ACTIVITY.YESTERDAY');
  return dateFormat(time, 'EEEE, MMM d');
};

const groups = computed(() =>
  props.conversations.reduce((result, conversation) => {
    const label = dayLabel(conversation.timestamp);
    const group = result.at(-1);
    if (group?.label === label) group.conversations.push(conversation);
    else result.push({ label, conversations: [conversation] });
    return result;
  }, [])
);

const conversationContact = conversation => {
  const sender = conversation.meta?.sender || {};
  const contact = sender.id ? contactById.value(sender.id) : {};
  return contact?.id ? contact : sender;
};

const conversationInbox = conversation =>
  inboxById.value(conversation.inbox_id) || {};

const openConversation = (conversation, event) => {
  const path = frontendURL(
    conversationUrl({ accountId: accountId.value, id: conversation.id })
  );
  if (event.metaKey || event.ctrlKey) {
    window.open(
      `${window.chatwootConfig.hostURL}${path}`,
      '_blank',
      'noopener,noreferrer'
    );
    return;
  }
  router.push({ path });
};
</script>

<template>
  <section class="flex flex-col gap-4">
    <div
      v-if="isLoading && !conversations.length"
      class="flex justify-center py-12"
    >
      <Spinner />
    </div>

    <p
      v-else-if="!conversations.length"
      class="px-6 py-10 text-sm text-center border border-dashed rounded-xl border-n-weak text-n-slate-11"
    >
      {{
        filtered
          ? t('COMPANIES.DETAIL.ACTIVITY.NO_MATCHING_CONVERSATIONS')
          : emptyMessage || t('COMPANIES.DETAIL.ACTIVITY.EMPTY_CONVERSATIONS')
      }}
    </p>

    <div v-else class="flex flex-col gap-6">
      <div v-for="group in groups" :key="group.label" class="flex flex-col">
        <h3 class="pb-1 text-label-small text-n-slate-10">
          {{ group.label }}
        </h3>
        <div class="-mx-3">
          <ConversationCardExpanded
            v-for="conversation in group.conversations"
            :key="conversation.id"
            :chat="conversation"
            :current-contact="conversationContact(conversation)"
            :assignee="conversation.meta?.assignee || {}"
            :inbox="conversationInbox(conversation)"
            :selectable="false"
            conversation-first
            show-assignee
            show-inbox-name
            @click="openConversation(conversation, $event)"
          />
        </div>
      </div>
    </div>

    <Button
      v-if="hasMore && conversations.length"
      :label="t('COMPANIES.DETAIL.ACTIVITY.LOAD_MORE')"
      variant="faded"
      color="slate"
      size="sm"
      class="self-center"
      :is-loading="isLoading"
      @click="emit('loadMore')"
    />
  </section>
</template>
