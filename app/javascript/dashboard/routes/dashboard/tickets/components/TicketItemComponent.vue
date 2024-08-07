<template>
  <div
    class="ticket-card"
    :class="{ active: isActiveTicket, unread: hasUnread }"
    @click="onCardClick"
  >
    <div class="ticket-details">
      <div
        class="px-0 py-3 border-b group-hover:border-transparent border-slate-50 dark:border-slate-800/75 columns"
      >
        <div class="flex justify-between">
          <div class="flex gap-2 ml-2 rtl:mr-2 rtl:ml-0 flex-col">
            <span class="truncate text-lg font-bold">
              {{ source.title }} # {{ source.id }}
            </span>
            <span class="truncate text-md">
              {{ source.description }}
            </span>
            <span class="text-sm text-slate-600 dark:text-slate-300">
              {{ $t('TICKETS.ASSIGNEE.ASSIGNED_TO') }}:
              <strong>{{ textAssignee }}</strong>
            </span>
          </div>

          <div
            class="flex flex-col conversation--meta right-4 top-4 justify-space-between"
          >
            <span class="ml-auto font-normal leading-4 text-black-600 text-xxs">
              <time-ago
                :last-activity-timestamp="updatedAtTimestamp"
                :created-at-timestamp="createdAtTimestamp"
              />
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';

export default {
  name: 'TicketItemComponent',
  components: {
    TimeAgo,
  },
  props: {
    index: {
      type: Number,
      default: 0,
    },
    source: {
      type: Object,
      default() {
        return {};
      },
    },
  },
  computed: {
    ...mapGetters({
      currentUserId: 'getCurrentUserID',
      ticketsUIFlags: 'tickets/getUIFlags',
    }),
    isActiveTicket() {
      const selectedTicket = this.$store.getters.getSelectedTicket;
      return selectedTicket && selectedTicket.id === this.source.id;
    },
    hasUnread() {
      return this.source.unread;
    },
    updatedAtTimestamp() {
      return Math.floor(Date.now() / 1000);
    },
    createdAtTimestamp() {
      return this.source.created_at
        ? Math.floor(new Date(this.source.created_at).getTime() / 1000)
        : Math.floor(Date.now() / 1000);
    },
    textAssignee() {
      if (!this.source.assigned_to)
        return this.$t('TICKETS.ASSIGNEE_FILTER.UNASSIGNED');
      if (this.source.assigned_to.id === this.currentUserId)
        return this.$t('TICKETS.ASSIGNEE_FILTER.ME');

      return this.source.assigned_to.name;
    },
  },
  methods: {
    onCardClick() {
      this.$store.dispatch('tickets/get', this.source.id);
    },
  },
};
</script>

<style scoped>
.ticket-card {
  @apply cursor-pointer;

  padding: 10px;
}
.ticket-card.active {
  background-color: #f0f0f0;
}
.ticket-card.unread {
  font-weight: bold;
}
.ticket-details {
  display: flex;
  align-items: center;
}
</style>
