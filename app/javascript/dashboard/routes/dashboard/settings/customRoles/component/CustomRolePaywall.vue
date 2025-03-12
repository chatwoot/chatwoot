<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';
import CustomRoleListItem from './CustomRoleTableBody.vue';
import { useI18n } from 'vue-i18n';

const dummyCustomRolesData = [
  {
    name: 'All Permissions',
    description: 'All permissions',
    permissions: [
      'conversation_manage',
      'conversation_participating_manage',
      'conversation_unassigned_manage',
      'contact_manage',
      'report_manage',
      'knowledge_base_manage',
    ],
  },
  {
    name: 'Conversation Permissions',
    description: 'Conversation permissions',
    permissions: [
      'conversation_manage',
      'conversation_participating_manage',
      'conversation_unassigned_manage',
    ],
  },
  {
    name: 'Contact Permissions',
    description: 'Contact permissions',
    permissions: ['contact_manage'],
  },
  {
    name: 'Report Permissions',
    description: 'Report permissions',
    permissions: ['report_manage'],
  },
];

const router = useRouter();

const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');

const isSuperAdmin = computed(() => {
  return currentUser.value.type === 'SuperAdmin';
});
const i18nKey = computed(() =>
  isOnChatwootCloud.value ? 'PAYWALL' : 'ENTERPRISE_PAYWALL'
);

const goToBillingSettings = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: currentAccountId.value },
  });
};

const { t } = useI18n();
const tableHeaders = computed(() => {
  return [
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.NAME'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.DESCRIPTION'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.PERMISSIONS'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.ACTIONS'),
  ];
});
</script>

<template>
  <div class="w-full min-h-[12rem] relative">
    <div class="w-full space-y-3 text-sm">
      <thead class="opacity-30 dark:opacity-30">
        <th
          v-for="thHeader in tableHeaders"
          :key="thHeader"
          class="py-4 pr-4 font-semibold text-left text-slate-700 dark:text-slate-300"
        >
          <span class="mb-0">
            {{ thHeader }}
          </span>
        </th>
      </thead>
      <CustomRoleListItem
        class="opacity-25 dark:opacity-20"
        :roles="dummyCustomRolesData"
        :loading="{}"
      />
    </div>
    <div
      class="absolute inset-0 flex flex-col items-center justify-center w-full h-full bg-gradient-to-t from-white dark:from-slate-900 to-transparent"
    >
      <BasePaywallModal
        feature-prefix="CUSTOM_ROLE"
        :i18n-key="i18nKey"
        :is-on-chatwoot-cloud="isOnChatwootCloud"
        :is-super-admin="isSuperAdmin"
        @upgrade="goToBillingSettings"
      />
    </div>
  </div>
</template>
