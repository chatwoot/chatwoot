<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { uiSettings } = useUISettings();
const assistants = useMapGetter('captainAssistants/getRecords');
const hasError = ref(false);

// Leaving while assistants load must not pull the user back here once they arrive
let isUnmounted = false;
onBeforeUnmount(() => {
  isUnmounted = true;
});

// Opens the tools page of the last active assistant, which runs the install flow from the query
onMounted(async () => {
  const { accountId } = route.params;
  const { source } = route.query;
  try {
    await store.dispatch('captainAssistants/get');
  } catch {
    hasError.value = true;
    return;
  }
  if (isUnmounted) return;

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
    query: { install: source },
  });
});
</script>

<template>
  <div
    class="flex items-center justify-center w-full bg-n-surface-1 text-n-slate-11"
  >
    <p v-if="hasError" class="mb-0 text-sm text-n-ruby-11">
      {{ t('CAPTAIN.CUSTOM_TOOLS.INSTALL_LINK.LOAD_ERROR') }}
    </p>
    <Spinner v-else />
  </div>
</template>
