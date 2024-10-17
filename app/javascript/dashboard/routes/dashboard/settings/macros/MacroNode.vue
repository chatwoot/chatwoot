<script setup>
import { computed, inject, defineModel } from 'vue';
import { useMacros } from 'dashboard/composables/useMacros';
import { useI18n } from 'vue-i18n';
import ActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';

const props = defineProps({
  singleNode: {
    type: Boolean,
    default: false,
  },
  errorKey: {
    type: String,
    default: '',
  },
  fileName: {
    type: String,
    default: '',
  },
});

defineEmits(['resetAction', 'deleteNode']);

const { t } = useI18n();
const macroActionTypes = inject('macroActionTypes');
const { getMacroDropdownValues } = useMacros();

const actionData = defineModel({
  type: Object,
  required: true,
});

const errorMessage = computed(() => {
  if (!props.errorKey) return '';
  return t(`MACROS.ERRORS.${props.errorKey}`);
});

const showActionInput = computed(() => {
  if (
    actionData.value.action_name === 'send_email_to_team' ||
    actionData.value.action_name === 'send_message'
  )
    return false;
  const type = macroActionTypes.find(
    action => action.key === actionData.value.action_name
  ).inputType;
  return !!type;
});

const dropdownValues = () => {
  return getMacroDropdownValues(actionData.value.action_name);
};
</script>

<template>
  <div class="relative flex items-center w-full min-w-0 basis-full">
    <woot-button
      v-if="!singleNode"
      size="small"
      variant="clear"
      color-scheme="secondary"
      icon="navigation"
      class="absolute cursor-move -left-8 macros__node-drag-handle"
    />
    <div
      class="flex-grow p-2 mr-2 rounded-md shadow-sm"
      :class="
        errorKey
          ? 'bg-red-50 animate-shake dark:bg-red-800'
          : 'bg-white dark:bg-slate-700'
      "
    >
      <ActionInput
        v-model="actionData"
        :action-types="macroActionTypes"
        :dropdown-values="dropdownValues()"
        :show-action-input="showActionInput"
        :show-remove-button="false"
        is-macro
        :error-message="errorMessage"
        :initial-file-name="fileName"
        @reset-action="$emit('resetAction')"
      />
    </div>
    <woot-button
      v-if="!singleNode"
      v-tooltip="$t('MACROS.EDITOR.DELETE_BTN_TOOLTIP')"
      icon="delete"
      size="small"
      variant="smooth"
      color-scheme="alert"
      @click="$emit('deleteNode')"
    />
  </div>
</template>
