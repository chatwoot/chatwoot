<script setup>
defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  padding: { type: String, default: 'default' }, // default|tight|loose|none
  interactive: { type: Boolean, default: false },
});

const paddingClass = {
  default: 'p-6',
  tight: 'p-4',
  loose: 'p-8',
  none: '',
};
</script>

<template>
  <div
    :class="[
      'bg-s-surface border border-s-border rounded-2xl shadow-s-sm transition-shadow duration-150 ease-out',
      interactive ? 'hover:shadow-s-md cursor-pointer' : '',
    ]"
  >
    <header
      v-if="title || $slots.header"
      class="flex items-start justify-between gap-3 px-6 pt-5 pb-4 border-b border-s-border-subtle"
    >
      <div class="flex flex-col gap-1 min-w-0">
        <h3 v-if="title" class="text-base font-semibold text-s-primary truncate">
          {{ title }}
        </h3>
        <p v-if="subtitle" class="text-sm text-s-muted truncate">{{ subtitle }}</p>
        <slot name="header" />
      </div>
      <slot name="actions" />
    </header>
    <div :class="paddingClass[padding]">
      <slot />
    </div>
    <footer v-if="$slots.footer" class="px-6 py-4 border-t border-s-border-subtle">
      <slot name="footer" />
    </footer>
  </div>
</template>
