<template>
  <div class="sidebar-labels-wrap">
    <div v-if="!labelUiFlags.isFetching" class="conversation-tickets-list">
      <!-- list tickets labels -->
      <div v-if="tickets.length">
        <ticket-item
          v-for="ticket in tickets"
          :key="ticket.id"
          :ticket="ticket"
        />
      </div>
      <p v-else class="text-center text-slate-800 dark:text-slate-200">
        {{ $t('TICKETS.NO_TICKETS') }}
      </p>
    </div>
    <spinner v-else />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import TicketItem from './TicketItem.vue';

export default {
  components: {
    Spinner,
    TicketItem,
  },
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      tickets: 'tickets/getTickets',
      labelUiFlags: 'tickets/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('tickets/getConversationTickets', this.conversationId);
  },
};
</script>

<style lang="scss" scoped>
.sidebar-labels-wrap {
  margin-bottom: 0;
}
.conversation-tickets-list {
  width: 100%;
}

.error {
  color: var(--r-500);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
}
</style>
