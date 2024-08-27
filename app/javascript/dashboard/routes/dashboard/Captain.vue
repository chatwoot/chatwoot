<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';

import integrations from '../../api/integrations';
import Spinner from 'shared/components/Spinner.vue';

const isLoading = ref(true);
const captainURL = ref('');
const hasError = ref(false);

const loadCaptainFrame = async integration => {
  if (!integration || !integration.enabled) {
    return;
  }
  try {
    isLoading.value = true;
    const { data } = await integrations.fetchCaptainURL();
    captainURL.value = data.sso_url;
  } catch (error) {
    hasError.value = true;
  } finally {
    isLoading.value = false;
  }
};

const getters = useStoreGetters();
const captainIntegration = computed(() =>
  getters['integrations/getIntegration'].value('captain', null)
);

onMounted(() => loadCaptainFrame(captainIntegration.value));

watch(captainIntegration, updatedIntegration =>
  loadCaptainFrame(updatedIntegration)
);
</script>

<template>
  <div
    class="flex-1 overflow-auto flex gap-8 flex-col font-inter text-slate-900 dark:text-slate-500"
  >
    <div class="flex-1 flex items-center justify-center">
      <div v-if="!captainIntegration">
        {{ $t('INTEGRATION_SETTINGS.CAPTAIN.DISABLED') }}
      </div>
      <div
        v-else-if="!captainIntegration.enabled"
        class="flex-1 flex flex-col gap-2 items-center justify-center"
      >
        <div>{{ $t('INTEGRATION_SETTINGS.CAPTAIN.DISABLED') }}</div>
        <router-link :to="{ name: 'settings_applications' }">
          <woot-button class="clear link">
            {{ $t('INTEGRATION_SETTINGS.CAPTAIN.CLICK_HERE_TO_CONFIGURE') }}
          </woot-button>
        </router-link>
      </div>
      <div
        v-else-if="isLoading"
        class="flex-1 flex items-center justify-center"
      >
        <Spinner color-scheme="primary" />
        <span>{{ $t('INTEGRATION_SETTINGS.CAPTAIN.LOADING_CONSOLE') }}</span>
      </div>
      <div v-else-if="!isLoading && hasError">
        {{ $t('INTEGRATION_SETTINGS.CAPTAIN.FAILED_TO_LOAD_CONSOLE') }}
      </div>
      <iframe
        v-else-if="!isLoading && captainURL"
        :src="captainURL"
        class="w-full min-h-[800px] h-full"
      />
    </div>
  </div>
</template>
