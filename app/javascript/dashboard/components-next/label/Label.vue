<script setup>
defineProps({
  label: {
    type: Object,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    :title="label.description"
    class="bg-n-button-color gap-1.5 rounded-lg -outline-offset-1 outline outline-1 outline-n-container inline-flex items-center flex-shrink-0"
    :class="compact ? 'px-1.5 h-6 gap-1 rounded-md' : 'px-2.5 h-8 rounded-lg'"
  >
    <span
      class="rounded-sm flex-shrink-0"
      :class="compact ? 'size-1.5' : 'size-2'"
      :style="{ background: label.color }"
    />
    <span
      class="text-n-slate-12 whitespace-nowrap"
      :class="compact ? 'text-label-small' : 'text-label !font-440'"
    >
      {{ label.title }}
    </span>
    <slot name="action" />
  </div>
</template>
