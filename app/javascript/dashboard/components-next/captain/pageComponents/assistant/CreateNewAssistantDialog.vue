<script setup>
import { ref, reactive } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const emit = defineEmits(['confirm', 'cancel']);
const { t } = useI18n();

const dialogRef = ref(null);

const state = reactive({
  name: '',
  url: '',
});

const handleConfirm = () => {
  emit('confirm', state);
};

const handleCancel = () => {
  emit('cancel');
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :confirm-button-label="
      t('CAPTAIN.ASSISTANTS.ONBOARDING.CREATE.CREATE_BUTTON')
    "
    @close="handleCancel"
    @confirm="handleConfirm"
  >
    <fieldset class="flex flex-col gap-10 py-8">
      <InlineInput
        v-model="state.name"
        :label="t('CAPTAIN.ASSISTANTS.ONBOARDING.CREATE.NAME')"
        :placeholder="
          t('CAPTAIN.ASSISTANTS.ONBOARDING.CREATE.NAME_PLACEHOLDER')
        "
        class="flex flex-col !items-start !gap-2 [&>input]:text-base [&>label]:text-xl"
      />

      <InlineInput
        v-model="state.url"
        :label="t('CAPTAIN.ASSISTANTS.ONBOARDING.CREATE.URL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.ONBOARDING.CREATE.URL_PLACEHOLDER')"
        class="flex flex-col !items-start !gap-2 [&>input]:text-base [&>label]:text-xl"
      />
    </fieldset>
    <template #footer />
  </Dialog>
</template>
