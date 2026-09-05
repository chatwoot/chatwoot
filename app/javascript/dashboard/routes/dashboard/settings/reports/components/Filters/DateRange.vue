<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { DATE_RANGE_OPTIONS } from '../../constants';

const props = defineProps({
  selectedRange: {
    type: Object,
    default: () => Object.values(DATE_RANGE_OPTIONS)[0],
  },
});
const emit = defineEmits(['onRangeChange']);
const { t } = useI18n();

const options = computed(() =>
  Object.values(DATE_RANGE_OPTIONS).map(o => ({
    ...o,
    name: t(o.translationKey),
  }))
);

const selectedId = ref(
  props.selectedRange?.id ?? Object.values(DATE_RANGE_OPTIONS)[0].id
);

const handleChange = e => {
  const found = options.value.find(o => o.id === e.target.value);
  if (found) emit('onRangeChange', found);
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <select :value="selectedId" class="no-margin" @change="handleChange">
      <option v-for="o in options" :key="o.id" :value="o.id">
        {{ o.name }}
      </option>
    </select>
  </div>
</template>
