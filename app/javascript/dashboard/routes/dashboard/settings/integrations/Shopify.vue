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
import shopifyAPI from 'dashboard/api/integrations/shopify';

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
const integrationLoaded = ref(false);
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
          <a
            :href="integration.action"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Button
              teal
              :label="$t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            />
          </a>
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
    </div>

    <div v-else class="flex flex-1 justify-center items-center">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
