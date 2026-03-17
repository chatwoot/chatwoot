<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <section class="rounded-xl border border-n-weak bg-n-solid-2 p-3">
    <header
      v-if="title"
      class="mb-2 text-xs font-semibold uppercase tracking-wide text-n-slate-10"
    >
      {{ title }}
    </header>
    <slot />
  </section>
</template>
