<script setup>
import { onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import CaptainCustomTools from 'dashboard/api/captain/customTools';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const globalConfig = useMapGetter('globalConfig/get');

// Opens the first page with something on it: installed tools, then custom tools, then the catalog.
// Install links carry ?install=, which the Installed page handles.
const landingPage = async () => {
  if (route.query.install) return 'captain_tools_installed';
  try {
    const { data } = await CaptainCustomTools.get({
      assistantId: route.params.assistantId,
    });
    if (data.meta.installed_count > 0) return 'captain_tools_installed';
    if (data.meta.custom_count > 0) return 'captain_tools_custom';
  } catch {
    return 'captain_tools_custom';
  }
  return globalConfig.value.captainToolsManifestEnabled
    ? 'captain_tools_explore'
    : 'captain_tools_custom';
};

onMounted(async () => {
  router.replace({
    name: await landingPage(),
    params: route.params,
    query: route.query,
  });
});
</script>

<template>
  <div class="flex items-center justify-center w-full bg-n-surface-1">
    <Spinner />
  </div>
</template>
