<script setup>
// One row of the Calls page: what the settings are for on the start side, the settings on the end side
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <section
    class="grid grid-cols-1 gap-3 px-5 py-5 md:grid-cols-[14rem_1fr] md:gap-6"
  >
    <div class="flex flex-col gap-1">
      <h3 class="text-heading-3 text-n-slate-12">{{ title }}</h3>
      <p v-if="description" class="text-body-main text-n-slate-11">
        {{ description }}
      </p>
    </div>
    <div class="flex flex-col min-w-0 gap-4">
      <slot />
    </div>
  </section>
</template>
