<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { buildPortalURL } from 'dashboard/helper/portalHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

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

const portalLink = computed(() => {
  return buildPortalURL(currentPortalSlug.value);
});

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

const onClickPreviewPortal = () => {
  window.open(portalLink.value, '_blank');
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
        <div class="flex items-center gap-2">
          <h2
            class="text-base font-medium cursor-pointer text-slate-900 dark:text-slate-50 w-fit hover:underline"
            @click="redirectToPortalHomePage"
          >
            {{ t('HELP_CENTER.PORTAL_SWITCHER.PORTALS') }}
          </h2>
          <Button
            icon="i-lucide-arrow-up-right"
            variant="ghost"
            icon-lib="lucide"
            size="sm"
            class="!w-6 !h-6 hover:bg-n-slate-2 text-n-slate-11 !p-0.5 rounded-md"
            @click="onClickPreviewPortal"
          />
        </div>
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('HELP_CENTER.PORTAL_SWITCHER.CREATE_PORTAL') }}
        </p>
      </div>
      <Button
        :label="t('HELP_CENTER.PORTAL_SWITCHER.NEW_PORTAL')"
        color="slate"
        icon="i-lucide-plus"
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
        trailing-icon
        :icon="isPortalActive(portal) ? 'i-lucide-check' : ''"
        class="!justify-end !px-2 !py-2 hover:!bg-n-alpha-2 [&>.i-lucide-check]:text-n-teal-10 h-9"
        size="sm"
        @click="handlePortalChange(portal)"
      >
        <div v-if="portal.custom_domain" class="flex items-center gap-1">
          <span class="i-lucide-link size-3" />
          <span class="text-sm truncate text-n-slate-11">
            {{ portal.custom_domain || '' }}
          </span>
        </div>
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ portal.name || '' }}
        </span>
        <Avatar
          v-if="portal"
          :name="portal.name"
          :src="getPortalThumbnailSrc(portal)"
          :size="20"
          icon-name="i-lucide-building-2"
          rounded-full
        />
      </Button>
    </div>
  </div>
</template>
