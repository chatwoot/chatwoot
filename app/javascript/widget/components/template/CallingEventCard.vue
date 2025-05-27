<script>
export default {
  props: {
    callStatus: {
      type: String,
      required: true,
      default: 'missed',
    },
    callStartTime: {
      type: String,
      required: true,
    },
    messageId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {};
  },
  computed: {
    formattedTime() {
      const date = new Date(this.callStartTime);
      const now = new Date();

      const isToday = date.toDateString() === now.toDateString();

      const yesterday = new Date();
      yesterday.setDate(now.getDate() - 1);
      const isYesterday = date.toDateString() === yesterday.toDateString();

      const timePart = date.toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      });

      if (isToday) {
        return `Today ${timePart}`;
      } else if (isYesterday) {
        return `Yesterday ${timePart}`;
      } else if (date.getFullYear() === now.getFullYear()) {
        return `${date.getDate()} ${date.toLocaleString('default', {
          month: 'short',
        })} ${timePart}`;
      } else {
        return `${date.getDate()} ${date.toLocaleString('default', {
          month: 'short',
        })} ${String(date.getFullYear()).slice(-2)} ${timePart}`;
      }
    },
    // formattedTime() {
    //   const date = new Date(this.callStartTime);
    //   return date.toLocaleTimeString([], {
    //     day: true,
    //     hour: '2-digit',
    //     minute: '2-digit',
    //   });
    // },
    backgroundClass() {
      switch (this.callStatus) {
        case 'accepted':
          return 'bg-green-50';
        case 'rejected':
          return 'bg-red-50';
        case 'missed':
          return 'bg-red-50';
        default:
          return 'bg-white';
      }
    },
  },
};
</script>

<template>
  <div class="space-x-2">
    <div
      :class="[
        'inline-flex items-center space-x-2 rounded-full px-4 py-1 text-sm shadow-sm',
        backgroundClass,
      ]"
    >
      <span class="font-semibold text-gray-800">
        {{ callStatus[0].toUpperCase() + callStatus.slice(1) }}
      </span>
    </div>
    <span class="text-gray-500 text-xs">
      {{ formattedTime }}
    </span>
  </div>
</template>
