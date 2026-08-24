<script setup>
defineProps({
  title: { type: String, default: '' },
  borderClass: { type: String, default: 'border-n-container' },
  shadow: { type: Boolean, default: true },
});
</script>

<template>
  <section
    class="flex flex-col min-w-0 overflow-hidden border rounded-2xl bg-n-card"
    :class="[
      borderClass,
      shadow ? 'shadow-[0_0.0625rem_0.125rem_0_rgba(27,28,29,0.04)]' : '',
    ]"
  >
    <header
      v-if="title || $slots.actions"
      class="flex h-[3.25rem] shrink-0 items-center justify-between gap-3 px-5 pt-5"
    >
      <h2 v-if="title" class="text-heading-3 text-n-slate-12">
        {{ title }}
      </h2>
      <slot name="actions" />
    </header>
    <slot />
  </section>
</template>
