<script setup>
defineProps({
  title: { type: String, default: '' },
});
</script>

<template>
  <section
    class="flex flex-col min-w-0 overflow-hidden border rounded-2xl bg-n-card border-n-container shadow-[0_1px_2px_0_rgba(27,28,29,0.04)]"
  >
    <header
      v-if="title || $slots.actions"
      class="flex items-center justify-between gap-3 px-5 pt-5"
    >
      <h2 v-if="title" class="text-sm font-medium text-n-slate-12">
        {{ title }}
      </h2>
      <slot name="actions" />
    </header>
    <slot />
  </section>
</template>
