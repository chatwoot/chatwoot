<script>
export default {
  name: 'StatusInfo',
  props: {
    chat: {
      type: Object,
      required: true,
    },
  },
  computed: {
  status() {
    const assigneeId = this.chat.meta?.assignee?.id;

    if (this.chat.status === "resolved") {
      return 'resolved';
    } else if (this.chat.status === "open" && assigneeId == null) {
      return 'open';
    } else if (this.chat.status === "open" && assigneeId != null) {
      return 'assigned';
    } else {
      return 'pending';
    }
  },
    statusClass() {
      const statusMap = {
        open: 'bg-blue-500 text-white',
        assigned: 'bg-red-500 text-white',
        resolved: 'bg-green-500 text-white',
        pending: 'bg-yellow-500 text-black',
      };
      return statusMap[this.status] || statusMap.pending;
    },
    displayStatus() {
      return this.status.charAt(0).toUpperCase() + this.status.slice(1);
    }
  }
};
</script>


<template>
  <div class="flex mb-1">
    <span 
      :class="['text-xs font-medium px-2 py-0.5 rounded-full', statusClass]"
    >
      {{ displayStatus }}
    </span>
  </div>
</template>
