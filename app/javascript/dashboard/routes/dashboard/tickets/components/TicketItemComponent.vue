<template>
  <div
    class="ticket-card"
    :class="{ active: isActiveTicket, unread: hasUnread }"
    @click="onCardClick"
    @contextmenu="openContextMenu($event)"
  >
    <div class="ticket-details">
      <h4 class="ticket-title">{{ source.title }}</h4>
      <p class="ticket-description">{{ source.description }}</p>
      <span class="ticket-status">{{ source.status }}</span>
      <span class="ticket-priority">{{ source.priority }}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TicketItemComponent',
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
    isActiveTicket() {
      const selectedTicket = this.$store.getters.getSelectedTicket;
      return selectedTicket && selectedTicket.id === this.source.id;
    },
    hasUnread() {
      return this.source.unread;
    },
  },
  methods: {
    onCardClick() {
      this.$emit('select-ticket', this.source.id);
    },
    openContextMenu(event) {
      event.preventDefault();
      this.$emit('context-menu-toggle', { x: event.pageX, y: event.pageY });
    },
  },
};
</script>

<style scoped>
.ticket-card {
  padding: 10px;
  border-bottom: 1px solid #ccc;
  cursor: pointer;
}
.ticket-card.active {
  background-color: #f0f0f0;
}
.ticket-card.unread {
  font-weight: bold;
}
.ticket-details {
  display: flex;
  justify-content: space-between;
}
</style>
