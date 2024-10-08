<script setup>
import LocaleCard from './LocaleCard.vue';

const locales = [
  { variant: 'Default', name: 'English', isDefault: true },
  { variant: 'Not Default', name: 'Spanish', isDefault: false },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="HelpCenter/LocaleCard"
    :layout="{ type: 'grid', width: '500px' }"
  >
    <Variant
      v-for="(locale, index) in locales"
      :key="index"
      :title="locale.variant"
    >
      <LocaleCard :locale="locale.name" :is-default="locale.isDefault" />
    </Variant>
  </Story>
</template>
