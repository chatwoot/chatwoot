<script setup>
import { ref, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CustomToolForm from './CustomToolForm.vue';

const props = defineProps({
  selectedTool: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});

const emit = defineEmits(['close', 'created']);
const { t } = useI18n();
const store = useStore();
const route = useRoute();

const dialogRef = ref(null);
const uiFlags = useMapGetter('captainCustomTools/getUIFlags');

const isSaving = computed(() =>
  props.type === 'edit'
    ? uiFlags.value.updatingItem
    : uiFlags.value.creatingItem
);

const updateTool = toolDetails =>
  store.dispatch('captainCustomTools/update', {
    id: props.selectedTool.id,
    ...toolDetails,
    assistantId: route.params.assistantId,
  });

const i18nKey = computed(
  () => `CAPTAIN.CUSTOM_TOOLS.${props.type.toUpperCase()}`
);

const createTool = toolDetails =>
  store.dispatch('captainCustomTools/create', {
    ...toolDetails,
    assistantId: route.params.assistantId,
  });

const handleSubmit = async updatedTool => {
  try {
    if (props.type === 'edit') {
      await updateTool(updatedTool);
    } else {
      await createTool(updatedTool);
      emit('created');
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      parseAPIErrorResponse(error) || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <SidePanel
    ref="dialogRef"
    width="2xl"
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.CUSTOM_TOOLS.FORM_DESCRIPTION')"
    @after-leave="handleClose"
  >
    <CustomToolForm :mode="type" :tool="selectedTool" @submit="handleSubmit" />
    <template #footer>
      <div class="flex gap-3 justify-end">
        <Button
          type="button"
          faded
          slate
          :label="$t('CAPTAIN.FORM.CANCEL')"
          @click="handleCancel"
        />
        <Button
          type="submit"
          form="custom-tool-form"
          :label="
            $t(type === 'edit' ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE')
          "
          :is-loading="isSaving"
          :disabled="isSaving"
        />
      </div>
    </template>
  </SidePanel>
</template>
