<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import integrationAPI from 'dashboard/api/integrations';

const store = useStore();

const integrationLoaded = ref(false);
const showStoreUrlModal = ref(false);
const storeUrl = ref('');
const storeUrlError = ref('');

const integration = useFunctionGetter('integrations/getIntegration', 'shopify');
const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const hideStoreUrlModal = () => {
  showStoreUrlModal.value = false;
  storeUrl.value = '';
  storeUrlError.value = '';
};

const validateStoreUrl = url => {
  const pattern = /^[a-zA-Z0-9][a-zA-Z0-9-]*\.myshopify\.com$/;
  return pattern.test(url);
};

const handleStoreUrlSubmit = async () => {
  try {
    storeUrlError.value = '';
    if (!validateStoreUrl(storeUrl.value)) {
      storeUrlError.value =
        'Please enter a valid Shopify store URL (e.g., your-store.myshopify.com)';
      return;
    }

    const { data } = await integrationAPI.connectShopify({
      shopDomain: storeUrl.value,
    });

    if (data.redirect_url) {
      window.location.href = data.redirect_url;
    }
  } catch (error) {
    storeUrlError.value = error.message;
  }
};

const initializeShopifyIntegration = async () => {
  await store.dispatch('integrations/get', 'shopify');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeShopifyIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div v-if="integrationLoaded && !uiFlags.isCreatingShopify">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.MESSAGE'),
        }"
      >
        <template #action>
          <button
            class="rounded button success nice"
            @click="showStoreUrlModal = true"
          >
            {{ $t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') }}
          </button>
        </template>
      </Integration>

      <woot-modal
        v-if="!integration.enabled"
        v-model:show="showStoreUrlModal"
        :on-close="hideStoreUrlModal"
      >
        <div class="p-4">
          <h2 class="text-lg font-medium mb-4">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.TITLE') }}
          </h2>
          <form class="space-y-4" @submit.prevent="handleStoreUrlSubmit">
            <div>
              <label class="block text-sm font-medium text-slate-700">
                {{ $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.LABEL') }}
              </label>
              <woot-input
                v-model="storeUrl"
                :placeholder="
                  $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.PLACEHOLDER')
                "
                type="text"
                :error="storeUrlError"
              />
              <p class="mt-1 text-sm text-slate-500">
                {{ $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.HELP') }}
              </p>
            </div>
            <div class="flex justify-end space-x-2">
              <woot-button
                variant="clear"
                size="small"
                @click="hideStoreUrlModal"
              >
                {{ $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.CANCEL') }}
              </woot-button>
              <woot-button variant="primary" size="small" type="submit">
                {{ $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.SUBMIT') }}
              </woot-button>
            </div>
          </form>
        </div>
      </woot-modal>
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
