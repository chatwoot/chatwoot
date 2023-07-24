<template>
  <div class="overflow-auto" :class="compact ? 'py-0 px-0' : 'py-3 px-4'">
    <div class="items-center flex justify-between mb-1.5">
      <span class="text-slate-800 font-medium dark:text-slate-100 text-sm">
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

<script>
export default {
  props: {
    title: { type: String, required: true },
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
    compact: { type: Boolean, default: false },
  },
};
</script>
