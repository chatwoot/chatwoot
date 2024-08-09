<template>
  <section class="ticket-page bg-white dark:bg-slate-900">
    <div class="flex flex-row w-full">
      <div class="flex-col w-full" :class="{ 'w-[70%]': !!ticket }">
        <div class="flex px-3">
          <ticket-type-tabs
            :tabs="assigneeTabItems"
            :active-tab="activeAssigneeTab"
            @tab-change="updateAssigneeTab"
          />
        </div>
        <div class="flex flex-col w-full h-5/6">
          <virtual-list
            v-if="ticketList.length > 0"
            ref="ticketVirtualList"
            class="w-full overflow-y-scroll h-full"
            footer-tag="div"
            :data-key="'id'"
            :data-sources="ticketList"
            :data-component="itemComponent"
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
      <div
        v-if="ticket"
        class="flex flex-col w-[30%] border-l border-slate-50 dark:border-slate-800"
      >
        <ticket-details :ticket-id="ticket.id" />
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
import TicketDetails from './components/TicketDetails.vue';

export default {
  name: 'TicketView',
  components: {
    // eslint-disable-next-line vue/no-unused-components
    TicketItemComponent,
    TicketTypeTabs,
    TicketDetails,
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
    };
  },
  computed: {
    ...mapGetters({
      ticketListLoading: 'tickets/getUIFlagsPage',
      ticketStats: 'tickets/getStats',
      ticketLists: 'tickets/getTickets',
      ticket: 'tickets/getTicket',
    }),
    selectedLabel() {
      return this.$route.query.label || null;
    },
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
  watch: {
    selectedLabel(newLabel) {
      this.fetchTickets(newLabel);
    },
  },
  mounted() {
    this.fetchTickets(this.selectedLabel);
  },
  methods: {
    updateAssigneeTab(selectedTab) {
      this.activeAssigneeTab = selectedTab;
      // this.fetchTickets();
    },
    fetchTickets(label) {
      this.$store.dispatch('tickets/getAllTickets', label);
    },
    loadMoreTickets() {
      if (!this.ticketListLoading.isFetching) {
        // eslint-disable-next-line no-console
        console.log('load more');
        //   this.fetchTickets();
      }
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
