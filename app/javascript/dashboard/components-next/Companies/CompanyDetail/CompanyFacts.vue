<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { dateFormat } from 'shared/helpers/timeHelper';

import ProfileFacts from 'dashboard/components-next/ProfileFacts/ProfileFacts.vue';

const props = defineProps({
  company: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const companyAttributes = useMapGetter('attributes/getCompanyAttributes');

onMounted(() => store.dispatch('attributes/get'));

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
  ];
});
</script>

<template>
  <ProfileFacts
    :facts="facts"
    :attributes="companyAttributes || []"
    :custom-attributes="company.customAttributes || {}"
  />
</template>
