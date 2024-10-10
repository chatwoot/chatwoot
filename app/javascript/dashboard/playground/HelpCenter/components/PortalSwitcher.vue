<script setup>
import { ref } from 'vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

const portals = ref([
  {
    id: 1,
    name: 'Chatwoot Help Center',
    articles: 67,
    domain: 'chatwoot.help',
    slug: 'handbook',
  },
  {
    id: 2,
    name: 'Chatwoot Handbook',
    articles: 67,
    domain: 'chatwoot.help',
    slug: 'handbook',
  },
  {
    id: 3,
    name: 'Chatwoot Handbook',
    articles: 67,
    domain: 'chatwoot.help',
    slug: 'handbook',
  },
]);

const selectedPortal = ref(1);

const handlePortalChange = id => {
  selectedPortal.value = id;
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div
    class="pt-5 pb-3 bg-white z-50 dark:bg-slate-800 absolute w-[440px] rounded-xl shadow-md flex flex-col gap-4"
  >
    <div class="flex items-center justify-between gap-2 px-6 pb-2">
      <div class="flex flex-col gap-1">
        <h2 class="text-base font-medium text-slate-900 dark:text-slate-50">
          Portals
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-300">
          Create and manage multiple portals
        </p>
      </div>
      <ButtonV4 label="New portal" variant="secondary" icon="add" size="sm" />
    </div>
    <div v-if="portals.length > 0" class="flex flex-col gap-3">
      <template v-for="(portal, index) in portals" :key="portal.id">
        <div class="flex flex-col gap-2 px-6 py-2">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <input
                :id="portal.id"
                v-model="selectedPortal"
                type="radio"
                :value="portal.id"
                class="mr-3"
                @change="handlePortalChange(portal.id)"
              />
              <label
                :for="portal.id"
                class="text-sm font-medium text-slate-900 dark:text-slate-100"
              >
                {{ portal.name }}
              </label>
            </div>
            <div class="w-4 h-4 rounded-full bg-slate-100 dark:bg-slate-700" />
          </div>
          <div class="inline-flex items-center gap-2 py-1 text-sm">
            <span class="text-slate-600 dark:text-slate-400">
              articles:
              <span class="text-slate-800 dark:text-slate-200">
                {{ portal.articles }}
              </span>
            </span>
            <div class="w-px h-3 bg-slate-50 dark:bg-slate-700" />
            <span class="text-slate-600 dark:text-slate-400">
              domain:
              <span class="text-slate-800 dark:text-slate-200">
                {{ portal.domain }}
              </span>
            </span>
            <div class="w-px h-3 bg-slate-50 dark:bg-slate-700" />
            <span class="text-slate-600 dark:text-slate-400">
              slug:
              <span class="text-slate-800 dark:text-slate-200">
                {{ portal.slug }}
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
