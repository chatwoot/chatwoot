<script setup>
import LocaleCard from './LocaleCard.vue';
const locales = [
  {
    name: 'English',
    code: 'en',
    isDefault: true,
    isDraft: false,
    articleCount: 29,
    categoryCount: 5,
  },
  {
    name: 'Spanish',
    code: 'es',
    isDefault: false,
    isDraft: true,
    articleCount: 29,
    categoryCount: 5,
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/HelpCenter/LocaleCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Locale Card">
      <div class="px-10 py-4 bg-n-background">
        <div v-for="(locale, index) in locales" :key="index" class="px-20 py-2">
          <LocaleCard
            :locale="locale.name"
            :is-default="locale.isDefault"
            :is-draft="locale.isDraft"
            :locale-code="locale.code"
            :article-count="locale.articleCount"
            :category-count="locale.categoryCount"
          />
        </div>
      </div>
    </Variant>
  </Story>
</template>
