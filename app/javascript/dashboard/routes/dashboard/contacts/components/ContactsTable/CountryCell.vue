<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import { computed } from 'vue';
import { getCountryFlag } from 'dashboard/helper/flag';

const props = defineProps({
  countryCode: {
    type: String,
    default: '',
  },
  country: {
    type: String,
    default: '',
  },
});

const countryFlag = computed(() => {
  if (!props.countryCode) {
    return '';
  }

  return getCountryFlag(props.countryCode);
});

const formattedCountryName = computed(() => {
  if (!props.country) {
    return '';
  }

  return `${countryFlag.value} ${props.country}`;
});
</script>

<template>
  <BaseCell :content="formattedCountryName" />
</template>
