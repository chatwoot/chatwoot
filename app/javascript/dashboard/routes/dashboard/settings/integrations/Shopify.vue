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

import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  error: {
    type: String,
    default: '',
  },
});

const store = useStore();
const dialogRef = ref(null);
const integrationLoaded = ref(false);
const storeUrl = ref('');
const isSubmitting = ref(false);
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
  storeUrl.value = '';
  storeUrlError.value = '';
  isSubmitting.value = false;
};

const validateStoreUrl = url => {
  const pattern = /^[a-zA-Z0-9][a-zA-Z0-9-]*\.myshopify\.com$/;
  return pattern.test(url);
};

const openStoreUrlDialog = () => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const handleStoreUrlSubmit = async () => {
  try {
    storeUrlError.value = '';
    if (!validateStoreUrl(storeUrl.value)) {
      storeUrlError.value =
        'Please enter a valid Shopify store URL (e.g., your-store.myshopify.com)';
      return;
    }

    isSubmitting.value = true;
    const { data } = await integrationAPI.connectShopify({
      shopDomain: storeUrl.value,
    });

    if (data.redirect_url) {
      window.location.href = data.redirect_url;
    }
  } catch (error) {
    storeUrlError.value = error.message;
  } finally {
    isSubmitting.value = false;
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
    <div
      v-if="integrationLoaded && !uiFlags.isCreatingShopify"
      class="flex flex-col gap-6"
    >
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
          <Button
            teal
            :label="$t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            @click="openStoreUrlDialog"
          />
        </template>
      </Integration>
      <div
        v-if="error"
        class="flex items-center justify-center flex-1 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow p-6"
      >
        <p class="text-red-500">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ERROR') }}
        </p>
      </div>
      <Dialog
        ref="dialogRef"
        :title="$t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.TITLE')"
        :is-loading="isSubmitting"
        @confirm="handleStoreUrlSubmit"
        @close="hideStoreUrlModal"
      >
        <Input
          v-model="storeUrl"
          :label="$t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.PLACEHOLDER')
          "
          :message="
            !storeUrlError
              ? $t('INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.HELP')
              : storeUrlError
          "
          :message-type="storeUrlError ? 'error' : 'info'"
        />
      </Dialog>
    </div>

    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
