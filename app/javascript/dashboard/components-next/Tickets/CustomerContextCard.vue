<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import camelcaseKeys from 'camelcase-keys';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import TicketsAPI from 'dashboard/api/tickets';

import TicketDueDate from './TicketDueDate.vue';
import TicketStatusChip from './TicketStatusChip.vue';

const props = defineProps({
  contactId: {
    type: [Number, String],
    default: null,
  },
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

// The contact conversations endpoint returns the 20 most recent, so a busier
// customer is shown as "20+" rather than an undercount.
const CONVERSATIONS_LIMIT = 20;

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const accountId = useMapGetter('getCurrentAccountId');
const contactGetter = useMapGetter('contacts/getContact');
const contactConversationsGetter = useMapGetter(
  'contactConversations/getContactConversation'
);

const openTickets = ref([]);
const isLoading = ref(false);

const conversations = computed(() =>
  contactConversationsGetter.value(props.contactId)
);

const conversationsLabel = computed(() =>
  conversations.value.length >= CONVERSATIONS_LIMIT
    ? `${CONVERSATIONS_LIMIT}+`
    : `${conversations.value.length}`
);

const lastActivityAt = computed(
  () => contactGetter.value(props.contactId)?.last_activity_at
);

const lastActivityLabel = computed(() =>
  lastActivityAt.value ? dynamicTime(lastActivityAt.value) : '—'
);

const isCurrentConversation = ticket =>
  String(ticket.conversationId) === String(props.conversationId);

const load = async () => {
  if (!props.contactId) return;

  isLoading.value = true;
  try {
    const [{ data }] = await Promise.all([
      TicketsAPI.get({ contact_id: props.contactId, settled: false }),
      store.dispatch('contactConversations/get', props.contactId),
    ]);
    openTickets.value = camelcaseKeys(data.payload, { deep: true });
  } catch (error) {
    openTickets.value = [];
    useAlert(t('TICKETS.CONTEXT.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const openConversation = ticket => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversation_id: ticket.conversationId,
    },
  });
};

watch(() => props.contactId, load);

onMounted(load);
</script>

<template>
  <div class="flex flex-col gap-4 px-2 py-3">
    <section class="flex flex-col gap-2">
      <h4 class="mb-0 text-sm font-medium text-n-slate-12">
        {{ t('TICKETS.CONTEXT.OPEN_CASES') }}
      </h4>
      <div v-if="isLoading" class="flex flex-col gap-3">
        <div v-for="row in 2" :key="row" class="flex flex-col gap-1.5">
          <div class="w-full h-4 rounded bg-n-slate-3 animate-pulse" />
          <div class="w-1/2 h-4 rounded bg-n-slate-3 animate-pulse" />
        </div>
      </div>
      <p v-else-if="!openTickets.length" class="mb-0 text-sm text-n-slate-11">
        {{ t('TICKETS.CONTEXT.EMPTY') }}
      </p>
      <ul v-else class="flex flex-col gap-1 m-0 list-none">
        <li v-for="ticket in openTickets" :key="ticket.id">
          <button
            class="flex flex-col w-full gap-1 px-2 py-1.5 -mx-2 text-left rounded-lg hover:bg-n-alpha-1"
            @click="openConversation(ticket)"
          >
            <span class="flex items-center w-full gap-1.5">
              <span class="text-sm tabular-nums text-n-slate-11">
                #{{ ticket.conversationId }}
              </span>
              <span
                class="flex-1 min-w-0 text-sm truncate text-n-slate-12"
                :title="ticket.subject"
              >
                {{ ticket.subject }}
              </span>
            </span>
            <span class="flex flex-wrap items-center gap-2 text-sm">
              <TicketStatusChip :status-category="ticket.statusCategory" />
              <TicketDueDate v-if="ticket.dueAt" :due-at="ticket.dueAt" />
              <span
                v-if="isCurrentConversation(ticket)"
                class="text-n-slate-10"
              >
                {{ t('TICKETS.CONTEXT.CURRENT') }}
              </span>
            </span>
          </button>
        </li>
      </ul>
    </section>
    <section class="pt-3 border-t border-n-weak">
      <div v-if="isLoading" class="flex flex-col gap-1.5">
        <div class="w-2/3 h-4 rounded bg-n-slate-3 animate-pulse" />
        <div class="w-1/2 h-4 rounded bg-n-slate-3 animate-pulse" />
      </div>
      <dl v-else class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 mb-0 text-sm">
        <dt class="text-n-slate-11">
          {{ t('TICKETS.CONTEXT.CONVERSATIONS') }}
        </dt>
        <dd class="mb-0 tabular-nums text-n-slate-12">
          {{ conversationsLabel }}
        </dd>
        <dt class="text-n-slate-11">
          {{ t('TICKETS.CONTEXT.LAST_ACTIVITY') }}
        </dt>
        <dd class="mb-0 text-n-slate-12">{{ lastActivityLabel }}</dd>
      </dl>
    </section>
  </div>
</template>
