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
            {{ $t('TICKETS.TITLE') }} # {{ ticketId }}
          </h1>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'TicketShowView',
  props: {
    ticketId: {
      type: Number,
      required: true,
    },
  },
  data: () => ({
    ticket: {},
  }),

  methods: {
    async getTicket() {
      const { data } = await this.$store.dispatch('tickets/get', this.ticketId);
      this.ticket = data;
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
