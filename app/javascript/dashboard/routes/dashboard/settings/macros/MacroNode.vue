<script setup>
import { computed, inject, defineModel } from 'vue';
import { useMacros } from 'dashboard/composables/useMacros';
import { useI18n } from 'vue-i18n';
import ActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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
  const type = macroActionTypes.value.find(
    action => action.key === actionData.value.action_name
  ).inputType;
  return !!type;
});

const dropdownValues = () => {
  return getMacroDropdownValues(actionData.value.action_name);
};
</script>

<template>
  <div class="relative flex items-start w-full min-w-0 basis-full">
    <NextButton
      v-if="!singleNode"
      ghost
      sm
      slate
      icon="i-lucide-menu"
      class="absolute cursor-move -left-10 mr-2 macros__node-drag-handle"
    />
    <div
      class="flex-grow p-2 mr-2 rounded-md shadow-sm outline outline-1 outline-n-weak"
      :class="
        errorKey
          ? 'animate-shake bg-n-ruby-8/20 outline-n-ruby-5 dark:outline-n-ruby-5'
          : 'bg-n-background dark:bg-n-solid-1'
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
    <NextButton
      v-if="!singleNode"
      v-tooltip="$t('MACROS.EDITOR.DELETE_BTN_TOOLTIP')"
      icon="i-lucide-trash-2"
      sm
      faded
      ruby
      class="flex-shrink-0"
      @click="$emit('deleteNode')"
    />
  </div>
</template>
