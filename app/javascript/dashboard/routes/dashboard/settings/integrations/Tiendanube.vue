<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import integrationAPI from 'dashboard/api/integrations';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const integrationLoaded = ref(false);
const isRedirecting = ref(false);

const integration = computed(() =>
  store.getters['integrations/getIntegration']('tiendanube')
);

const uiFlags = computed(() =>
  store.getters['integrations/getUIFlags']
);

const integrationAction = computed(() => {
  if (integration.value?.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const connectTiendanube = async () => {
  console.log('CLICK CONNECT TIENDANUBE');

  const { data } = await integrationAPI.connectTiendanube();
  window.location.href = data.redirect_url;
};

const initializeTiendanubeIntegration = async () => {
  await store.dispatch('integrations/get', 'tiendanube');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeTiendanubeIntegration();
});
</script>

<template>
  <div
    v-if="integrationLoaded && !uiFlags.isCreatingTiendanube"
    class="flex flex-col flex-1 overflow-auto gap-5 pt-1 pb-10"
  >
    <Integration
      :integration-id="integration.id"
      :integration-logo="integration.logo"
      :integration-name="integration.name"
      :integration-description="integration.description"
      :integration-enabled="integration.enabled"
      :integration-action="integrationAction"
      :delete-confirmation-text="{
        title: 'Disconnect Tiendanube',
        message: 'Are you sure you want to disconnect Tiendanube?',
      }"
    >
      <template #action>
        <Button
          faded
          blue
          :label="$t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
          @click="connectTiendanube"
        />
      </template>
    </Integration>
  </div>

  <div v-else class="flex items-center justify-center flex-1">
    <Spinner color-scheme="primary" />
  </div>
</template>
