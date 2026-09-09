<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { CSAT_RATINGS } from 'shared/constants/messages';

const props = defineProps({
  selectedRaiting: { type: Object, default: null },
});
const emit = defineEmits(['ratingFilterSelection']);
const { t } = useI18n();

const options = computed(() =>
  [...CSAT_RATINGS].reverse().map(o => ({
    ...o,
    label: t(o.translationKey),
  }))
);

const selectedValue = ref(props.selectedRaiting?.value ?? '');

const handleChange = e => {
  const found = options.value.find(o => String(o.value) === e.target.value);
  emit('ratingFilterSelection', found ?? null);
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <select :value="selectedValue" class="no-margin" @change="handleChange">
      <option value="" disabled>
        {{ $t('FORMS.MULTISELECT.SELECT_ONE') }}
      </option>
      <option v-for="o in options" :key="o.value" :value="o.value">
        {{ o.label }}
      </option>
    </select>
  </div>
</template>
