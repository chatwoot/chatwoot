<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { dateFormat, dynamicTime } from 'shared/helpers/timeHelper';

import ProfileFacts from 'dashboard/components-next/ProfileFacts/ProfileFacts.vue';

const props = defineProps({
  contact: { type: Object, required: true },
});

const { t } = useI18n();
const contactAttributes = useMapGetter('attributes/getContactAttributes');

const facts = computed(() => {
  const { companyName, city, country, countryCode } =
    props.contact.additionalAttributes || {};

  return [
    {
      key: 'company',
      icon: 'i-lucide-building-2',
      label: t('CONTACTS_LAYOUT.DETAIL.FACTS.COMPANY'),
      value: companyName,
    },
    {
      key: 'location',
      icon: 'i-lucide-map-pin',
      label: t('CONTACTS_LAYOUT.DETAIL.FACTS.LOCATION'),
      value: [city, city ? countryCode || country : country]
        .filter(Boolean)
        .join(', '),
      title: [city, country].filter(Boolean).join(', '),
      countryCode,
    },
    {
      key: 'last-activity',
      icon: 'i-lucide-activity',
      label: t('CONTACTS_LAYOUT.DETAIL.FACTS.LAST_ACTIVITY'),
      value:
        props.contact.lastActivityAt &&
        dynamicTime(props.contact.lastActivityAt),
    },
    {
      key: 'added',
      icon: 'i-lucide-calendar',
      label: t('CONTACTS_LAYOUT.DETAIL.FACTS.ADDED'),
      value: props.contact.createdAt && dateFormat(props.contact.createdAt),
    },
  ];
});
</script>

<template>
  <ProfileFacts
    :facts="facts"
    :attributes="contactAttributes || []"
    :custom-attributes="contact.customAttributes || {}"
  />
</template>
