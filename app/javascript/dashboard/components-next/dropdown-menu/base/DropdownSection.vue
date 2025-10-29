<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="-mx-2 n-dropdown-section">
    <div
      v-if="title"
      class="px-4 mb-3 mt-1 leading-4 font-medium tracking-[0.2px] text-n-slate-10 text-xs"
    >
      {{ title }}
    </div>
    <ul class="gap-2 grid reset-base list-none px-2">
      <slot />
    </ul>
  </div>
</template>
