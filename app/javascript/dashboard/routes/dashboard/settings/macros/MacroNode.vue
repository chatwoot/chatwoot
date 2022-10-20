<template>
  <div class="macro__node-action-container">
    <fluent-icon
      v-if="!singleNode"
      size="20"
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
        @resetAction="$emit('resetAction')"
      />
      <macro-action-button
        v-if="!singleNode"
        icon="dismiss-circle"
        class="macro__node macro__node-action-button-delete"
        type="delete"
        :tooltip="$t('MACROS.EDITOR.DELETE_BTN_TOOLTIP')"
        @click="$emit('deleteNode')"
      />
    </div>
  </div>
</template>

<script>
import ActionInput from 'dashboard/components/widgets/AutomationActionInput';
import MacroActionButton from './ActionButton.vue';
import macrosMixin from 'dashboard/mixins/macrosMixin';
import { mapGetters } from 'vuex';

export default {
  components: {
    ActionInput,
    MacroActionButton,
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
  },
  computed: {
    ...mapGetters({
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
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
.macro__node-action-container {
  position: relative;
  .macros__node-drag-handle {
    position: absolute;
    left: var(--space-minus-medium);
    top: var(--space-smaller);
    cursor: move;
    color: var(--s-400);
  }
  .macro__node-action-item {
    background-color: var(--white);
    padding: var(--space-slab);
    border-radius: var(--border-radius-medium);
    box-shadow: rgb(0 0 0 / 3%) 0px 6px 24px 0px,
      rgb(0 0 0 / 6%) 0px 0px 0px 1px;

    .macro__node-action-button-delete {
      display: none;
    }
    &:hover {
      .macro__node-action-button-delete {
        display: flex;
      }
    }
    &.has-error {
      animation: shake 0.3s ease-in-out 0s 2;
      background-color: var(--r-50);
    }
  }
}

@keyframes shake {
  0% {
    transform: translateX(0);
  }
  25% {
    transform: translateX(0.375rem);
  }
  50% {
    transform: translateX(-0.375rem);
  }
  75% {
    transform: translateX(0.375rem);
  }
  100% {
    transform: translateX(0);
  }
}
</style>
