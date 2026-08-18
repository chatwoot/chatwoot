<script setup>
import { useAlert } from 'dashboard/composables';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import AuditLogFilters from './components/AuditLogFilters.vue';
import {
  generateTranslationPayload,
  generateLogActionKey,
  parseAuditLogRouteQuery,
  buildAuditLogRouteQuery,
} from 'dashboard/helper/auditlogHelper';
import { computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';

const getters = useStoreGetters();
const store = useStore();
const router = useRouter();
const records = computed(() => getters['auditlogs/getAuditLogs'].value);
const uiFlags = computed(() => getters['auditlogs/getUIFlags'].value);
const meta = computed(() => getters['auditlogs/getMeta'].value);
const agentList = computed(() => getters['agents/getAgents'].value);

const { t } = useI18n();
const route = useRoute();

const currentFilters = computed(() => parseAuditLogRouteQuery(route.query));

const barFilters = computed(() => {
  const { q, types, since, until, sort } = currentFilters.value;
  return { q, type: types?.[0], since, until, sort };
});

const hasActiveFilters = computed(() => {
  const { q, type, since, until, sort } = barFilters.value;
  return Boolean(q || type || since || until || sort);
});

const fetchAuditLogs = async () => {
  try {
    await store.dispatch('auditlogs/fetch', currentFilters.value);
  } catch (error) {
    const errorMessage = error?.message || t('AUDIT_LOGS.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const updateQuery = partial => {
  // a debounced search can land after the admin has moved to another page
  if (route.name !== 'auditlogs_list') return;
  router.push({
    name: 'auditlogs_list',
    query: buildAuditLogRouteQuery({ ...route.query, ...partial }),
  });
};

const onFiltersUpdate = partial => {
  updateQuery({ ...partial, page: undefined });
};

const generateLogText = auditLogItem => {
  const payload = generateTranslationPayload(auditLogItem, agentList.value);
  const translationKey = generateLogActionKey(auditLogItem);

  const joinIfArray = value => {
    return Array.isArray(value) ? value.join(', ') : value;
  };

  const mergedPayload = {
    ...payload,
    attributes: joinIfArray(payload.attributes),
    values: joinIfArray(payload.values),
  };
  return t(translationKey, mergedPayload);
};

const onPageChange = page => {
  updateQuery({ page });
};

onMounted(() => {
  store.dispatch('agents/get');
  fetchAuditLogs();
});

watch(
  () => route.query,
  () => {
    if (route.name !== 'auditlogs_list') return;
    fetchAuditLogs();
  }
);

const tableHeaders = computed(() => {
  return [
    t('AUDIT_LOGS.LIST.TABLE_HEADER.ACTIVITY'),
    t('AUDIT_LOGS.LIST.TABLE_HEADER.TIME'),
    t('AUDIT_LOGS.LIST.TABLE_HEADER.IP_ADDRESS'),
  ];
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('AUDIT_LOGS.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="
      hasActiveFilters
        ? $t('AUDIT_LOGS.LIST.FILTERED_404')
        : $t('AUDIT_LOGS.LIST.404')
    "
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('AUDIT_LOGS.HEADER')"
        :description="$t('AUDIT_LOGS.DESCRIPTION')"
        :link-text="$t('AUDIT_LOGS.LEARN_MORE')"
        feature-name="audit_logs"
      />
    </template>
    <template #preBody>
      <AuditLogFilters :filters="barFilters" @update="onFiltersUpdate" />
    </template>
    <template #body>
      <div class="flex flex-col">
        <BaseTable :headers="tableHeaders" :items="records">
          <template #row="{ items }">
            <BaseTableRow
              v-for="auditLogItem in items"
              :key="auditLogItem.id"
              :item="auditLogItem"
            >
              <template #default>
                <BaseTableCell>
                  <span
                    class="text-body-main text-n-slate-12 whitespace-nowrap"
                  >
                    {{ generateLogText(auditLogItem) }}
                  </span>
                </BaseTableCell>

                <BaseTableCell>
                  <span
                    class="text-body-main text-n-slate-11 whitespace-nowrap"
                  >
                    {{
                      messageTimestamp(
                        auditLogItem.created_at,
                        'MMM dd, yyyy hh:mm a'
                      )
                    }}
                  </span>
                </BaseTableCell>

                <BaseTableCell class="w-36">
                  <span class="text-body-main text-n-slate-11">
                    {{ auditLogItem.remote_address }}
                  </span>
                </BaseTableCell>
              </template>
            </BaseTableRow>
          </template>
        </BaseTable>
        <PaginationFooter
          :current-page="Number(meta.currentPage)"
          :total-items="meta.totalEntries"
          :items-per-page="meta.perPage"
          class="!px-0"
          @update:current-page="onPageChange"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
