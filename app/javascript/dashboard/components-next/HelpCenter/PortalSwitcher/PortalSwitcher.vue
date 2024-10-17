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

const portals = useMapGetter('portals/allPortals');

const currentPortalSlug = computed(() => route.params.portalSlug);

const isPortalActive = portal => {
  return portal.slug === currentPortalSlug.value;
};

const getArticlesCount = portal => {
  return portal.config.allowed_locales.reduce((acc, locale) => {
    return acc + locale.articles_count;
  }, 0);
};

const getPortalThumbnailSrc = portal => {
  return portal?.logo?.file_url || '';
};

const fetchPortalAndItsCategories = async (slug, locale) => {
  await store.dispatch('portals/index');
  const selectedPortalParam = {
    portalSlug: slug,
    locale,
  };
  await store.dispatch('portals/show', selectedPortalParam);
  await store.dispatch('categories/index', selectedPortalParam);
  await store.dispatch('agents/get');
};

const handlePortalChange = portal => {
  const {
    slug,
    meta: { default_locale: defaultLocale },
  } = portal;
  router.push({
    name: 'list_articles',
    params: {
      portalSlug: slug,
      locale: defaultLocale,
    },
  });
  fetchPortalAndItsCategories(slug, defaultLocale);
  emit('close');
};

const openCreatePortalDialog = () => {
  emit('createPortal');
  emit('close');
};
</script>

<template>
  <div
    class="pt-5 pb-3 bg-white z-50 dark:bg-slate-800 absolute w-[450px] rounded-xl shadow-md flex flex-col gap-4"
  >
    <div class="flex items-center justify-between gap-4 px-6 pb-2">
      <div class="flex flex-col gap-1">
        <h2 class="text-base font-medium text-slate-900 dark:text-slate-50">
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
        @click="openCreatePortalDialog"
      />
    </div>
    <div v-if="portals.length > 0" class="flex flex-col gap-3">
      <template v-for="(portal, index) in portals" :key="portal.id">
        <div class="flex flex-col gap-2 px-6 py-2">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <input
                :id="portal.id"
                :checked="isPortalActive(portal)"
                type="radio"
                :value="portal.slug"
                class="mr-3"
                @change="handlePortalChange(portal)"
              />
              <label
                :for="portal.id"
                class="text-sm font-medium text-slate-900 dark:text-slate-100"
              >
                {{ portal.name }}
              </label>
            </div>
            <Thumbnail
              v-if="portal"
              :author="portal"
              :name="portal.name"
              :src="getPortalThumbnailSrc(portal)"
            />
          </div>
          <div
            class="inline-flex items-center gap-2 py-1 overflow-hidden text-sm whitespace-nowrap"
          >
            <span class="flex-shrink-0 text-slate-600 dark:text-slate-400">
              {{ t('HELP_CENTER.PORTAL_SWITCHER.ARTICLES') }}:
              <span class="text-slate-800 dark:text-slate-200">
                {{ getArticlesCount(portal) }}
              </span>
            </span>
            <div class="flex-shrink-0 w-px h-3 bg-slate-50 dark:bg-slate-700" />
            <span
              :title="portal.custom_domain"
              class="inline-flex items-center flex-shrink-0 gap-1 text-slate-600 dark:text-slate-400"
            >
              {{ t('HELP_CENTER.PORTAL_SWITCHER.DOMAIN') }}:
              <span
                class="text-slate-800 dark:text-slate-200 truncate max-w-[80px]"
              >
                {{ portal.custom_domain || '-' }}
              </span>
            </span>
            <div class="flex-shrink-0 w-px h-3 bg-slate-50 dark:bg-slate-700" />
            <span
              :title="portal.slug"
              class="inline-flex items-center flex-shrink-0 gap-1 text-slate-600 dark:text-slate-400"
            >
              {{ t('HELP_CENTER.PORTAL_SWITCHER.PORTAL_NAME') }}:
              <span
                class="text-slate-800 dark:text-slate-200 truncate max-w-[80px]"
              >
                {{ portal.slug || '-' }}
              </span>
            </span>
          </div>
        </div>
        <div
          v-if="index < portals.length - 1 && portals.length > 1"
          class="w-full h-px bg-slate-50 dark:bg-slate-700/50"
        />
      </template>
    </div>
  </div>
</template>
