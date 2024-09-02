<script setup>
import { computed } from 'vue';
import { getCountryFlag } from 'dashboard/helper/flag';

const props = defineProps({
  countryCode: {
    type: String,
    required: true,
  },
  country: {
    type: String,
    required: true,
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
  <div class="overflow-hidden whitespace-nowrap text-ellipsis">
    <template v-if="country">{{ formattedCountryName }}</template>
    <span v-else class="text-slate-300 dark:text-slate-700"> --- </span>
  </div>
</template>
