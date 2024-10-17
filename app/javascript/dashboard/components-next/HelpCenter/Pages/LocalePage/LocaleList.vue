<script setup>
import LocaleCard from 'dashboard/components-next/HelpCenter/LocaleCard/LocaleCard.vue';

defineProps({
  locales: {
    type: Array,
    required: true,
  },
});
</script>

<template>
  <ul role="list" class="w-full h-full space-y-4">
    <LocaleCard
      v-for="(locale, index) in locales"
      :key="index"
      :locale="locale.name"
      :is-default="locale.isDefault"
      :article-count="locale.articleCount"
      :category-count="locale.categoryCount"
    />
  </ul>
</template>
