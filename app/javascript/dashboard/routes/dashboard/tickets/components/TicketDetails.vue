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

        <more-actions-dropdown
          :ticket-id="ticketId"
          :current-user-id="currentUserId"
        />
      </div>
      <div class="p-4 flex flex-col w-full">
        <woot-button class="button" color-scheme="primary">
          {{ $t('TICKETS.RESOLVE') }}
        </woot-button>
        <span class="ml-2 text-sm text-slate-600">
          {{ $t('TICKETS.ASSIGNEE.ASSIGNED_TO') }}:
          <strong>{{ assigneeFormatted }}</strong>
        </span>
        <span class="ml-2 text-sm text-slate-600">
          {{ $t('TICKETS.DESCRIPTION') }}
          <strong>{{ ticket.description }}</strong>
        </span>
        <span class="ml-2 text-sm text-slate-600">
          {{ $t(`TICKETS.STATUS.TITLE`) }}
          <strong>{{
            $t(`TICKETS.STATUS.${ticket.status.toUpperCase()}`)
          }}</strong>
        </span>
        <span class="ml-2 text-sm text-slate-600">
          {{ $t('TICKETS.LABELS.TITLE') }}:
          <woot-label
            v-for="label in ticket.labels"
            :key="label.id"
            :title="label.title"
            :description="label.description"
            :show-close="true"
            :color="label.color"
            variant="smooth"
          />
        </span>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import MoreActionsDropdown from './MoreActionsDropdown.vue';

export default {
  name: 'TicketDetails',
  components: {
    MoreActionsDropdown,
  },
  props: {
    ticketId: {
      type: [Number, String],
      required: true,
    },
  },
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
};
</script>

<style lang="scss" scoped>
.ticket-page {
  display: flex;
  width: 100%;
  height: 100%;
}
</style>
