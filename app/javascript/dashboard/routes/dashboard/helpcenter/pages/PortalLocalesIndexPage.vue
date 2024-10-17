<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store.js';
import allLocales from 'shared/constants/locales.js';

import LocalesPage from 'dashboard/components-next/HelpCenter/Pages/LocalePage/LocalesPage.vue';

const route = useRoute();

const getPortalBySlug = useMapGetter('portals/portalBySlug');

const portal = computed(() => getPortalBySlug.value(route.params.portalSlug));

const allowedLocales = computed(() => {
  if (!portal.value) {
    return [];
  }
  const { allowed_locales: allAllowedLocales } = portal.value.config;
  return allAllowedLocales.map(locale => {
    return {
      id: locale?.code,
      name: allLocales[locale?.code],
      code: locale?.code,
      articlesCount: locale?.articles_count || 0,
      categoriesCount: locale?.categories_count || 0,
    };
  });
});
</script>

<template>
  <LocalesPage :locales="allowedLocales" :portal="portal" />
</template>
