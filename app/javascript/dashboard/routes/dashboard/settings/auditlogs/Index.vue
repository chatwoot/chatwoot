<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useDebounceFn } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { messageTimestamp } from 'shared/helpers/timeHelper';
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
  auditLogFiltersFromQuery,
  buildAuditLogRouteQuery,
} from 'dashboard/helper/auditlogHelper';

const SEARCH_DEBOUNCE_DELAY = 500;

const getters = useStoreGetters();
const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const records = computed(() => getters['auditlogs/getAuditLogs'].value);
const uiFlags = computed(() => getters['auditlogs/getUIFlags'].value);
const meta = computed(() => getters['auditlogs/getMeta'].value);
const agentList = computed(() => getters['agents/getAgents'].value);

const searchQuery = ref(route.query.q ?? '');
// The search term this page last put in the URL. Echoes of our own navigation
// must not overwrite a term the admin is still typing.
const pushedSearch = ref(searchQuery.value);

const hasActiveFilters = computed(() => {
  const { q, type, since, sort } = route.query;
  return Boolean(q || type || since || sort);
});

const fetchAuditLogs = async () => {
  try {
    const filters = auditLogFiltersFromQuery(route.query);
    await store.dispatch('auditlogs/fetch', filters);
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

const onPageChange = page => {
  updateQuery({ page });
};

const clearFilters = () => {
  pushedSearch.value = '';
  searchQuery.value = '';
  router.push({ name: 'auditlogs_list', query: {} });
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

const tableHeaders = computed(() => {
  return [
    t('AUDIT_LOGS.LIST.TABLE_HEADER.ACTIVITY'),
    t('AUDIT_LOGS.LIST.TABLE_HEADER.TIME'),
    t('AUDIT_LOGS.LIST.TABLE_HEADER.IP_ADDRESS'),
  ];
});

const commitSearch = useDebounceFn(term => {
  pushedSearch.value = term;
  onFiltersUpdate({ q: term || undefined });
}, SEARCH_DEBOUNCE_DELAY);

watch(searchQuery, value => {
  const term = value.trim();
  if (term !== pushedSearch.value) commitSearch(term);
});

watch(
  () => route.query.q,
  value => {
    const next = value ?? '';
    if (next === pushedSearch.value) return;
    pushedSearch.value = next;
    searchQuery.value = next;
  }
);

watch(
  () => route.query,
  () => {
    if (route.name === 'auditlogs_list') fetchAuditLogs();
  }
);

onMounted(() => {
  store.dispatch('agents/get');
  fetchAuditLogs();
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('AUDIT_LOGS.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="
      hasActiveFilters ? $t('AUDIT_LOGS.SEARCH_404') : $t('AUDIT_LOGS.LIST.404')
    "
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('AUDIT_LOGS.HEADER')"
        :description="$t('AUDIT_LOGS.DESCRIPTION')"
        :link-text="$t('AUDIT_LOGS.LEARN_MORE')"
        :search-placeholder="$t('AUDIT_LOGS.FILTERS.SEARCH_PLACEHOLDER')"
        feature-name="audit_logs"
      >
        <template #tabs>
          <AuditLogFilters
            :type="route.query.type"
            :range="route.query.range"
            :since="route.query.since"
            :until="route.query.until"
            :sort="route.query.sort"
            :has-active-filters="hasActiveFilters"
            @update="onFiltersUpdate"
            @clear="clearFilters"
          />
        </template>
        <template v-if="meta.totalEntries" #count>
          <span class="text-body-main text-n-slate-11 whitespace-nowrap">
            {{ $t('AUDIT_LOGS.COUNT', { n: meta.totalEntries }) }}
          </span>
        </template>
      </BaseSettingsHeader>
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
