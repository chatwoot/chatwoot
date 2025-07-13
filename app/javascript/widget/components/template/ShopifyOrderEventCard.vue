<script setup>
import { computed, onMounted } from 'vue';

const props = defineProps({
  messageId: {
    type: Number,
    required: true,
  },
  messageContentAttributes: {
    type: Object,
    default: () => {},
  },
});

const orderId = computed(() => {
  return props.messageContentAttributes.shopify_order_id;
});

const formattedTime = computed(() => {
  const date = new Date(
    props.messageContentAttributes.shopify_order_event_time
  );

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
  }
  if (isYesterday) {
    return `Yesterday ${timePart}`;
  }
  if (date.getFullYear() === now.getFullYear()) {
    return `${date.getDate()} ${date.toLocaleString('default', {
      month: 'short',
    })} ${timePart}`;
  }
  return `${date.getDate()} ${date.toLocaleString('default', {
    month: 'short',
  })} ${String(date.getFullYear()).slice(-2)} ${timePart}`;
});

const getDetails = attrs => {
  switch (attrs.shopify_order_event_name) {
    case 'cancel_order':
      return `Cancelled order ${attrs.shopify_order_id} at ${formattedTime.value}`;
  }
};

onMounted(() => {
  console.log('PROPS: ', props);
});
</script>

<template>
  <div>
    <div
      class="inline-flex items-center space-x-2 px-2 py-1 text-xs shadow-sm bg-green-50 rounded-md"
    >
      <span
        v-if="messageContentAttributes.shopify_event.status_url"
        class="text-gray-800"
      >
        <a
          :href="messageContentAttributes.shopify_event.status_url"
          target="_blank"
          rel="noopener noreferrer"
        >
          View Status
        </a>
      </span>
    </div>

    <div v-if="messageContentAttributes.shopify_event.total_refund">
      Total Refund: {{ messageContentAttributes.shopify_event.total_refund }}
    </div>

    <div
      v-if="messageContentAttributes.shopify_event.items?.length > 0 ?? false"
    >
      <label> Items </label>
      <div
        v-for="(item, index) in messageContentAttributes.shopify_event.items"
      >
        <div class="flex flex-col">
          <div class="flex flex-row text-xs">
            <span> {{ item.name }} x {{ item.qty }} </span>
          </div>
          <span v-if="item.restock" class="text-xs">
            Restock: {{ item.restock }}
          </span>
        </div>
      </div>
    </div>
    <!-- <span class="text-gray-500 text-xs">
      {{ formattedTime }}
    </span>-->
  </div>
</template>
