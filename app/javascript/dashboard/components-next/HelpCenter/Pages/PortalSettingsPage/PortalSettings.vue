<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import PortalGeneralSettings from './PortalGeneralSettings.vue';
import PortalConfigurationSettings from './PortalConfigurationSettings.vue';
import PortalLayoutContentSettings from './PortalLayoutContentSettings.vue';
import PortalIntegrationsSettings from './PortalIntegrationsSettings.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  portals: {
    type: Array,
    required: true,
  },
  isFetching: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortal',
  'updatePortalConfiguration',
  'deletePortal',
  'refreshStatus',
  'sendCnameInstructions',
]);

const { t } = useI18n();
const route = useRoute();

const SETTINGS_TABS = [
  {
    id: 'general',
    labelKey: 'HELP_CENTER.PORTAL_SETTINGS.NAV.GENERAL',
    icon: 'i-lucide-settings-2',
  },
  {
    id: 'domain',
    labelKey: 'HELP_CENTER.PORTAL_SETTINGS.NAV.DOMAIN',
    icon: 'i-lucide-globe',
  },
  {
    id: 'appearance',
    labelKey: 'HELP_CENTER.PORTAL_SETTINGS.NAV.APPEARANCE',
    icon: 'i-lucide-palette',
  },
  {
    id: 'integrations',
    labelKey: 'HELP_CENTER.PORTAL_SETTINGS.NAV.INTEGRATIONS',
    icon: 'i-lucide-blocks',
  },
];

const activeTab = ref('general');

const currentPortalSlug = computed(() => route.params.portalSlug);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isFetchingSSLStatus = useMapGetter('portals/isFetchingSSLStatus');

const activePortal = computed(() => {
  return props.portals?.find(portal => portal.slug === currentPortalSlug.value);
});

const isLoading = computed(() => props.isFetching || isSwitchingPortal.value);

const handleUpdatePortal = portal => {
  emit('updatePortal', portal);
};

const handleUpdatePortalConfiguration = portal => {
  emit('updatePortalConfiguration', portal);
};

const fetchSSLStatus = () => {
  emit('refreshStatus');
};

const handleSendCnameInstructions = payload => {
  emit('sendCnameInstructions', payload);
};

const handleDeletePortal = portal => {
  emit('deletePortal', portal);
};
</script>

<template>
  <HelpCenterLayout
    :show-pagination-footer="false"
    :breadcrumb-label="t('HELP_CENTER.BREADCRUMB.SETTINGS')"
  >
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 pt-2 pb-8 text-n-slate-11"
      >
        <Spinner />
      </div>
      <div v-else-if="activePortal" class="flex items-start w-full gap-8">
        <nav class="sticky top-0 flex flex-col w-48 gap-0.5 shrink-0 py-1">
          <button
            v-for="tab in SETTINGS_TABS"
            :key="tab.id"
            type="button"
            class="flex items-center w-full h-9 gap-2 px-2.5 text-sm transition-colors rounded-lg"
            :class="
              activeTab === tab.id
                ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
                : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
            "
            :aria-current="activeTab === tab.id ? 'page' : undefined"
            @click="activeTab = tab.id"
          >
            <Icon :icon="tab.icon" class="shrink-0 size-4" />
            {{ t(tab.labelKey) }}
          </button>
        </nav>

        <div class="flex flex-col flex-1 min-w-0 max-w-[40rem] pb-8">
          <PortalGeneralSettings
            v-if="activeTab === 'general'"
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal="handleUpdatePortal"
            @delete-portal="handleDeletePortal"
          />

          <PortalConfigurationSettings
            v-else-if="activeTab === 'domain'"
            :active-portal="activePortal"
            :is-fetching="isFetching"
            :is-fetching-status="isFetchingSSLStatus"
            @update-portal-configuration="handleUpdatePortalConfiguration"
            @refresh-status="fetchSSLStatus"
            @send-cname-instructions="handleSendCnameInstructions"
          />

          <PortalLayoutContentSettings
            v-else-if="activeTab === 'appearance'"
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal-configuration="handleUpdatePortalConfiguration"
          />

          <PortalIntegrationsSettings
            v-else-if="activeTab === 'integrations'"
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal-configuration="handleUpdatePortalConfiguration"
          />
        </div>
      </div>
    </template>
  </HelpCenterLayout>
</template>
