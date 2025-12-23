<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { generateFileName } from 'dashboard/helper/downloadHelper';
import { useI18n } from 'vue-i18n';
import { formatTime } from '@chatwoot/utils';
import ReportFilterSelector from './FilterSelector.vue';

const props = defineProps({
  actionKey: {
    type: String,
    required: true,
  },
  fetchItemsKey: {
    type: String,
    required: true,
  },
  summaryKey: {
    type: String,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const from = ref(0);
const to = ref(0);
const businessHours = ref(false);
const expandedLabels = ref(new Set());

const labels = useMapGetter(['labels/getLabelsTree']);
const reportMetrics = useMapGetter([props.summaryKey]);

const getMetrics = id =>
  reportMetrics.value.find(metrics => metrics.id === Number(id)) || {};

const flattenedLabels = computed(() => {
  if (!labels.value) return [];

  const flatten = (items, level = 0) => {
    const result = [];
    items.forEach(item => {
      result.push({ ...item, level });
      if (
        item.children &&
        item.children.length > 0 &&
        expandedLabels.value.has(item.id)
      ) {
        result.push(...flatten(item.children, level + 1));
      }
    });
    return result;
  };
  return flatten(labels.value);
});

const handleExpand = id => {
  if (expandedLabels.value.has(id)) {
    expandedLabels.value.delete(id);
  } else {
    expandedLabels.value.add(id);
  }
};

const renderAvgTime = value => (value ? formatTime(value) : '--');
const renderCount = value => (value ? value.toLocaleString() : '--');

const onFilterChange = updatedFilter => {
  from.value = updatedFilter.from;
  to.value = updatedFilter.to;
  businessHours.value = updatedFilter.businessHours;

  if (from.value && to.value) {
    store.dispatch(props.actionKey, {
      from: from.value,
      to: to.value,
      businessHours: businessHours.value,
    });
  }
};

onMounted(() => {
  store.dispatch(props.fetchItemsKey);
});

// Expose download method for parent component
const downloadReports = () => {
  const fileName = generateFileName({
    type: 'label',
    to: to.value,
    businessHours: businessHours.value,
  });
  const params = {
    from: from.value,
    to: to.value,
    fileName,
    businessHours: businessHours.value,
  };
  store.dispatch('downloadLabelReports', params);
};

defineExpose({ downloadReports });
</script>

<template>
  <div>
    <ReportFilterSelector @filter-change="onFilterChange" />

    <div
      v-if="flattenedLabels.length > 0"
      class="flex-1 overflow-auto px-2 py-2 mt-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
    >
      <table class="w-full">
        <thead class="sticky top-0 z-10 bg-n-slate-1">
          <tr class="rounded-xl">
            <th
              class="text-left py-3 px-5 font-medium text-sm text-n-slate-12 ltr:rounded-bl-lg ltr:rounded-tl-lg rtl:rounded-br-lg rtl:rounded-tr-lg"
            >
              {{ t('SUMMARY_REPORTS.LABEL') }}
            </th>
            <th class="text-left py-3 px-5 font-medium text-sm text-n-slate-12">
              {{ t('SUMMARY_REPORTS.CONVERSATIONS') }}
            </th>
            <th class="text-left py-3 px-5 font-medium text-sm text-n-slate-12">
              {{ t('SUMMARY_REPORTS.AVG_FIRST_RESPONSE_TIME') }}
            </th>
            <th class="text-left py-3 px-5 font-medium text-sm text-n-slate-12">
              {{ t('SUMMARY_REPORTS.AVG_RESOLUTION_TIME') }}
            </th>
            <th class="text-left py-3 px-5 font-medium text-sm text-n-slate-12">
              {{ t('SUMMARY_REPORTS.AVG_REPLY_TIME') }}
            </th>
            <th
              class="text-left py-3 px-5 font-medium text-sm text-n-slate-12 ltr:rounded-br-lg ltr:rounded-tr-lg rtl:rounded-bl-lg rtl:rounded-tl-lg"
            >
              {{ t('SUMMARY_REPORTS.RESOLUTION_COUNT') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-slate-2">
          <tr
            v-for="label in flattenedLabels"
            :key="label.id"
            :class="{ 'cursor-pointer': label.children_count > 0 }"
            @click="label.children_count > 0 && handleExpand(label.id)"
          >
            <td class="py-4 px-5">
              <div
                class="flex items-center"
                :style="{ paddingLeft: `${label.level * 24}px` }"
              >
                <button
                  v-if="label.children_count > 0"
                  class="mr-2 p-0.5 hover:bg-n-slate-3 rounded transition-transform duration-200"
                  :class="{ 'rotate-90': expandedLabels.has(label.id) }"
                  @click.stop="handleExpand(label.id)"
                >
                  <svg
                    class="w-4 h-4 text-n-slate-11"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </button>
                <span v-else class="w-6 inline-block" />

                <div
                  class="inline-flex items-center"
                  :class="{ 'font-semibold': label.children_count > 0 }"
                >
                  <span
                    class="inline-block w-3 h-3 rounded-full mr-2"
                    :style="{ backgroundColor: label.color }"
                  />
                  <router-link
                    :to="`/app/accounts/${$route.params.accountId}/reports/label/${label.id}`"
                    class="text-blue-600 dark:text-blue-400 hover:underline"
                  >
                    {{ label.title }}
                  </router-link>
                </div>
              </div>
            </td>
            <td class="py-4 px-5 text-n-slate-12">
              {{ renderCount(getMetrics(label.id).conversationsCount) }}
            </td>
            <td class="py-4 px-5 text-n-slate-12">
              {{ renderAvgTime(getMetrics(label.id).avgFirstResponseTime) }}
            </td>
            <td class="py-4 px-5 text-n-slate-12">
              {{ renderAvgTime(getMetrics(label.id).avgResolutionTime) }}
            </td>
            <td class="py-4 px-5 text-n-slate-12">
              {{ renderAvgTime(getMetrics(label.id).avgReplyTime) }}
            </td>
            <td class="py-4 px-5 text-n-slate-12">
              {{ renderCount(getMetrics(label.id).resolvedConversationsCount) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else class="mt-5 text-center text-n-slate-11 p-8">
      {{ t('LABEL_REPORTS.NO_LABELS') }}
    </div>
  </div>
</template>
