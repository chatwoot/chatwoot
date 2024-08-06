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
            {{ $t('TICKETS.TITLE') }}
          </h1>
          <span
            class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
          >
            {{ $t(`TICKETS.STATUS.OPEN`) }}
          </span>
        </div>
      </div>
      <div class="flex px-3">
        <ticket-type-tabs
          :tabs="assigneeTabItems"
          :active-tab="activeAssigneeTab"
          @tab-change="updateAssigneeTab"
        />
      </div>
      <div class="flex flex-col w-full">
        <virtual-list
          v-if="ticketList.length > 0"
          ref="ticketVirtualList"
          :data-key="'id'"
          :data-sources="ticketList"
          :data-component="itemComponent"
          class="w-full overflow-auto h-1/2"
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
        <p v-else class="text-center text-muted p-4">
          {{ $t('TICKETS.LIST.NO_TICKETS') }}
        </p>
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
    };
  },
  computed: {
    ...mapGetters({
      ticketListLoading: 'tickets/getUIFlagsPage',
      ticketStats: 'tickets/getStats',
      ticketLists: 'tickets/getTickets',
    }),
    assigneeTabItems() {
      return [
        {
          key: 'open',
          name: this.$t('TICKETS.STATUS.PENDING'),
          count: this.ticketStats.pending,
        },
        {
          key: 'closed',
          name: this.$t('TICKETS.STATUS.RESOLVED'),
          count: this.ticketStats.resolved,
        },
        {
          key: 'all',
          name: this.$t('TICKETS.STATUS.ALL'),
          count: this.ticketStats.all,
        },
      ];
    },
    ticketList() {
      let ticketList = [];
      if (this.activeAssigneeTab === 'open') {
        ticketList = this.ticketLists.filter(
          ticket => ticket.status === 'pending'
        );
      } else if (this.activeAssigneeTab === 'closed') {
        ticketList = this.ticketLists.filter(
          ticket => ticket.status === 'resolved'
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
  mounted() {
    this.fetchTickets();
  },
  methods: {
    updateAssigneeTab(selectedTab) {
      this.activeAssigneeTab = selectedTab;
      // this.fetchTickets();
    },
    fetchTickets() {
      this.$store.dispatch('tickets/getAllTickets');
    },
    loadMoreTickets() {
      if (!this.ticketListLoading.isFetching) {
        // eslint-disable-next-line no-console
        console.log('load more');
        //   this.fetchTickets();
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
