<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { useTicketsStore } from 'dashboard/stores/tickets';

import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import TicketsFilterBar from 'dashboard/components-next/Tickets/TicketsFilterBar.vue';
import TicketsTable from 'dashboard/components-next/Tickets/TicketsTable.vue';
import {
  TICKETS_PER_PAGE,
  TICKET_STATUS_CATEGORIES,
  TICKET_TYPES,
} from 'dashboard/components-next/Tickets/constants';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const ticketsStore = useTicketsStore();

const accountId = useMapGetter('getCurrentAccountId');
const currentUserId = useMapGetter('getCurrentUserID');

const tickets = computed(() => ticketsStore.records);
const meta = computed(() => ticketsStore.meta);
const isFetching = computed(() => ticketsStore.uiFlags.isFetching);

// Filters are seeded from the URL so a shared link restores the same view.
const statusCategory = ref(
  TICKET_STATUS_CATEGORIES.includes(route.query.status_category)
    ? route.query.status_category
    : null
);
const ticketType = ref(
  TICKET_TYPES.includes(route.query.ticket_type)
    ? route.query.ticket_type
    : null
);
const overdue = ref(route.query.overdue === 'true');
// `mine` travels as a flag rather than an agent id so a shared link means
// "assigned to whoever opens it", which is what the sidebar view promises.
const mine = ref(route.query.mine === 'true');
const currentPage = ref(Number(route.query.page) || 1);

const syncFiltersToUrl = () => {
  router.replace({
    query: {
      ...(statusCategory.value && { status_category: statusCategory.value }),
      ...(ticketType.value && { ticket_type: ticketType.value }),
      ...(overdue.value && { overdue: 'true' }),
      ...(mine.value && { mine: 'true' }),
      ...(currentPage.value > 1 && { page: currentPage.value }),
    },
  });
};

const fetchTickets = async () => {
  syncFiltersToUrl();
  try {
    await ticketsStore.fetchTickets({
      page: currentPage.value,
      ...(statusCategory.value && { status_category: statusCategory.value }),
      ...(ticketType.value && { ticket_type: ticketType.value }),
      ...(overdue.value && { overdue: true }),
      ...(mine.value &&
        currentUserId.value && { assignee_id: currentUserId.value }),
    });
  } catch (error) {
    useAlert(error.message);
  }
};

watch([statusCategory, ticketType, overdue, mine], () => {
  currentPage.value = 1;
  fetchTickets();
});

const onPageChange = page => {
  currentPage.value = page;
  fetchTickets();
};

const openTicket = ticket => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversation_id: ticket.conversationId,
    },
  });
};

onMounted(fetchTickets);
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="shrink-0">
      <div class="w-full px-6 pt-6">
        <h1 class="text-xl font-medium text-n-slate-12">
          {{ t('TICKETS.HEADER') }}
        </h1>
      </div>
      <TicketsFilterBar
        v-model:status-category="statusCategory"
        v-model:ticket-type="ticketType"
        v-model:overdue="overdue"
        v-model:mine="mine"
        class="pb-4 mx-6 mt-5 border-b border-n-weak"
      />
    </header>
    <main class="flex-1 min-w-0 px-6 overflow-y-auto">
      <TicketsTable
        :tickets="tickets"
        :is-loading="isFetching"
        :no-data-message="t('TICKETS.EMPTY_STATE')"
        @open="openTicket"
      />
    </main>
    <footer v-if="tickets.length" class="sticky bottom-0 shrink-0">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="meta.count"
        :items-per-page="TICKETS_PER_PAGE"
        @update:current-page="onPageChange"
      />
    </footer>
  </section>
</template>
