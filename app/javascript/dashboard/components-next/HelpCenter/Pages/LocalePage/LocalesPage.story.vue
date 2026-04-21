<script setup>
import LocalesPage from './LocalesPage.vue';

const locales = [
  {
    name: 'English (en-US)',
    code: 'en',
    isDefault: true,
    isDraft: false,
    articleCount: 5,
    categoryCount: 5,
  },
  {
    name: 'Spanish (es-ES)',
    code: 'es',
    isDefault: false,
    isDraft: true,
    articleCount: 20,
    categoryCount: 10,
  },
  {
    name: 'English (en-UK)',
    code: 'en_GB',
    isDefault: false,
    isDraft: false,
    articleCount: 15,
    categoryCount: 7,
  },
  {
    name: 'Malay (ms-MY)',
    code: 'ms',
    isDefault: false,
    isDraft: false,
    articleCount: 15,
    categoryCount: 7,
  },
  {
    name: 'Malayalam (ml-IN)',
    code: 'ml',
    isDefault: false,
    isDraft: false,
    articleCount: 10,
    categoryCount: 5,
  },
  {
    name: 'Hindi (hi-IN)',
    code: 'hi',
    isDefault: false,
    isDraft: false,
    articleCount: 15,
    categoryCount: 7,
  },
];
</script>

<template>
  <Story title="Pages/HelpCenter/LocalePage" :layout="{ type: 'single' }">
    <Variant title="All Locales">
      <div class="w-full min-h-screen bg-n-background">
        <LocalesPage :locales="locales" />
      </div>
    </Variant>
  </Story>
</template>
