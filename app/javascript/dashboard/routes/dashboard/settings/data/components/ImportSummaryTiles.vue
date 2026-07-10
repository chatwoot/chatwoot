<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});
</script>

<template>
  <dl
    class="grid grid-cols-2 gap-px overflow-hidden rounded-xl border border-n-weak bg-n-weak sm:grid-cols-3 lg:grid-cols-5"
  >
    <div
      v-for="item in items"
      :key="item.key"
      class="flex min-w-0 flex-col gap-1 bg-n-solid-1 px-4 py-3"
    >
      <dt class="flex items-center gap-1.5 text-label-small text-n-slate-10">
        <Icon :icon="item.icon" class="size-3.5 shrink-0" />
        {{ item.label }}
      </dt>
      <dd
        v-tooltip.top="item.tooltip"
        class="truncate text-heading-3 text-n-slate-12"
      >
        {{ item.value }}
      </dd>
    </div>
  </dl>
</template>
