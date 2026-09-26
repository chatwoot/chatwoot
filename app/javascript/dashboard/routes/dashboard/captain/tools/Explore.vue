<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMapGetter } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import {
  fetchToolsCatalog,
  isVerifiedOwner,
} from 'dashboard/api/captain/toolsCatalog';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import InstallManifestDialog from 'dashboard/components-next/captain/pageComponents/customTool/InstallManifestDialog.vue';
import ToolsetCatalogCard from 'dashboard/components-next/captain/pageComponents/customTool/ToolsetCatalogCard.vue';
import ToolsetDetailsPanel from 'dashboard/components-next/captain/pageComponents/customTool/ToolsetDetailsPanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Policy from 'dashboard/components/policy.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');
const { run: runCatalogRequest, isPending: isLoading } = useAbortableRequest();

const assistantId = computed(() => route.params.assistantId);
const installManifestDialogRef = ref(null);
const detailsPanelRef = ref(null);
const toolsets = ref([]);
const hasError = ref(false);
// null shows every category
const selectedCategory = ref(null);

const toolsRoute = computed(() => ({
  name: 'captain_tools_index',
  params: {
    accountId: route.params.accountId,
    assistantId: assistantId.value,
  },
}));

const categoryPills = computed(() => [
  { value: null, label: t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ALL') },
  ...[...new Set(toolsets.value.map(toolset => toolset.category))].map(
    category => ({ value: category, label: category })
  ),
]);

const visibleToolsets = computed(() =>
  selectedCategory.value
    ? toolsets.value.filter(
        toolset => toolset.category === selectedCategory.value
      )
    : toolsets.value
);

const loadCatalog = async () => {
  hasError.value = false;
  try {
    const catalog = await runCatalogRequest(signal =>
      fetchToolsCatalog(globalConfig.value.captainToolsCatalogURL, { signal })
    );
    // Chatwoot's own toolsets lead; the stable sort keeps the catalog order otherwise
    if (catalog)
      toolsets.value = catalog.toolsets.toSorted(
        (a, b) => isVerifiedOwner(b.owner) - isVerifiedOwner(a.owner)
      );
  } catch {
    hasError.value = true;
  }
};

const openToolset = toolset => detailsPanelRef.value.open(toolset);

// The dialog outlives an assistant switch, so a late install must not move the newly opened assistant
let installingAssistantId = null;

const openInstallDialog = source => {
  installingAssistantId = assistantId.value;
  installManifestDialogRef.value.open(source);
};

const installToolset = toolset => openInstallDialog(toolset.source);

const onInstalled = () => {
  if (installingAssistantId === assistantId.value) {
    router.push(toolsRoute.value);
  }
};

onMounted(() => {
  // Installs are off by default, and a bookmarked catalog would only offer installs that fail
  if (!globalConfig.value.captainToolsManifestEnabled) {
    router.replace(toolsRoute.value);
    return;
  }
  loadCatalog();
});
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.HEADER')"
    :back-url="toolsRoute"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #headerActions>
      <Policy :permissions="['administrator']">
        <Button
          :label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.BUTTON')"
          icon="i-lucide-file-box"
          size="sm"
          faded
          slate
          @click="openInstallDialog()"
        />
      </Policy>
    </template>

    <template #paywall>
      <CaptainPaywall feature-prefix="CAPTAIN.CUSTOM_TOOLS" />
    </template>

    <template #body>
      <div class="flex flex-col gap-6">
        <p class="mb-0 text-sm text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.DESCRIPTION') }}
        </p>

        <div v-if="isLoading" class="flex justify-center py-10">
          <Spinner />
        </div>

        <p v-else-if="hasError" class="mb-0 text-sm text-n-ruby-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.LOAD_ERROR') }}
        </p>

        <template v-else>
          <div class="flex flex-wrap gap-2">
            <Button
              v-for="pill in categoryPills"
              :key="pill.label"
              :label="pill.label"
              size="sm"
              :variant="selectedCategory === pill.value ? 'solid' : 'faded'"
              :color="selectedCategory === pill.value ? 'blue' : 'slate'"
              class="!rounded-full"
              @click="selectedCategory = pill.value"
            />
          </div>

          <p
            v-if="!visibleToolsets.length"
            class="mb-0 text-sm text-n-slate-11"
          >
            {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.EMPTY') }}
          </p>
          <div
            v-else
            class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3"
          >
            <ToolsetCatalogCard
              v-for="toolset in visibleToolsets"
              :key="toolset.source"
              :toolset="toolset"
              @click="openToolset(toolset)"
            />
          </div>
        </template>
      </div>
    </template>
  </PageLayout>

  <ToolsetDetailsPanel ref="detailsPanelRef" @install="installToolset" />

  <InstallManifestDialog
    ref="installManifestDialogRef"
    :assistant-id="assistantId"
    @installed="onInstalled"
  />
</template>
