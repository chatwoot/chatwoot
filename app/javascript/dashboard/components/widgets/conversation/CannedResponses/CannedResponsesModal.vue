<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CannedResponsesPicker from './CannedResponsesPicker.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['onSelect', 'cancel', 'update:show']);

const { t } = useI18n();

const localShow = computed({
  get: () => props.show,
  set: value => emit('update:show', value),
});

const onSelect = item => {
  emit('onSelect', item);
};

const onClose = () => {
  emit('cancel');
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="t('CANNED_MGMT.PICKER.TITLE')"
      :header-content="t('CANNED_MGMT.PICKER.SUBTITLE')"
    />
    <div class="px-8 py-6 row modal-content">
      <CannedResponsesPicker @on-select="onSelect" />
    </div>
  </woot-modal>
</template>
