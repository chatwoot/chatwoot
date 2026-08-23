<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  meta: {
    type: Array,
    default: () => [],
  },
});
</script>

<template>
  <div class="flex items-center justify-between gap-4 py-4 min-w-0">
    <div class="flex items-center min-w-0 gap-3">
      <span
        class="grid border rounded-xl shadow-sm size-10 shrink-0 place-items-center bg-n-alpha-3 border-n-strong ring ring-n-solid-1"
      >
        <slot name="icon" />
      </span>
      <div class="flex flex-col min-w-0 gap-1">
        <div class="flex items-center min-w-0 gap-2">
          <span class="truncate text-heading-3 text-n-slate-12">
            <slot name="title">
              {{ title }}
            </slot>
          </span>
          <slot name="badges" />
        </div>
        <div
          v-if="meta.length || $slots.meta"
          class="flex flex-wrap items-center gap-2 text-body-main text-n-slate-11 min-w-0"
        >
          <slot name="meta">
            <template v-for="(item, index) in meta" :key="`${index}-${item}`">
              <div
                v-if="index > 0"
                class="w-px h-3 rounded-lg bg-n-strong shrink-0"
              />
              <span class="truncate">{{ item }}</span>
            </template>
          </slot>
        </div>
      </div>
    </div>
    <div v-if="$slots.actions" class="flex gap-2 justify-end shrink-0">
      <slot name="actions" />
    </div>
  </div>
</template>
