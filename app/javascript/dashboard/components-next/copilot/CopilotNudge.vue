<script setup>
// Wraps a Copilot button. Until the person first opens Copilot, the button carries the dashboard's brand dot, the same
// one the sidebar and the contacts filter use. Its halo keeps pulsing until the person opens Copilot.
defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div class="relative">
    <slot />
    <span
      v-if="show"
      data-test-id="copilot-dot"
      class="absolute top-0 end-0 size-2.5 pointer-events-none"
    >
      <span
        class="absolute inset-0 rounded-full bg-n-brand opacity-75 motion-safe:animate-ping"
      />
      <span
        class="absolute inset-0 rounded-full bg-n-brand border border-n-solid-2"
      />
    </span>
  </div>
</template>
