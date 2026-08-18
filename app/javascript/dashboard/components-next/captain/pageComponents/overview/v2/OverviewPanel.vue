<script setup>
defineProps({
  title: { type: String, default: '' },
});
</script>

<template>
  <section
    class="flex flex-col min-w-0 overflow-hidden border rounded-xl bg-n-solid-1 border-n-weak"
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
