<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { isShopifyBillingAccount } from 'v3/helpers/AuthHelper';
import shopifyAPI from 'dashboard/api/integrations/shopify';
import Integration from './Integration.vue';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

defineProps({
  error: {
    type: String,
    default: '',
  },
});

const store = useStore();
const integrationLoaded = ref(false);
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const { replaceInstallationName } = useBranding();
const integration = useFunctionGetter('integrations/getIntegration', 'shopify');
const uiFlags = useMapGetter('integrations/getUIFlags');
const currentAccount = useMapGetter('getCurrentAccount');
const isShopifyBillingManaged = computed(() =>
  isShopifyBillingAccount(currentAccount.value)
);

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const hook = computed(() => {
  const { hooks = [] } = integration.value || {};
  const [firstHook] = hooks;
  return firstHook || {};
});

const storeDomain = computed(() => hook.value.reference_id || '');

const formattedHelpText = computed(() => {
  return formatMessage(
    replaceInstallationName(
      t('INTEGRATION_SETTINGS.SHOPIFY.HELP_TEXT.BODY', {
        storeDomain: storeDomain.value,
      })
    ),
    false
  );
});

const clearPendingInstallToken = async () => {
  const query = { ...route.query };
  delete query.shopify_pending_install;
  await router.replace({ query });
};

const completePendingInstall = async token => {
  try {
    await shopifyAPI.completeInstall(token);
    await store.dispatch('integrations/get', 'shopify');
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.PENDING_INSTALL.SUCCESS'));
    await clearPendingInstallToken();
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.PENDING_INSTALL.ERROR'));
    if (error.response?.status === 422) {
      await clearPendingInstallToken();
    }
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
  <SettingsLayout :is-loading="!integrationLoaded || uiFlags.isCreatingShopify">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.SHOPIFY.HEADER')"
        description=""
        feature-name="shopify_integration"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <Integration
          :integration-id="integration.id"
          :integration-logo="integration.logo"
          :integration-name="integration.name"
          :integration-description="integration.description"
          :integration-enabled="integration.enabled"
          :integration-action="integrationAction"
          :hide-enabled-action="isShopifyBillingManaged"
          :delete-confirmation-text="{
            title: t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.MESSAGE'),
          }"
        />

        <div
          v-if="integration.enabled"
          class="flex-1 w-full px-6 py-5 rounded-md shadow outline outline-n-container outline-1 bg-n-alpha-3"
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
          class="flex items-center justify-center flex-1 p-6 rounded-md shadow outline outline-n-container outline-1 bg-n-alpha-3"
        >
          <p class="text-n-ruby-9">
            {{ t('INTEGRATION_SETTINGS.SHOPIFY.ERROR') }}
          </p>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
