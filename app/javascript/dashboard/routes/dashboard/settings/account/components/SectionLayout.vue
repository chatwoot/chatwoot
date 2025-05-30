<script setup>
defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  withBorder: { type: Boolean, default: false },
  hideContent: { type: Boolean, default: false },
});
</script>

<template>
  <section
    class="grid grid-cols-1 settings-section py-8"
    :class="{
      'border-t border-n-weak': withBorder,
      'gap-8': !hideContent && description,
      'gap-4': !hideContent && !description,
    }"
  >
    <header class="grid grid-cols-4">
      <div class="col-span-3">
        <h4 class="text-lg font-medium text-n-slate-12">
          <slot name="title">{{ title }}</slot>
        </h4>
        <p class="text-n-slate-11 text-sm mt-2">
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div class="col-span-1">
        <slot name="headerActions" />
      </div>
    </header>
    <div
      class="content-transition text-n-slate-12"
      :class="{ 'content-hidden': hideContent }"
    >
      <slot />
    </div>
  </section>
</template>

<style scoped>
.settings-section {
  interpolate-size: allow-keywords;
}

.content-transition {
  height: auto;
  overflow: hidden;
  transition: height 0.3s ease;
}

.content-transition.content-hidden {
  height: 0;
}
</style>
