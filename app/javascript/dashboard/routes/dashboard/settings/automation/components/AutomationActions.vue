<script setup>
import { computed } from 'vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import {
  getFileName,
  showActionInput,
} from 'dashboard/helper/automationHelper';

const props = defineProps({
  actionTypes: {
    type: Array,
    required: true,
  },
  getActionDropdownValues: {
    type: Function,
    required: true,
  },
  files: {
    type: Array,
    default: () => [],
  },
  showFileName: {
    type: Boolean,
    default: false,
  },
  errors: {
    type: Object,
    default: () => ({}),
  },
  appendNewAction: {
    type: Function,
    required: true,
  },
  removeAction: {
    type: Function,
    required: true,
  },
  resetAction: {
    type: Function,
    required: true,
  },
});

const actions = defineModel({ type: Array, required: true });

const hasActionErrors = computed(() =>
  Object.keys(props.errors).some(key => key.startsWith('action_'))
);
</script>

<template>
  <section>
    <label>
      {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
    </label>
    <ul
      class="grid p-3 list-none border-solid outline outline-1 rounded-xl -outline-offset-1"
      :class="
        hasActionErrors
          ? 'outline-n-ruby-5 bg-n-ruby-2/50'
          : 'outline-n-weak dark:outline-n-strong'
      "
    >
      <AutomationActionInput
        v-for="(action, i) in actions"
        :key="i"
        v-model="actions[i]"
        :action-types="actionTypes"
        :dropdown-values="getActionDropdownValues(action.action_name)"
        :show-action-input="showActionInput(actionTypes, action.action_name)"
        :error-message="
          errors[`action_${i}`]
            ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
            : ''
        "
        :initial-file-name="showFileName ? getFileName(action, files) : ''"
        @reset-action="resetAction(i)"
        @remove-action="removeAction(i)"
      />
      <div class="pt-2">
        <NextButton
          icon="i-lucide-plus"
          blue
          faded
          sm
          :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
          @click="appendNewAction"
        />
      </div>
    </ul>
  </section>
</template>
