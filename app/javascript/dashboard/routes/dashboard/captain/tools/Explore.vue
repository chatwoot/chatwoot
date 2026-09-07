<script setup>
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import ToolsetCatalog from 'dashboard/components-next/captain/pageComponents/customTool/ToolsetCatalog.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const { accountId, assistantId } = route.params;
const backUrl = frontendURL(
  `accounts/${accountId}/captain/${assistantId}/tools`
);

// The tools page picks up `source` and opens the import dialog with it prefilled.
const install = source =>
  router.push({
    name: 'captain_tools_index',
    params: { accountId, assistantId },
    query: { source },
  });
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.EXPLORE')"
    :back-url="backUrl"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS"
    :show-assistant-switcher="false"
    :show-pagination-footer="false"
    :show-know-more="false"
  >
    <template #paywall>
      <CaptainPaywall feature-prefix="CAPTAIN.CUSTOM_TOOLS" />
    </template>
    <template #body>
      <ToolsetCatalog @install="install" />
    </template>
  </PageLayout>
</template>
