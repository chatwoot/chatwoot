<template>
  <section class="ticket-page bg-white dark:bg-slate-900">
    <div class="flex flex-col w-full">
      <div
        class="flex items-center justify-between py-4 px-4 pb-3 border-b border-slate-75 dark:border-slate-700"
      >
        <div class="flex max-w-[85%] justify-center items-center">
          <h1
            class="text-xl break-words overflow-hidden whitespace-nowrap text-ellipsis text-black-900 dark:text-slate-100 mb-0"
            title="Tickets"
          >
            Tickets
          </h1>
          <span
            class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
          >
            {{ $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${activeStatus}.TEXT`) }}
          </span>
        </div>
      </div>
      <div class="flex">
        <ticket-type-tabs
          :tabs="assigneeTabItems"
          :active-tab="activeAssigneeTab"
          @tab-change="updateAssigneeTab"
        />
      </div>
      <div class="flex">
        <div class="flex flex-col w-full">
          <virtual-list
            ref="ticketVirtualList"
            :data-key="'id'"
            :data-sources="ticketList"
            :data-component="itemComponent"
            class="w-full overflow-auto h-full"
            footer-tag="div"
          >
            <template #footer>
              <div v-if="ticketListLoading.isFetching" class="text-center">
                <span class="spinner mt-4 mb-4" />
              </div>
              <p v-if="showEndOfListMessage" class="text-center text-muted p-4">
                {{ $t('TICKETS.LIST.EOF') }}
              </p>
              <intersection-observer
                v-if="!showEndOfListMessage && !ticketListLoading.isFetching"
                :options="infiniteLoaderOptions"
                @observed="loadMoreTickets"
              />
            </template>
          </virtual-list>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import VirtualList from 'vue-virtual-scroll-list';
import TicketTypeTabs from './components/TicketTypeTabs.vue';
import TicketItemComponent from './components/TicketItemComponent.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';

export default {
  name: 'TicketView',
  components: {
    // eslint-disable-next-line vue/no-unused-components
    TicketItemComponent,
    TicketTypeTabs,
    IntersectionObserver,
    VirtualList,
  },
  data() {
    return {
      itemComponent: TicketItemComponent,
      activeAssigneeTab: 'open',
      activeStatus: 'open',
      infiniteLoaderOptions: {
        root: null,
        rootMargin: '100px 0px 100px 0px',
      },
      selectedTickets: [],
      ticketLists: [
        {
          id: 1,
          title: 'All',
          description: 'All tickets',
          status: 'open',
          resolved: false,
          assignee_type: 'me',
          priority: 1,
          conversations_count: 2,
          labels: ['sales'],
          created_at: '2023-07-26T00:00:00.000Z',
        },
        {
          id: 2,
          title: 'Open',
          description: 'Open tickets',
          status: 'open',
          resolved: false,
          assignee_type: 'me',
          priority: 1,
          conversations_count: 2,
          labels: ['sales'],
          created_at: '2023-07-26T00:00:00.000Z',
        },
        {
          id: 3,
          title: 'Resolved',
          description: 'Resolved tickets',
          status: 'resolved',
          resolved: true,
          assignee_type: 'me',
          priority: 1,
          conversations_count: 2,
          labels: ['sales'],
          created_at: '2023-07-26T00:00:00.000Z',
        },
        {
          id: 4,
          title: 'My tickets',
          description: 'My tickets',
          status: 'closed',
          resolved: false,
          assignee_type: 'me',
          priority: 1,
          conversations_count: 2,
          labels: ['sales'],
          created_at: '2023-07-26T00:00:00.000Z',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      ticketListLoading: 'tickets/getUIFlagsPage',
      ticketStats: 'tickets/getStats',
    }),
    assigneeTabItems() {
      return [
        { key: 'open', name: 'Open', count: this.ticketStats.open },
        { key: 'closed', name: 'Closed', count: this.ticketStats.closed },
        { key: 'all', name: 'All', count: this.ticketStats.all },
      ];
    },
    ticketList() {
      let ticketList = [];
      if (this.activeAssigneeTab === 'open') {
        ticketList = this.ticketLists.filter(
          ticket => ticket.status === 'open'
        );
      } else if (this.activeAssigneeTab === 'closed') {
        ticketList = this.ticketLists.filter(
          ticket => ticket.status === 'closed'
        );
      } else {
        ticketList = this.ticketLists;
      }
      return ticketList;
    },
    showEndOfListMessage() {
      return this.ticketList.length && !this.ticketListLoading.isFetching;
    },
  },
  methods: {
    updateAssigneeTab(selectedTab) {
      this.activeAssigneeTab = selectedTab;
      this.fetchTickets();
    },
    fetchTickets() {
      this.$store.dispatch('fetchAllTickets');
    },
    loadMoreTickets() {
      if (!this.ticketListLoading.isFetching) {
        this.fetchTickets();
      }
    },
    isTicketSelected(ticketId) {
      return this.selectedTickets.includes(ticketId);
    },
  },
};
</script>

<style lang="scss" scoped>
.ticket-page {
  display: flex;
  width: 100%;
  height: 100%;
}
</style>
