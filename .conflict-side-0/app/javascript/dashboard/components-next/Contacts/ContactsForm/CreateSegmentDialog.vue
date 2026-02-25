<script setup>
import { ref, reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['create']);

const FILTER_TYPE_CONTACT = 1;

const { t } = useI18n();

const uiFlags = useMapGetter('customViews/getUIFlags');
const isCreating = computed(() => uiFlags.value.isCreating);

const dialogRef = ref(null);

const state = reactive({
  name: '',
});

const validationRules = {
  name: { required },
};

const v$ = useVuelidate(validationRules, state);

const handleDialogConfirm = async () => {
  const isNameValid = await v$.value.$validate();
  if (!isNameValid) return;
  emit('create', {
    name: state.name,
    filter_type: FILTER_TYPE_CONTACT,
  });
  state.name = '';
  v$.value.$reset();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.TITLE')"
    :confirm-button-label="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.CONFIRM')
    "
    :is-loading="isCreating"
    :disable-confirm-button="isCreating"
    @confirm="handleDialogConfirm"
  >
    <Input
      v-model="state.name"
      :label="t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.LABEL')"
      :placeholder="
        t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.PLACEHOLDER')
      "
      :message="
        v$.name.$error
          ? t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.ERROR')
          : ''
      "
      :message-type="v$.name.$error ? 'error' : 'info'"
    />
  </Dialog>
</template>
