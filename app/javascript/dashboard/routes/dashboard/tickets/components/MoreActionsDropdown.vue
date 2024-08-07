<template>
  <div class="relative" @clickaway="closeDropdown">
    <woot-button
      class="button"
      color-scheme="primary"
      :aria-expanded="isOpen"
      icon="arrow-swap"
      @click="toggleDropdown"
    />
    <div
      v-if="isOpen"
      class="absolute right-0 mt-2 py-2 w-48 bg-white border border-gray-100 rounded-md shadow-lg"
    >
      <a
        href="#"
        class="block px-4 py-2 text-gray-800 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-slate-700"
        @click="toggleEditMode"
      >
        {{ $t('TICKETS.ACTIONS.EDIT') }}
      </a>
      <a
        v-if="!ticket.assigned_to"
        href="#"
        class="block px-4 py-2 text-gray-800 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-slate-700"
        @click="assignToMe"
      >
        {{ $t('TICKETS.ASSIGNEE.ASSIGNEE_TO_ME') }}
      </a>
      <a
        href="#"
        class="block px-4 py-2 text-gray-800 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-slate-700"
        @click="resolveTicket"
      >
        {{ $t('TICKETS.RESOLVE') }}
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
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  name: 'MoreActionsDropdown',
  mixins: [clickaway],
  props: {
    ticket: {
      type: Object,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: true,
    },
  },
  data: () => ({
    isOpen: false,
  }),
  computed: {
    ...mapGetters({
      currentUserId: 'getCurrentUserID',
    }),
  },
  methods: {
    toggleDropdown() {
      this.isOpen = !this.isOpen;
    },
    closeDropdown() {
      this.isOpen = false;
    },
    assignToMe(e) {
      e.preventDefault();
      this.$store.dispatch('tickets/assign', this.ticket.id);
    },
    toggleEditMode() {
      this.$emit('toggle-edit-mode');
      this.closeDropdown();
    },
    deleteTicket() {
      this.$store.dispatch('tickets/delete', this.ticket.id);
      this.closeDropdown();
    },
    resolveTicket() {
      this.$store.dispatch('tickets/resolve', this.ticket.id);
      this.closeDropdown();
    },
  },
};
</script>
