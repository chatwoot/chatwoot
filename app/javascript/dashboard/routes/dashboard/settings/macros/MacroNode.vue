<script>
import { inject } from 'vue';
import ActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import macrosMixin from 'dashboard/mixins/macrosMixin';

export default {
  components: {
    ActionInput,
  },
  mixins: [macrosMixin],
  props: {
    singleNode: {
      type: Boolean,
      default: false,
    },
    value: {
      type: Object,
      default: () => ({}),
    },
    errorKey: {
      type: String,
      default: '',
    },
    fileName: {
      type: String,
      default: '',
    },
  },
  setup() {
    const macroActionTypes = inject('macroActionTypes');
    return { macroActionTypes };
  },
  computed: {
    actionData: {
      get() {
        return this.value;
      },
      set(value) {
        this.$emit('input', value);
      },
    },
    errorMessage() {
      if (!this.errorKey) return '';

      return this.$t(`MACROS.ERRORS.${this.errorKey}`);
    },
    showActionInput() {
      if (
        this.actionData.action_name === 'send_email_to_team' ||
        this.actionData.action_name === 'send_message'
      )
        return false;
      const type = this.macroActionTypes.find(
        action => action.key === this.actionData.action_name
      ).inputType;
      return !!type;
    },
  },
  methods: {
    dropdownValues() {
      return this.getDropdownValues(this.value.action_name, this.$store);
    },
  },
};
</script>

<template>
  <div class="macro__node-action-container">
    <woot-button
      v-if="!singleNode"
      size="small"
      variant="clear"
      color-scheme="secondary"
      icon="navigation"
      class="macros__node-drag-handle"
    />
    <div
      class="macro__node-action-item"
      :class="{
        'has-error': errorKey,
      }"
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
        @resetAction="$emit('resetAction')"
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

<style scoped lang="scss">
.macros__node-drag-handle {
  @apply cursor-move -left-8 absolute;
}
.macro__node-action-container {
  @apply w-full min-w-0 basis-full items-center flex relative;

  .macro__node-action-item {
    @apply flex-grow bg-white dark:bg-slate-700 p-2 mr-2 rounded-md shadow-sm;

    &.has-error {
      animation: shake 0.3s ease-in-out 0s 2;
      @apply bg-red-50 dark:bg-red-800;
    }
  }
}

@keyframes shake {
  0% {
    transform: translateX(0);
  }
  25% {
    transform: translateX(0.234375rem);
  }
  50% {
    transform: translateX(-0.234375rem);
  }
  75% {
    transform: translateX(0.234375rem);
  }
  100% {
    transform: translateX(0);
  }
}
</style>
