<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import integrationAPI from 'dashboard/api/integrations';
import shopifyAPI from 'dashboard/api/integrations/shopify';

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
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const dialogRef = ref(null);
const integrationLoaded = ref(false);
const storeUrl = ref('');
const isSubmitting = ref(false);
const storeUrlError = ref('');
const integration = useFunctionGetter('integrations/getIntegration', 'shopify');
const uiFlags = useMapGetter('integrations/getUIFlags');

const hook = computed(() => {
  const { hooks = [] } = integration.value || {};
  const [firstHook] = hooks;
  return firstHook || {};
});

const storeDomain = computed(() => hook.value.reference_id || '');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const formattedHelpText = computed(() => {
  return formatMessage(
    t('INTEGRATION_SETTINGS.SHOPIFY.HELP_TEXT.BODY', {
      storeDomain: storeDomain.value,
    }),
    false
  );
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
      storeUrlError.value = t(
        'INTEGRATION_SETTINGS.SHOPIFY.STORE_URL.INVALID_URL'
      );
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

const completePendingInstall = async token => {
  try {
    await shopifyAPI.completeInstall(token);
    await store.dispatch('integrations/get', 'shopify');
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.PENDING_INSTALL.SUCCESS'));
  } catch {
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.PENDING_INSTALL.ERROR'));
  } finally {
    router.replace({ query: {} });
  }
};

const initializeShopifyIntegration = async () => {
  await store.dispatch('integrations/get', 'shopify');
  integrationLoaded.value = true;

  const pendingInstallToken = route.query.shopify_pending_install;
  if (pendingInstallToken) {
    await completePendingInstall(pendingInstallToken);
  }
};

onMounted(() => {
  initializeShopifyIntegration();
});
</script>

<template>
  <div class="overflow-auto flex-grow flex-shrink p-4 mx-auto max-w-6xl">
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
        v-if="integration.enabled"
        class="flex-1 px-6 py-5 w-full rounded-md shadow outline outline-n-container outline-1 bg-n-alpha-3"
      >
        <div class="max-w-5xl prose-lg">
          <h5 class="tracking-tight text-n-slate-12">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.HELP_TEXT.TITLE') }}
          </h5>
          <div v-dompurify-html="formattedHelpText" class="text-n-slate-11" />
        </div>
      </div>

      <div
        v-if="error"
        class="flex flex-1 justify-center items-center p-6 rounded-md shadow outline outline-n-container outline-1 bg-n-alpha-3"
      >
        <p class="text-n-ruby-9">
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

    <div v-else class="flex flex-1 justify-center items-center">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
