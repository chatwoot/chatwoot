<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useBranding } from 'shared/composables/useBranding';
import IntegrationItem from './IntegrationItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

const store = useStore();
const getters = useStoreGetters();
const { replaceInstallationName } = useBranding();
const { t } = useI18n();

const uiFlags = getters['integrations/getUIFlags'];

const integrationList = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const helpURL = computed(() => getHelpUrlForFeature('integrations'));

const pageSubtitle = computed(() =>
  replaceInstallationName(t('INTEGRATION_SETTINGS.PAGE_SUBTITLE'))
);

onMounted(() => {
  store.dispatch('integrations/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('INTEGRATION_SETTINGS.LIST.LOADING')"
  >
    <template #header>
      <div class="flex flex-col gap-6 pb-2">
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('INTEGRATION_SETTINGS.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('INTEGRATION_SETTINGS.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ pageSubtitle }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('INTEGRATION_SETTINGS.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
      </div>
    </template>
    <template #body>
      <div
        class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
      >
        <div class="bg-surface-container-low p-4 sm:p-6">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
            <IntegrationItem
              v-for="item in integrationList"
              :id="item.id"
              :key="item.id"
              :name="item.name"
              :description="item.description"
              :enabled="item.enabled"
            />
          </div>
        </div>
      </div>
      <p class="mt-6 text-xs font-medium text-on-primary-container">
        {{
          t('INTEGRATION_SETTINGS.LIST.SHOWING_COUNT', {
            count: integrationList.length,
          })
        }}
      </p>
    </template>
  </SettingsLayout>
</template>
