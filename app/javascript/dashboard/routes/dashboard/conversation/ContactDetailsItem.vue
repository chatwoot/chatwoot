<script>
export default {
  props: {
    title: { type: String, required: true },
    value: { type: [String, Number], default: '' },
    compact: { type: Boolean, default: false },
  },
};
</script>

<template>
  <div class="overflow-auto" :class="compact ? 'py-0 px-0' : 'py-3 px-4'">
    <div class="items-center flex justify-between mb-1.5">
      <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
        {{ title }}
      </span>
      <slot name="button" />
    </div>
    <div v-if="value" class="break-words">
      <slot>
        {{ value }}
      </slot>
    </div>
  </div>
</template>
