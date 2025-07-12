<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import IframeLoader from 'shared/components/IframeLoader.vue';

const { t } = useI18n();

const route = useRoute();
const store = useStore();
const appId = computed(() => route.params.appId);
const dashboardApps = useMapGetter('dashboardApps/getRecords');
const isLoading = ref(true);

const currentApp = computed(() => {
  return dashboardApps.value.find(app => app.id.toString() === appId.value);
});

const appUrl = computed(() => {
  if (
    !currentApp.value ||
    !currentApp.value.content ||
    !currentApp.value.content.length
  ) {
    return null;
  }
  return currentApp.value.content[0]?.url;
});

onMounted(async () => {
  try {
    if (!dashboardApps.value.length) {
      await store.dispatch('dashboardApps/get');
    }
  } catch (error) {
    // Error loading dashboard apps
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <div class="bg-n-solid-2 border-b border-n-weak p-4">
      <h1 v-if="currentApp" class="text-xl font-semibold text-n-slate-12">
        {{ currentApp.title }}
      </h1>
      <h1 v-else class="text-xl font-semibold text-n-slate-12">
        {{ t('DASHBOARD_APPS.TITLE') }}
      </h1>
    </div>

    <div class="flex-1 relative">
      <div v-if="isLoading" class="flex items-center justify-center h-full">
        <div class="text-n-slate-11">{{ t('DASHBOARD_APPS.LOADING') }}</div>
      </div>

      <div
        v-else-if="!currentApp"
        class="flex items-center justify-center h-full"
      >
        <div class="text-center">
          <h2 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ t('DASHBOARD_APPS.NOT_FOUND') }}
          </h2>
          <p class="text-n-slate-11">
            {{ t('DASHBOARD_APPS.NOT_FOUND_MESSAGE') }}
          </p>
        </div>
      </div>

      <div v-else-if="!appUrl" class="flex items-center justify-center h-full">
        <div class="text-center">
          <h2 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ t('DASHBOARD_APPS.INVALID_CONFIG') }}
          </h2>
          <p class="text-n-slate-11">
            {{ t('DASHBOARD_APPS.INVALID_CONFIG_MESSAGE') }}
          </p>
        </div>
      </div>

      <IframeLoader v-else :url="appUrl" class="h-full w-full" />
    </div>
  </div>
</template>
