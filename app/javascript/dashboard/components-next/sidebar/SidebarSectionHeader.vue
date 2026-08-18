<script setup>
defineProps({
  label: { type: String, required: true },
  // At 56px the sidebar has no room for a text label, so the section degrades
  // to a plain rule — the grouping stays legible, the wording drops out.
  collapsed: { type: Boolean, default: false },
});
</script>

<template>
  <li
    v-if="collapsed"
    class="mx-auto my-1.5 w-6 h-px list-none bg-n-weak"
    role="separator"
  />
  <li v-else class="flex gap-2 items-center px-2 pt-3 pb-1 list-none">
    <span
      class="text-xs font-medium tracking-wider uppercase text-n-slate-10 truncate"
    >
      {{ label }}
    </span>
    <span class="h-px flex-1 bg-n-weak" />
  </li>
</template>
