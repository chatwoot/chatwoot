<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    required: true,
  },
  deltaText: {
    type: String,
    default: '',
  },
  isPositiveDelta: {
    type: Boolean,
    default: true,
  },
  comparisonLabel: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <article class="rounded-xl border border-n-weak bg-n-solid-1 p-3">
    <p class="m-0 text-xs font-medium text-n-slate-11">
      {{ label }}
    </p>
    <p class="m-0 mt-1 text-xl font-semibold text-n-slate-12">
      {{ value }}
    </p>
    <p
      class="m-0 mt-1 text-xs"
      :class="isPositiveDelta ? 'text-n-teal-10' : 'text-n-ruby-9'"
    >
      {{ deltaText }} {{ comparisonLabel }}
    </p>
  </article>
</template>
