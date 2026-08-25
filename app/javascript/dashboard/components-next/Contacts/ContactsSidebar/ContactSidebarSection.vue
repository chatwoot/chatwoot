<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  count: {
    type: [Number, String],
    default: null,
  },
  bodyClass: {
    type: String,
    default: 'px-4 py-4',
  },
});
</script>

<template>
  <section
    class="flex flex-col overflow-hidden border rounded-2xl border-n-weak bg-n-solid-1"
  >
    <header
      v-if="title || $slots.action"
      class="flex items-center justify-between gap-2 px-5 py-4 border-b border-n-weak"
    >
      <h4
        class="text-xs font-semibold tracking-wider uppercase text-n-slate-10"
      >
        {{ title }}
        <span
          v-if="count !== null && count !== ''"
          class="font-medium tracking-normal normal-case ms-1 text-n-slate-10"
        >
          {{ count }}
        </span>
      </h4>
      <slot name="action" />
    </header>
    <div :class="bodyClass">
      <slot />
    </div>
  </section>
</template>
