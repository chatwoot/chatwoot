<script setup>
import LocaleCard from './LocaleCard.vue';

defineProps({
  locales: {
    type: Array,
    required: true,
  },
});
</script>

<template>
  <ul role="list" class="w-full h-full min-h-screen pt-6 space-y-4">
    <LocaleCard
      v-for="(locale, index) in locales"
      :key="index"
      :locale="locale.name"
      :is-default="locale.isDefault"
    />
  </ul>
</template>
