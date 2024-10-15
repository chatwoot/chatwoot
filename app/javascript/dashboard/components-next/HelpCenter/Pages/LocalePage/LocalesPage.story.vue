<script setup>
import LocalesPage from './LocalesPage.vue';

const locales = [
  {
    name: 'English (en-US)',
    isDefault: true,
    articleCount: 5,
    categoryCount: 5,
  },
  {
    name: 'Spanish (es-ES)',
    isDefault: false,
    articleCount: 20,
    categoryCount: 10,
  },
  {
    name: 'English (en-UK)',
    isDefault: false,
    articleCount: 15,
    categoryCount: 7,
  },
  {
    name: 'Malay (ms-MY)',
    isDefault: false,
    articleCount: 15,
    categoryCount: 7,
  },
  {
    name: 'Malayalam (ml-IN)',
    isDefault: false,
    articleCount: 10,
    categoryCount: 5,
  },
  {
    name: 'Hindi (hi-IN)',
    isDefault: false,
    articleCount: 15,
    categoryCount: 7,
  },
];
</script>

<template>
  <Story title="Pages/HelpCenter/LocalePage" :layout="{ type: 'single' }">
    <Variant title="All Locales">
      <div class="w-full min-h-screen bg-white dark:bg-slate-900">
        <LocalesPage :locales="locales" />
      </div>
    </Variant>
  </Story>
</template>
