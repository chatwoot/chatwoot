<script setup>
import LocaleCard from './LocaleCard.vue';

const locales = [
  { variant: 'Default', name: 'English', isDefault: true },
  { variant: 'Not Default', name: 'Spanish', isDefault: false },
];
</script>

<template>
  <Story title="LocaleCard" :layout="{ type: 'grid', width: '400px' }">
    <Variant
      v-for="(locale, index) in locales"
      :key="index"
      :title="locale.variant"
    >
      <LocaleCard :locale="locale.name" :isDefault="locale.isDefault" />
    </Variant>
  </Story>
</template>
