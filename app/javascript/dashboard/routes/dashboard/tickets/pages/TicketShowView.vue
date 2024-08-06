<template>
  <section class="ticket-page bg-white dark:bg-slate-900">
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
  </section>
</template>

<script>
export default {
  name: 'TicketShowView',
};
</script>

<style lang="scss" scoped>
.ticket-page {
  display: flex;
  width: 100%;
  height: 100%;
}
</style>
