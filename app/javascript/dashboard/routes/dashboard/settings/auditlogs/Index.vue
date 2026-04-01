<script setup>
import { useAlert } from 'dashboard/composables';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import SettingsLayout from '../SettingsLayout.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
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

const helpURL = computed(() => getHelpUrlForFeature('audit_logs'));

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
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="t('AUDIT_LOGS.LIST.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="t('AUDIT_LOGS.LIST.404')"
  >
    <template #header>
      <div class="flex flex-col gap-6 pb-2">
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('AUDIT_LOGS.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('AUDIT_LOGS.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ t('AUDIT_LOGS.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('AUDIT_LOGS.LEARN_MORE') }}
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
        <div class="min-w-[44rem] bg-surface-container-low">
          <table class="min-w-full divide-y divide-surface-container-high/30">
            <thead>
              <tr
                class="border-b border-surface-container-high/50 bg-surface-container-high/30"
              >
                <th
                  v-for="thHeader in tableHeaders"
                  :key="thHeader"
                  class="px-6 py-4 text-start text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
                >
                  {{ thHeader }}
                </th>
              </tr>
            </thead>
            <tbody
              class="divide-y divide-surface-container-high/30 [&>tr]:transition-colors [&>tr]:duration-150 [&>tr]:hover:bg-surface-container-high/20"
            >
              <tr v-for="auditLogItem in records" :key="auditLogItem.id">
                <td
                  class="max-w-2xl px-6 py-4 text-sm leading-relaxed text-on-surface break-words"
                >
                  {{ generateLogText(auditLogItem) }}
                </td>
                <td
                  class="whitespace-nowrap px-6 py-4 text-sm text-on-surface-variant"
                >
                  {{
                    messageTimestamp(
                      auditLogItem.created_at,
                      'MMM dd, yyyy hh:mm a'
                    )
                  }}
                </td>
                <td
                  class="w-[8.75rem] whitespace-nowrap px-6 py-4 text-sm text-on-surface-variant"
                >
                  {{ auditLogItem.remote_address }}
                </td>
              </tr>
            </tbody>
          </table>
          <TableFooter
            :current-page="Number(meta.currentPage)"
            :total-count="meta.totalEntries"
            :page-size="meta.perPage"
            class="border-t border-surface-container-high/30 bg-surface-container-high/10 py-1"
            @page-change="onPageChange"
          />
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
