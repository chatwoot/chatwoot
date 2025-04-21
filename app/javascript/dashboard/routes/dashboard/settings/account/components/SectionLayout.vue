<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  withBorder: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <section
    class="grid grid-cols-[1fr_3fr] py-8 gap-10"
    :class="{ 'border-t border-n-weak': withBorder }"
  >
    <div>
      <h4 class="text-lg font-medium text-n-slate-12">
        <slot name="title">{{ title }}</slot>
      </h4>
      <p class="text-n-slate-11">
        <slot name="description">{{ description }}</slot>
      </p>
    </div>
    <div class="text-n-slate-12">
      <slot />
    </div>
  </section>
</template>
