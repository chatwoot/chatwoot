<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Label from 'dashboard/components-next/label/Label.vue';
import { TICKET_STATUS_CATEGORY_COLORS } from './constants';

const props = defineProps({
  statusCategory: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const color = computed(
  () => TICKET_STATUS_CATEGORY_COLORS[props.statusCategory] || 'slate'
);

const label = computed(() =>
  t(`TICKETS.STATUS_CATEGORY.${props.statusCategory.toUpperCase()}`)
);
</script>

<template>
  <Label v-if="statusCategory" :label="label" :color="color" compact />
</template>
