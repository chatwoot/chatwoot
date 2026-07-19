<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import CampaignsAPI from 'dashboard/api/campaigns';
import { downloadFile } from 'dashboard/helper/downloadHelper';
import BarChart from 'shared/components/charts/BarChart.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  campaign: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const STATUS_KEYS = [
  'pending',
  'sent',
  'delivered',
  'read',
  'failed',
  'skipped',
];

const isLoading = ref(false);
const isLoadingMore = ref(false);
const isExporting = ref(false);
const stats = ref({});
const recipients = ref([]);
const meta = ref({ count: 0, current_page: 1, total_pages: 1 });
const statusFilter = ref('');
const searchQuery = ref('');
const currentPage = ref(1);
const exportMenuOpen = ref(false);

const chartCollection = computed(() => ({
  labels: STATUS_KEYS.map(key =>
    t(`CAMPAIGN.WHATSAPP.REPORT.STATUS.${key.toUpperCase()}`)
  ),
  datasets: [
    {
      type: 'bar',
      data: STATUS_KEYS.map(key => Number(stats.value?.[key] || 0)),
      backgroundColor: [
        'rgb(148, 163, 184)',
        'rgb(31, 147, 255)',
        'rgb(34, 197, 94)',
        'rgb(168, 85, 247)',
        'rgb(239, 68, 68)',
        'rgb(100, 116, 139)',
      ],
    },
  ],
}));

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  datasets: {
    bar: {
      categoryPercentage: 0.5,
      barPercentage: 0.45,
      maxBarThickness: 22,
    },
  },
  scales: {
    y: { beginAtZero: true, ticks: { precision: 0 } },
  },
};

const hasMorePages = computed(
  () => currentPage.value < (meta.value.total_pages || 1)
);

const formatDate = value => {
  if (!value) return '—';
  return new Date(value).toLocaleString();
};

const loadStats = async () => {
  if (!props.campaign?.id) return;
  const response = await CampaignsAPI.getStats(props.campaign.id);
  stats.value = response.data.stats || props.campaign.execution_stats || {};
};

const loadRecipients = async ({ append = false } = {}) => {
  if (!props.campaign?.id) return;
  const response = await CampaignsAPI.getRecipients(props.campaign.id, {
    status: statusFilter.value || undefined,
    q: searchQuery.value || undefined,
    page: currentPage.value,
  });
  const payload = response.data.payload || [];
  recipients.value = append ? [...recipients.value, ...payload] : payload;
  meta.value = response.data.meta || meta.value;
};

const refresh = async () => {
  isLoading.value = true;
  currentPage.value = 1;
  try {
    await Promise.all([loadStats(), loadRecipients()]);
  } finally {
    isLoading.value = false;
  }
};

const loadMore = async () => {
  if (!hasMorePages.value || isLoadingMore.value) return;
  isLoadingMore.value = true;
  currentPage.value += 1;
  try {
    await loadRecipients({ append: true });
  } finally {
    isLoadingMore.value = false;
  }
};

const setStatusFilter = async status => {
  statusFilter.value = statusFilter.value === status ? '' : status;
  currentPage.value = 1;
  isLoading.value = true;
  try {
    await loadRecipients();
  } finally {
    isLoading.value = false;
  }
};

let searchTimer;
const onSearchInput = () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(async () => {
    currentPage.value = 1;
    isLoading.value = true;
    try {
      await loadRecipients();
    } finally {
      isLoading.value = false;
    }
  }, 300);
};

const exportRecipients = async exportFormat => {
  if (!props.campaign?.id || isExporting.value) return;
  exportMenuOpen.value = false;
  isExporting.value = true;
  try {
    const response = await CampaignsAPI.exportRecipients(props.campaign.id, {
      status: statusFilter.value || undefined,
      q: searchQuery.value || undefined,
      exportFormat,
    });
    const extension = exportFormat === 'xlsx' ? 'xlsx' : 'csv';
    downloadFile(
      `campaign_${props.campaign.id}_recipients.${extension}`,
      response.data
    );
  } finally {
    isExporting.value = false;
  }
};

