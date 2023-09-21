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
        'has-error': hasError($v.macro.actions.$each[index]),
      }"
    >
      <action-input
        v-model="actionData"
        :action-types="macroActionTypes"
        :dropdown-values="dropdownValues()"
        :show-action-input="showActionInput"
        :show-remove-button="false"
        :is-macro="true"
        :v="$v.macro.actions.$each[index]"
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

<script>
import ActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import macrosMixin from 'dashboard/mixins/macrosMixin';
import { mapGetters } from 'vuex';

export default {
  components: {
    ActionInput,
  },
  mixins: [macrosMixin],
  inject: ['macroActionTypes', '$v'],
  props: {
    singleNode: {
      type: Boolean,
      default: false,
    },
    value: {
      type: Object,
      default: () => ({}),
    },
    index: {
      type: Number,
      default: 0,
    },
    fileName: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
      agents: 'agents/getAgents',
    }),
    actionData: {
      get() {
        return this.value;
      },
      set(value) {
        this.$emit('input', value);
      },
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
    hasError(v) {
      return !!(v.action_params.$dirty && v.action_params.$error);
    },
  },
};
</script>

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
