<template>
  <div
    class="tickets-per-agent-card"
    :class="{ active: isActiveTicket, unread: hasUnread }"
    @click="onCardClick"
    @contextmenu="openContextMenu($event)"
  >
    <div class="tickets-per-agent-card-details">
      <div
        class="px-0 py-3 border-b group-hover:border-transparent border-slate-50 dark:border-slate-800/75 columns"
      >
        <div class="flex justify-between">
          <div class="flex gap-2 ml-2 rtl:mr-2 rtl:ml-0 flex-col">
            <span class="truncate text-lg font-bold">
              {{ source.name }}
            </span>
            <span class="truncate text-md">
              {{ source.tickets }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TicketsPerAgentComponent',
  components: {},
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
    updatedAtTimestamp() {
      return Date.now();
    },
    createdAtTimestamp() {
      return this.source.created_at
        ? new Date(this.source.created_at).getTime()
        : Date.now();
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
.tickets-per-agent-card {
  padding: 10px;
}
.tickets-per-agent-card.active {
  background-color: #f0f0f0;
}
.tickets-per-agent-card.unread {
  font-weight: bold;
}
.tickets-per-agent-card-details {
  display: flex;
  align-items: center;
}
</style>
