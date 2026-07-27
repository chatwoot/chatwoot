<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import VerticalTabs from 'dashboard/components-next/vertical-tabs/VerticalTabs.vue';
import PortalGeneralSettings from './PortalGeneralSettings.vue';
import PortalConfigurationSettings from './PortalConfigurationSettings.vue';
import PortalLayoutContentSettings from './PortalLayoutContentSettings.vue';
import PortalIntegrationsSettings from './PortalIntegrationsSettings.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

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

const activeTab = ref('general');

const settingsTabs = computed(() => [
  {
    id: 'general',
    label: t('HELP_CENTER.PORTAL_SETTINGS.NAV.GENERAL'),
    icon: 'i-lucide-settings-2',
  },
  {
    id: 'domain',
    label: t('HELP_CENTER.PORTAL_SETTINGS.NAV.DOMAIN'),
    icon: 'i-lucide-globe',
  },
  {
    id: 'appearance',
    label: t('HELP_CENTER.PORTAL_SETTINGS.NAV.APPEARANCE'),
    icon: 'i-lucide-palette',
  },
  {
    id: 'integrations',
    label: t('HELP_CENTER.PORTAL_SETTINGS.NAV.INTEGRATIONS'),
    icon: 'i-lucide-blocks',
  },
]);

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
      <VerticalTabs
        v-else-if="activePortal"
        v-model="activeTab"
        :tabs="settingsTabs"
        content-class="max-w-[40rem] pb-8"
      >
        <template #general>
          <PortalGeneralSettings
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal="handleUpdatePortal"
            @delete-portal="handleDeletePortal"
          />
        </template>

        <template #domain>
          <PortalConfigurationSettings
            :active-portal="activePortal"
            :is-fetching="isFetching"
            :is-fetching-status="isFetchingSSLStatus"
            @update-portal-configuration="handleUpdatePortalConfiguration"
            @refresh-status="fetchSSLStatus"
            @send-cname-instructions="handleSendCnameInstructions"
          />
        </template>

        <template #appearance>
          <PortalLayoutContentSettings
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal-configuration="handleUpdatePortalConfiguration"
          />
        </template>

        <template #integrations>
          <PortalIntegrationsSettings
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal-configuration="handleUpdatePortalConfiguration"
          />
        </template>
      </VerticalTabs>
    </template>
  </HelpCenterLayout>
</template>
