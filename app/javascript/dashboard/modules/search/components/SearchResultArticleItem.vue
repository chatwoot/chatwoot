<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import MessageFormatter from 'shared/helpers/MessageFormatter';

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
  category: {
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
});

const navigateTo = computed(() => {
  return frontendURL(
    `accounts/${props.accountId}/portals/${props.portalId}/articles/${props.id}`
  );
});

const truncatedContent = computed(() => {
  if (!props.content) return props.description || '';

  // Use MessageFormatter to properly convert markdown to plain text
  const formatter = new MessageFormatter(props.content);
  const plainText = formatter.plainText.trim();

  return plainText.length > 150
    ? `${plainText.substring(0, 150)}...`
    : plainText;
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
      <Icon icon="i-lucide-library-big" class="text-n-slate-10" />
    </div>
    <div class="ml-2 rtl:mr-2 min-w-0 rtl:ml-0 flex-1">
      <div class="flex items-center gap-2">
        <h5 class="text-sm font-medium truncate min-w-0 text-n-slate-12">
          {{ title }}
        </h5>
        <span
          v-if="category"
          class="text-xs font-medium capitalize bg-n-slate-3 px-1 py-0.5 rounded text-n-slate-10"
        >
          {{ category }}
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
