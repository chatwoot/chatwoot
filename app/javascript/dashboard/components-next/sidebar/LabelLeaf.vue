<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';

const props = defineProps({
  label: {
    type: Object,
    required: true,
  },
  active: {
    type: Boolean,
    default: false,
  },
});

const store = useStore();

const unreadCount = computed(() =>
  store.getters['conversationStats/getUnreadCountForLabel'](props.label.title)
);

const displayCount = computed(() =>
  unreadCount.value > 99 ? '99+' : unreadCount.value
);
</script>

<template>
  <span
    class="size-3 rounded-sm flex-shrink-0 ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset"
    :style="{ backgroundColor: label.color }"
  />
  <div class="flex-1 truncate min-w-0">{{ label.title }}</div>
  <span
    v-if="unreadCount > 0"
    class="rounded-md text-xs leading-5 font-medium text-center outline outline-1 px-1 flex-shrink-0"
    :class="{
      'text-n-blue-text outline-n-slate-6': active,
      'text-n-slate-11 outline-n-strong': !active,
    }"
  >
    {{ displayCount }}
  </span>
</template>
