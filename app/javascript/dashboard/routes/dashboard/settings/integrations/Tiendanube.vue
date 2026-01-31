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
const storeId = ref('');
const isSubmitting = ref(false);
const storeIdError = ref('');
const integration = useFunctionGetter('integrations/getIntegration', 'tiendanube');
const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const hideStoreIdModal = () => {
  storeId.value = '';
  storeIdError.value = '';
  isSubmitting.value = false;
};

const validateStoreId = id => {
  // Tiendanube store IDs can be alphanumeric (e.g., 'ideas36' or '123456')
  const pattern = /^[a-zA-Z0-9]+$/;
  return pattern.test(id) && id.length > 0;
};

const openStoreIdDialog = () => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const handleStoreIdSubmit = async () => {
  try {
    storeIdError.value = '';
    if (!validateStoreId(storeId.value)) {
      storeIdError.value =
        'Please enter a valid Tiendanube store ID';
      return;
    }

    isSubmitting.value = true;
    const { data } = await integrationAPI.connectTiendanube(storeId.value);

    if (data.redirect_url) {
      window.location.href = data.redirect_url;
    }
  } catch (error) {
    storeIdError.value = error.message;
  } finally {
    isSubmitting.value = false;
  }
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
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div
      v-if="integrationLoaded && !uiFlags.isCreatingTiendanube"
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
          title: $t('INTEGRATION_SETTINGS.TIENDANUBE.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.TIENDANUBE.DELETE.MESSAGE'),
        }"
      >
        <template #action>
          <Button
            teal
            :label="$t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            @click="openStoreIdDialog"
          />
        </template>
      </Integration>
      <div
        v-if="error"
        class="flex items-center justify-center flex-1 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow p-6"
      >
        <p class="text-n-ruby-9">
          {{ $t('INTEGRATION_SETTINGS.TIENDANUBE.ERROR') }}
        </p>
      </div>
      <Dialog
        ref="dialogRef"
        :title="$t('INTEGRATION_SETTINGS.TIENDANUBE.STORE_ID.TITLE')"
        :is-loading="isSubmitting"
        @confirm="handleStoreIdSubmit"
        @close="hideStoreIdModal"
      >
        <template #description>
          <div class="flex flex-col gap-4 mt-4">
            <p class="text-sm text-n-slate-11 mb-2">
              Access order details and customer data from your Tiendanube store.
            </p>
            <div class="flex flex-col gap-2">
              <label class="text-sm font-medium text-n-slate-12">
                {{ $t('INTEGRATION_SETTINGS.TIENDANUBE.STORE_ID.LABEL') }}
              </label>
              <input
                v-model="storeId"
                type="text"
                :placeholder="$t('INTEGRATION_SETTINGS.TIENDANUBE.STORE_ID.PLACEHOLDER')"
                class="w-full px-3 py-2 text-sm border rounded-md bg-n-alpha-3 border-n-weak text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <p v-if="!storeIdError" class="text-xs text-n-slate-11">
                {{ $t('INTEGRATION_SETTINGS.TIENDANUBE.STORE_ID.HELP') }}
              </p>
              <p v-else class="text-xs text-n-ruby-9">
                {{ storeIdError }}
              </p>
            </div>
          </div>
        </template>
      </Dialog>
    </div>

    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
