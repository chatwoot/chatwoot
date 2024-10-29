<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';

import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';

const emit = defineEmits(['close', 'createPortal']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const DEFAULT_ROUTE = 'portals_articles_index';
const CATEGORY_ROUTE = 'portals_categories_index';
const CATEGORY_SUB_ROUTES = [
  'portals_categories_articles_index',
  'portals_categories_articles_edit',
];

const portals = useMapGetter('portals/allPortals');

const currentPortalSlug = computed(() => route.params.portalSlug);

const isPortalActive = portal => {
  return portal.slug === currentPortalSlug.value;
};

const getPortalThumbnailSrc = portal => {
  return portal?.logo?.file_url || '';
};

const fetchPortalAndItsCategories = async (slug, locale) => {
  await store.dispatch('portals/switchPortal', true);
  await store.dispatch('portals/index');
  const selectedPortalParam = {
    portalSlug: slug,
    locale,
  };
  await store.dispatch('portals/show', selectedPortalParam);
  await store.dispatch('categories/index', selectedPortalParam);
  await store.dispatch('agents/get');
  await store.dispatch('portals/switchPortal', false);
};

const handlePortalChange = async portal => {
  if (isPortalActive(portal)) return;
  const {
    slug,
    meta: { default_locale: defaultLocale },
  } = portal;
  emit('close');
  await fetchPortalAndItsCategories(slug, defaultLocale);
  const targetRouteName = CATEGORY_SUB_ROUTES.includes(route.name)
    ? CATEGORY_ROUTE
    : route.name || DEFAULT_ROUTE;
  router.push({
    name: targetRouteName,
    params: {
      portalSlug: slug,
      locale: defaultLocale,
    },
  });
};

const openCreatePortalDialog = () => {
  emit('createPortal');
  emit('close');
};

const redirectToPortalHomePage = () => {
  router.push({
    name: 'portals_index',
    params: {
      navigationPath: DEFAULT_ROUTE,
    },
  });
};
</script>

<template>
  <div
    class="pt-5 pb-3 bg-n-alpha-3 backdrop-blur-[100px] outline outline-n-container outline-1 z-50 absolute w-[440px] rounded-xl shadow-md flex flex-col gap-4"
  >
    <div
      class="flex items-center justify-between gap-4 px-6 pb-3 border-b border-n-alpha-2"
    >
      <div class="flex flex-col gap-1">
        <h2
          class="text-base font-medium cursor-pointer text-slate-900 dark:text-slate-50 w-fit hover:underline"
          @click="redirectToPortalHomePage"
        >
          {{ t('HELP_CENTER.PORTAL_SWITCHER.PORTALS') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('HELP_CENTER.PORTAL_SWITCHER.CREATE_PORTAL') }}
        </p>
      </div>
      <Button
        :label="t('HELP_CENTER.PORTAL_SWITCHER.NEW_PORTAL')"
        variant="secondary"
        icon="add"
        size="sm"
        class="!bg-n-alpha-2 hover:!bg-n-alpha-3"
        @click="openCreatePortalDialog"
      />
    </div>
    <div v-if="portals.length > 0" class="flex flex-col gap-2 px-4">
      <Button
        v-for="(portal, index) in portals"
        :key="index"
        :label="portal.name"
        variant="ghost"
        :icon="isPortalActive(portal) ? 'checkmark-lucide' : ''"
        icon-lib="lucide"
        icon-position="right"
        class="!justify-start !px-2 !py-2 hover:!bg-n-alpha-2 [&>svg]:text-n-teal-10 [&>svg]:w-5 [&>svg]:h-5 h-9"
        size="sm"
        @click="handlePortalChange(portal)"
      >
        <template #leftPrefix>
          <Thumbnail
            v-if="portal"
            :author="portal"
            :name="portal.name"
            :size="20"
            :src="getPortalThumbnailSrc(portal)"
            :show-author-name="false"
            icon-name="building-lucide"
          />
        </template>
        <template #rightPrefix>
          <span class="text-sm truncate text-n-slate-11">
            {{ portal.custom_domain || '' }}
          </span>
        </template>
      </Button>
    </div>
  </div>
</template>
