<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import DashboardAppFrame from 'dashboard/components/widgets/DashboardApp/Frame.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const dashboardApps = useMapGetter('dashboardApps/getRecords');
const isLoadingApps = ref(true);

const appId = computed(() => Number(route.params.appId));

const dashboardApp = computed(() => {
  return dashboardApps.value.find(app => app.id === appId.value);
});

const notFound = computed(() => !isLoadingApps.value && !dashboardApp.value);

onMounted(async () => {
  try {
    if (!dashboardApps.value.length) {
      await store.dispatch('dashboardApps/get');
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to fetch dashboard apps', error);
  } finally {
    isLoadingApps.value = false;
  }
});
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background">
    <div
      v-if="isLoadingApps"
      class="flex items-center justify-center w-full h-full"
    >
      <Spinner />
    </div>
    <div
      v-else-if="notFound"
      class="flex items-center justify-center w-full h-full px-4 text-center"
    >
      <p class="text-sm text-n-slate-11">
        {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.VIEW.NOT_FOUND') }}
      </p>
    </div>
    <div v-else class="flex flex-col w-full h-full">
      <div
        class="flex items-center gap-3 px-4 py-3 border-b border-n-weak bg-n-background"
      >
        <h1 class="text-lg font-semibold text-n-slate-12">
          {{ dashboardApp.title }}
        </h1>
      </div>
      <div class="flex-1 min-h-0">
        <DashboardAppFrame
          v-if="dashboardApp"
          is-visible
          :config="dashboardApp.content"
          :position="0"
          :current-chat="null"
        />
      </div>
    </div>
  </div>
</template>
