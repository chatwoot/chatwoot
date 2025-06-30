<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { DATE_RANGE_OPTIONS } from '../../constants';

const emit = defineEmits(['onRangeChange']);

const { t } = useI18n();

const options = computed(() =>
  Object.values(DATE_RANGE_OPTIONS).map(option => ({
    ...option,
    name: t(option.translationKey),
  }))
);

const selectedKey = ref(Object.values(DATE_RANGE_OPTIONS)[0].key);

const selectedOption = computed({
  get() {
    return options.value.find(o => o.key === selectedKey.value);
  },
  set(val) {
    selectedKey.value = val.key;
  },
});

const updateRange = range => {
  selectedOption.value = range;
  emit('onRangeChange', range);
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      track-by="name"
      label="name"
      :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      deselect-label=""
      :options="options"
      :searchable="false"
      :allow-empty="false"
      @select="updateRange"
    />
  </div>
</template>
