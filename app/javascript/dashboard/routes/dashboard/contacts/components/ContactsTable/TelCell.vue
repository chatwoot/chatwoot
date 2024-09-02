<script setup>
import { computed } from 'vue';
import { parsePhoneNumber } from 'libphonenumber-js';

const props = defineProps({
  phoneNumber: {
    type: String,
    required: true,
  },
  defaultCountry: {
    type: String,
    default: '',
  },
});

const formattedNumber = computed(() => {
  if (!props.phoneNumber) {
    return '---';
  }

  try {
    const parsedNumber = parsePhoneNumber(
      props.phoneNumber,
      props.defaultCountry
    );

    if (parsedNumber) {
      return parsedNumber.formatInternational();
    }
    return props.phoneNumber;
  } catch (error) {
    return props.phoneNumber;
  }
});
</script>

<template>
  <span>{{ formattedNumber }}</span>
</template>
