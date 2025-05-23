<script setup>
import { computed } from 'vue';
import { frontendURL } from 'dashboard/helper/URLHelper';

const props = defineProps({
  id: {
    type: [String, Number],
    default: 0,
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  content: {
    type: String,
    default: '',
  },
  portalId: {
    type: [String, Number],
    default: 0,
  },
  accountId: {
    type: [String, Number],
    default: 0,
  },
  status: {
    type: String,
    default: '',
  },
});

const navigateTo = computed(() => {
  return frontendURL(
    `accounts/${props.accountId}/portals/${props.portalId}/articles/${props.id}`
  );
});

const truncatedContent = computed(() => {
  if (!props.content) return props.description || '';
  const plainText = props.content.replace(/<[^>]*>/g, '');
  return plainText.length > 150
    ? `${plainText.substring(0, 150)}...`
    : plainText;
});

const statusColor = computed(() => {
  switch (props.status) {
    case 'published':
      return 'text-n-green-10';
    case 'draft':
      return 'text-n-yellow-10';
    case 'archived':
      return 'text-n-slate-10';
    default:
      return 'text-n-slate-10';
  }
});
</script>

<template>
  <router-link
    :to="navigateTo"
    class="flex items-start p-2 rounded-xl cursor-pointer hover:bg-n-slate-2"
  >
    <div
      class="flex items-center justify-center w-6 h-6 mt-0.5 rounded bg-n-slate-3"
    >
      <fluent-icon icon="document" size="12px" class="text-n-slate-10" />
    </div>
    <div class="ml-2 rtl:mr-2 min-w-0 rtl:ml-0 flex-1">
      <div class="flex items-center gap-2">
        <h5 class="text-sm font-medium truncate min-w-0 text-n-slate-12">
          {{ title }}
        </h5>
        <span
          v-if="status"
          :class="statusColor"
          class="text-xs font-medium capitalize"
        >
          {{ status }}
        </span>
      </div>
      <p
        v-if="truncatedContent"
        class="mt-1 text-sm text-n-slate-11 line-clamp-2"
      >
        {{ truncatedContent }}
      </p>
    </div>
  </router-link>
</template>
