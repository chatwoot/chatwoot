<script setup>
import Icon from 'next/icon/Icon.vue';
import { computed } from 'vue';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
  count: {
    type: Number,
    default: 0,
  },
});

const countLabel = computed(() => (props.count > 99 ? '99+' : props.count));
</script>

<template>
  <div
    class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-8 text-n-slate-10 select-none pointer-events-none"
  >
    <Icon v-if="icon" :icon="icon" class="size-4" />
    <span class="text-sm font-medium leading-5 flex-grow min-w-0 truncate">
      {{ label }}
    </span>
    <span
      v-if="count"
      dir="ltr"
      class="inline-flex h-5 min-w-5 flex-shrink-0 items-center justify-center rounded-md bg-n-ruby-9/20 px-1.5 text-[11px] font-semibold leading-none text-n-ruby-11 ring-1 ring-n-ruby-8/50 tabular-nums"
    >
      {{ countLabel }}
    </span>
  </div>
</template>
