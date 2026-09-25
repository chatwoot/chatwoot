<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { dateFormat } from 'shared/helpers/timeHelper';

import Flag from 'dashboard/components-next/flag/Flag.vue';

const props = defineProps({
  company: { type: Object, required: true },
});

// Pad to a full row so the gap-based hairlines never leave an empty grey cell.
// A multiple of 4 also fills the 2-column mobile layout.
const COLUMNS = 4;

const { t } = useI18n();
const store = useStore();
const companyAttributes = useMapGetter('attributes/getCompanyAttributes');

onMounted(() => store.dispatch('attributes/get'));

const formatCustomValue = (attribute, value) => {
  if (attribute.attributeDisplayType === 'checkbox') {
    return value
      ? t('COMPANIES.DETAIL.FACTS.YES')
      : t('COMPANIES.DETAIL.FACTS.NO');
  }
  if (attribute.attributeDisplayType === 'date')
    return dateFormat(new Date(value).getTime() / 1000);
  return String(value);
};

const customFacts = computed(() => {
  const values = props.company.customAttributes || {};
  return (companyAttributes.value || [])
    .filter(
      ({ attributeKey }) =>
        ![undefined, null, ''].includes(values[attributeKey])
    )
    .map(attribute => ({
      key: `custom-${attribute.attributeKey}`,
      icon: 'i-lucide-tag',
      label: attribute.attributeDisplayName,
      value: formatCustomValue(attribute, values[attribute.attributeKey]),
    }));
});

const facts = computed(() => {
  const {
    industry,
    sub_industry: subIndustry,
    employee_count_range: employeeCountRange,
    employee_count: employeeCount,
    city,
    country,
    country_code: countryCode,
  } = props.company.additionalAttributes || {};

  return [
    {
      key: 'industry',
      icon: 'i-lucide-building-2',
      label: t('COMPANIES.DETAIL.FACTS.INDUSTRY'),
      value: subIndustry || industry,
    },
    {
      key: 'size',
      icon: 'i-lucide-users',
      label: t('COMPANIES.DETAIL.FACTS.SIZE'),
      value: employeeCount
        ? employeeCount.toLocaleString()
        : employeeCountRange,
    },
    {
      key: 'location',
      icon: 'i-lucide-map-pin',
      label: t('COMPANIES.DETAIL.FACTS.LOCATION'),
      value: [city, city ? countryCode || country : country]
        .filter(Boolean)
        .join(', '),
      title: [city, country].filter(Boolean).join(', '),
      countryCode,
    },
    {
      key: 'added',
      icon: 'i-lucide-calendar',
      label: t('COMPANIES.DETAIL.FACTS.ADDED'),
      value: props.company.createdAt && dateFormat(props.company.createdAt),
    },
    ...customFacts.value,
  ];
});

const emptyCells = computed(
  () => (COLUMNS - (facts.value.length % COLUMNS)) % COLUMNS
);
</script>

<template>
  <section class="flex flex-col gap-3">
    <div class="overflow-hidden border rounded-xl border-n-weak bg-n-weak">
      <dl class="grid grid-cols-2 gap-px m-0 md:grid-cols-4">
        <div
          v-for="fact in facts"
          :key="fact.key"
          class="flex flex-col min-w-0 gap-1 px-4 py-3 bg-n-solid-2"
        >
          <dt
            class="flex items-center gap-1.5 text-label-small text-n-slate-10"
          >
            <span :class="fact.icon" class="size-3.5 shrink-0" />
            {{ fact.label }}
          </dt>
          <dd
            class="flex items-start gap-1.5 text-heading-3"
            :class="fact.value ? 'text-n-slate-12' : 'text-n-slate-9'"
          >
            <Flag
              v-if="fact.value && fact.countryCode"
              :country="fact.countryCode"
              class="mt-0.5 shrink-0"
            />
            <span class="line-clamp-2" :title="fact.title">
              {{ fact.value || t('COMPANIES.DETAIL.FACTS.UNKNOWN') }}
            </span>
          </dd>
        </div>
        <div v-for="n in emptyCells" :key="`empty-${n}`" class="bg-n-solid-2" />
      </dl>
    </div>
  </section>
</template>
