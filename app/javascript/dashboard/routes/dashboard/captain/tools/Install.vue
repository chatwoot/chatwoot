<script setup>
import { onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { uiSettings } = useUISettings();
const assistants = useMapGetter('captainAssistants/getRecords');

// Opens the tools page of the last active assistant, which runs the install flow from the query
onMounted(async () => {
  await store.dispatch('captainAssistants/get');
  const { accountId } = route.params;

  if (!assistants.value.length) {
    router.replace({
      name: 'captain_assistants_create_index',
      params: { accountId },
    });
    return;
  }

  const lastActiveId = Number(uiSettings.value?.last_active_assistant_id);
  const assistantId = assistants.value.some(a => a.id === lastActiveId)
    ? lastActiveId
    : assistants.value[0].id;

  router.replace({
    name: 'captain_tools_index',
    params: { accountId, assistantId },
    query: { install: route.query.source },
  });
});
</script>

<template>
  <div
    class="flex items-center justify-center w-full bg-n-surface-1 text-n-slate-11"
  >
    <Spinner />
  </div>
</template>