watch(
  () => props.campaign?.id,
  id => {
    if (id) refresh();
  },
  { immediate: true }
);
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-n-alpha-black2"
    @click.self="emit('close')"
  >
    <div
      class="flex flex-col w-[min(90vw,72rem)] max-h-[90vh] bg-n-solid-2 border border-n-weak rounded-xl shadow-lg overflow-hidden"
    >
      <div class="flex items-start justify-between gap-3 p-5 border-b border-n-weak shrink-0">
        <div class="min-w-0">
          <h3 class="text-base font-medium text-n-slate-12 truncate">
            {{ campaign?.title }}
          </h3>
          <p class="text-sm text-n-slate-11 mt-1">
            {{ t('CAMPAIGN.WHATSAPP.REPORT.SUBTITLE') }}
          </p>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <div class="relative">
            <Button
              variant="faded"
              color="slate"
              size="sm"
              icon="i-lucide-download"
              :is-loading="isExporting"
              @click="exportMenuOpen = !exportMenuOpen"
            />
            <div
              v-if="exportMenuOpen"
              v-on-clickaway="() => (exportMenuOpen = false)"
              class="absolute top-full mt-1 ltr:right-0 rtl:left-0 z-50 flex flex-col min-w-[8rem] rounded-lg border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-md overflow-hidden"
            >
              <button
                type="button"
                class="px-3 py-2 text-sm text-start text-n-slate-12 hover:bg-n-alpha-2"
                @click="exportRecipients('csv')"
              >
                CSV
              </button>
              <button
                type="button"
                class="px-3 py-2 text-sm text-start text-n-slate-12 hover:bg-n-alpha-2"
                @click="exportRecipients('xlsx')"
              >
                Excel
              </button>
            </div>
          </div>
          <Button
            variant="faded"
            color="slate"
            size="sm"
            icon="i-lucide-x"
            @click="emit('close')"
          />
        </div>
      </div>

      <div class="flex flex-col gap-4 p-5 min-h-0 flex-1 overflow-hidden">
        <div class="flex flex-wrap gap-2 shrink-0">
          <button
            v-for="key in STATUS_KEYS"
            :key="key"
            type="button"
            class="text-xs font-medium inline-flex items-center gap-1 h-7 px-2.5 rounded-md bg-n-alpha-2 text-n-slate-12"
            :class="{
              'ring-1 ring-n-brand': statusFilter === key,
            }"
            @click="setStatusFilter(key)"
          >
            <span>{{
              t(`CAMPAIGN.WHATSAPP.REPORT.STATUS.${key.toUpperCase()}`)
            }}</span>
            <span class="text-n-slate-11">{{ stats[key] || 0 }}</span>
          </button>
          <span
            class="text-xs font-medium inline-flex items-center h-7 px-2.5 rounded-md bg-n-alpha-2 text-n-slate-11"
          >
            {{ t('CAMPAIGN.WHATSAPP.REPORT.AUDIENCE_TOTAL') }}:
            {{ stats.audience_total || 0 }}
          </span>
        </div>

        <div class="max-w-md mx-auto h-36 w-full shrink-0">
          <BarChart
            :collection="chartCollection"
            :chart-options="chartOptions"
          />
        </div>

        <Input
          v-model="searchQuery"
          size="sm"
          class="max-w-sm shrink-0"
          :placeholder="t('CAMPAIGN.WHATSAPP.REPORT.SEARCH_PLACEHOLDER')"
          @update:model-value="onSearchInput"
        />

        <div
          v-if="isLoading"
          class="flex items-center justify-center py-8 text-n-slate-11"
        >
          <Spinner />
        </div>

        <div v-else class="flex flex-col min-h-0 flex-1 overflow-hidden">
          <div class="overflow-auto flex-1 min-h-0 rounded-lg border border-n-weak">
            <table class="w-full text-sm border-collapse">
              <thead class="sticky top-0 z-[1] bg-n-solid-2">
                <tr class="text-xs font-medium text-n-slate-11 text-start">
                  <th class="px-3 py-2 border-b border-n-weak">
                    {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.CONTACT') }}
                  </th>
                  <th class="px-3 py-2 border-b border-n-weak">
                    {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.PHONE') }}
                  </th>
                  <th class="px-3 py-2 border-b border-n-weak">
                    {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.STATUS') }}
                  </th>
                  <th class="px-3 py-2 border-b border-n-weak">
                    {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.DETAILS') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="row in recipients"
                  :key="row.id"
                  class="text-n-slate-12 border-b border-n-weak last:border-0"
                >
                  <td class="px-3 py-2 max-w-[14rem] truncate">
                    {{ row.contact?.name || '—' }}
                  </td>
                  <td class="px-3 py-2 whitespace-nowrap">
                    {{ row.phone_number || '—' }}
                  </td>
                  <td class="px-3 py-2 capitalize whitespace-nowrap">
                    {{
                      t(
                        `CAMPAIGN.WHATSAPP.REPORT.STATUS.${row.status.toUpperCase()}`
                      )
                    }}
                  </td>
                  <td class="px-3 py-2 text-xs text-n-slate-11">
                    <template v-if="row.error_message">{{
                      row.error_message
                    }}</template>
                    <template v-else-if="row.read_at">
                      {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.READ_AT') }}:
                      {{ formatDate(row.read_at) }}
                    </template>
                    <template v-else-if="row.delivered_at">
                      {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.DELIVERED_AT') }}:
                      {{ formatDate(row.delivered_at) }}
                    </template>
                    <template v-else-if="row.sent_at">
                      {{ t('CAMPAIGN.WHATSAPP.REPORT.TABLE.SENT_AT') }}:
                      {{ formatDate(row.sent_at) }}
                    </template>
                    <template v-else>—</template>
                  </td>
                </tr>
              </tbody>
            </table>
            <p
              v-if="!recipients.length"
              class="text-sm text-n-slate-11 text-center py-6"
            >
              {{ t('CAMPAIGN.WHATSAPP.REPORT.EMPTY') }}
            </p>
          </div>
          <Button
            v-if="hasMorePages"
            variant="faded"
            color="slate"
            size="sm"
            class="self-center mt-3 shrink-0"
            :is-loading="isLoadingMore"
            @click="loadMore"
          >
            {{ t('CAMPAIGN.WHATSAPP.REPORT.LOAD_MORE') }}
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>
