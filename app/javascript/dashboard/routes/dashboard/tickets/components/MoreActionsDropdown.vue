<template>
  <div class="relative" @clickaway="closeDropdown">
    <woot-button
      class="button"
      variant="clear"
      :aria-expanded="isOpen"
      @click="toggleDropdown"
    >
      +
    </woot-button>
    <div
      v-if="isOpen"
      class="absolute right-0 mt-2 py-2 w-48 bg-white border border-gray-200 rounded-md shadow-lg dark:bg-slate-200"
    >
      <a
        href="#"
        class="block px-4 py-2 text-gray-800 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-slate-200"
        @click="assignToMe"
      >
        {{ $t('TICKETS.ASSIGNEE.ASSIGNEE_TO_ME') }}
      </a>
      <a
        href="#"
        class="block px-4 py-2 text-red-600 hover:bg-red-100 dark:text-red-400 dark:hover:bg-red-700"
        @click="deleteTicket"
      >
        {{ $t('TICKETS.ACTIONS.DELETE') }}
      </a>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';

export default {
  name: 'MoreActionsDropdown',
  mixins: [clickaway],
  props: {
    ticketId: {
      type: [Number, String],
      required: true,
    },
    currentUserId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      isOpen: false,
    };
  },
  methods: {
    toggleDropdown() {
      this.isOpen = !this.isOpen;
    },
    closeDropdown() {
      // eslint-disable-next-line no-console
      console.log('close dropdown');
      this.isOpen = false;
    },
    assignToMe() {
      this.$store.dispatch('tickets/assign', {
        ticketId: this.ticketId,
        assigneeId: this.currentUserId,
      });
      this.closeDropdown();
    },
    deleteTicket() {
      this.$store.dispatch('tickets/delete', this.ticketId);
      this.closeDropdown();
    },
  },
};
</script>

<style scoped></style>
