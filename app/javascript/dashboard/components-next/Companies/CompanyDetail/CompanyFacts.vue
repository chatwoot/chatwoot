<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { dateFormat } from 'shared/helpers/timeHelper';

import { getCompanyProfile } from 'dashboard/components-next/Companies/helpers/companyHelper';

import ProfileFacts from 'dashboard/components-next/ProfileFacts/ProfileFacts.vue';

const props = defineProps({
  company: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const companyAttributes = useMapGetter('attributes/getCompanyAttributes');

onMounted(() => store.dispatch('attributes/get'));

const facts = computed(() => {
  const { industry, employees, location, fullLocation, countryCode } =
    getCompanyProfile(props.company.additionalAttributes);

  return [
    {
      key: 'industry',
      icon: 'i-lucide-building-2',
      label: t('COMPANIES.DETAIL.FACTS.INDUSTRY'),
      value: industry,
    },
    {
      key: 'size',
      icon: 'i-lucide-users',
      label: t('COMPANIES.DETAIL.FACTS.SIZE'),
      value: employees,
    },
    {
      key: 'location',
      icon: 'i-lucide-map-pin',
      label: t('COMPANIES.DETAIL.FACTS.LOCATION'),
      value: location,
      title: fullLocation,
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
