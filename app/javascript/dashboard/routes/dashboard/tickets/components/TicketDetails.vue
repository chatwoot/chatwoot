<template>
  <section class="ticket-page bg-white dark:bg-slate-900">
    <div class="flex flex-col w-full">
      <div
        class="flex items-center justify-between py-4 px-4 pb-3 border-b border-slate-75 dark:border-slate-700"
      >
        <h1
          class="text-xl break-words overflow-hidden whitespace-nowrap text-ellipsis text-black-900 dark:text-slate-100 mb-0"
          title="Tickets"
        >
          {{ $t('TICKETS.TITLE') }} # {{ ticket.id }}
        </h1>
      </div>
      <div class="p-4 flex flex-col w-full">
        <div>
          <div class="flex justify-end gap-2">
            <woot-button
              v-if="!ticket.assigned_to"
              class="button clear"
              @click="assignToMe"
            >
              {{ $t('TICKETS.ASSIGNEE.ASSIGNEE_TO_ME') }}
            </woot-button>
            <woot-button class="button" color-scheme="primary">
              {{ $t('TICKETS.RESOLVE') }}
            </woot-button>
          </div>
        </div>
        <div class="pt-3 flex">
          <span class="ml-2 text-sm text-slate-600">
            {{ $t('TICKETS.ASSIGNEE.ASSIGNED_TO') }}:
            <strong>{{ assigneeFormatted }}</strong>
          </span>
        </div>
        <div class="py-1 flex">
          <span class="ml-2 text-sm text-slate-600">
            {{ $t('TICKETS.DESCRIPTION') }}
            <strong>{{ ticket.description }}</strong>
          </span>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'TicketDetails',
  props: {
    ticketId: {
      type: [Number, String],
      required: true,
    },
  },
  data: () => ({}),
  computed: {
    ...mapGetters({
      ticket: 'tickets/getTicket',
      currentUserId: 'getCurrentUserID',
    }),
    assigneeFormatted() {
      if (!this.ticket.assigned_to)
        return this.$t('TICKETS.ASSIGNEE_FILTER.UNASSIGNED');
      if (this.ticket.assigned_to.id === this.currentUserId)
        return this.$t('TICKETS.ASSIGNEE_FILTER.ME');

      return this.ticket.assigned_to.name;
    },
  },
  methods: {
    assignToMe() {
      this.$store.dispatch('tickets/assign', {
        ticketId: this.ticketId,
        assigneeId: this.currentUserId,
      });
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
