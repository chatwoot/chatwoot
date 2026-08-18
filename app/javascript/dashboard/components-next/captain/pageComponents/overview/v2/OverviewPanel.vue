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
      shadow ? 'shadow-[0_1px_2px_0_rgba(27,28,29,0.04)]' : '',
    ]"
  >
    <header
      v-if="title || $slots.actions"
      class="flex h-[52px] shrink-0 items-center justify-between gap-3 px-5 pt-5"
    >
      <h2
        v-if="title"
        class="font-interDisplay text-sm font-medium leading-[21px] tracking-[0.14px] text-n-slate-12"
      >
        {{ title }}
      </h2>
      <slot name="actions" />
    </header>
    <slot />
  </section>
</template>
