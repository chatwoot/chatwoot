<script setup>
// Browse content — articles, posts, contact details — sits flat on the
// background so the composer and any open conversation stay the only raised
// surfaces on Home. Rows get their rounding on hover instead of a card.
defineProps({
  label: { type: String, required: true },
});
</script>

<template>
  <section>
    <h2 class="px-2 pb-1 type-overline text-cw-text-faint">{{ label }}</h2>
    <div class="flex flex-col">
      <slot />
    </div>
  </section>
</template>
