<script setup>
import { useAlert } from 'dashboard/composables';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import {
  generateTranslationPayload,
  generateLogActionKey,
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

const routerPage = computed(() => Number(route.query.page ?? 1));

const fetchAuditLogs = page => {
  try {
    store.dispatch('auditlogs/fetch', { page });
  } catch (error) {
    const errorMessage = error?.message || t('AUDIT_LOGS.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
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
  router.push({ name: 'auditlogs_list', query: { page: page } });
};

onMounted(() => {
  store.dispatch('agents/get');
  fetchAuditLogs(routerPage.value);
});

watch(routerPage, (newPage, oldPage) => {
  if (newPage !== oldPage) {
    fetchAuditLogs(newPage);
  }
});

const tableHeaders = computed(() => {
  return [
    t('AUDIT_LOGS.LIST.TABLE_HEADER.ACTIVITY'),
    t('AUDIT_LOGS.LIST.TABLE_HEADER.TIME'),
    t('AUDIT_LOGS.LIST.TABLE_HEADER.IP_ADDRESS'),
  ];
});
</script>

<template>
  <div class="flex-1 overflow-auto">
    <BaseSettingsHeader
      :title="$t('AUDIT_LOGS.HEADER')"
      :description="$t('AUDIT_LOGS.DESCRIPTION')"
      :link-text="$t('AUDIT_LOGS.LEARN_MORE')"
      feature-name="audit_logs"
    />

    <div class="mt-6 flex-1 text-slate-700 dark:text-slate-300">
      <woot-loading-state
        v-if="uiFlags.fetchingList"
        :message="$t('AUDIT_LOGS.LOADING')"
      />
      <p
        v-else-if="!records.length"
        class="flex flex-col items-center justify-center h-full text-base p-8"
      >
        {{ $t('AUDIT_LOGS.LIST.404') }}
      </p>
      <div v-else class="min-w-full overflow-x-auto">
        <table class="divide-y divide-slate-75 dark:divide-slate-700">
          <thead>
            <th
              v-for="thHeader in tableHeaders"
              :key="thHeader"
              class="py-4 pr-4 text-left font-semibold text-slate-700 dark:text-slate-300"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody
            class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300"
          >
            <tr v-for="auditLogItem in records" :key="auditLogItem.id">
              <td class="py-4 pr-4 break-all whitespace-nowrap">
                {{ generateLogText(auditLogItem) }}
              </td>
              <td class="py-4 pr-4 break-all whitespace-nowrap">
                {{
                  messageTimestamp(
                    auditLogItem.created_at,
                    'MMM dd, yyyy hh:mm a'
                  )
                }}
              </td>
              <td class="py-4 w-[8.75rem]">
                {{ auditLogItem.remote_address }}
              </td>
            </tr>
          </tbody>
        </table>
        <TableFooter
          :current-page="Number(meta.currentPage)"
          :total-count="meta.totalEntries"
          :page-size="meta.perPage"
          class="border-slate-50 dark:border-slate-800 border-t !px-0 py-4"
          @page-change="onPageChange"
        />
      </div>
    </div>
  </div>
</template>
