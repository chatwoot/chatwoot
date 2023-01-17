<template>
  <div class="filter" :class="actionInputStyles">
    <div class="filter-inputs">
      <select
        v-model="action_name"
        class="action__question"
        :class="{ 'full-width': !showActionInput }"
        @change="resetAction()"
      >
        <option
          v-for="attribute in actionTypes"
          :key="attribute.key"
          :value="attribute.key"
        >
          {{ attribute.label }}
        </option>
      </select>
      <div v-if="showActionInput" class="filter__answer--wrap">
        <div v-if="inputType">
          <div
            v-if="inputType === 'search_select'"
            class="multiselect-wrap--small"
          >
            <multiselect
              v-model="action_params"
              track-by="id"
              label="name"
              :placeholder="$t('FORMS.MULTISELECT.SELECT')"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              deselect-label=""
              :max-height="160"
              :options="dropdownValues"
              :allow-empty="false"
              :option-height="104"
            />
          </div>
          <div
            v-else-if="inputType === 'multi_select'"
            class="multiselect-wrap--small"
          >
            <multiselect
              v-model="action_params"
              track-by="id"
              label="name"
              :placeholder="$t('FORMS.MULTISELECT.SELECT')"
              :multiple="true"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              deselect-label=""
              :max-height="160"
              :options="dropdownValues"
              :allow-empty="false"
              :option-height="104"
            />
          </div>
          <input
            v-else-if="inputType === 'email'"
            v-model="action_params"
            type="email"
            class="answer--text-input"
            placeholder="Enter email"
          />
          <input
            v-else-if="inputType === 'url'"
            v-model="action_params"
            type="url"
            class="answer--text-input"
            placeholder="Enter url"
          />
          <automation-action-file-input
            v-if="inputType === 'attachment'"
            v-model="action_params"
            :initial-file-name="initialFileName"
          />
        </div>
      </div>
      <woot-button
        v-if="!isMacro"
        icon="dismiss"
        variant="clear"
        color-scheme="secondary"
        @click="removeAction"
      />
    </div>
    <automation-action-team-message-input
      v-if="inputType === 'team_message'"
      v-model="action_params"
      :teams="dropdownValues"
    />
    <woot-message-editor
      v-if="inputType === 'textarea'"
      v-model="castMessageVmodel"
      rows="4"
      :placeholder="$t('AUTOMATION.ACTION.TEAM_MESSAGE_INPUT_PLACEHOLDER')"
      class="action-message"
    />
    <p
      v-if="v.action_params.$dirty && v.action_params.$error"
      class="filter-error"
    >
      {{ $t('FILTER.EMPTY_VALUE_ERROR') }}
    </p>
  </div>
</template>

<script>
import AutomationActionTeamMessageInput from './AutomationActionTeamMessageInput.vue';
import AutomationActionFileInput from './AutomationFileInput.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';
export default {
  components: {
    AutomationActionTeamMessageInput,
    AutomationActionFileInput,
    WootMessageEditor,
  },
  props: {
    value: {
      type: Object,
      default: () => null,
    },
    actionTypes: {
      type: Array,
      default: () => [],
    },
    dropdownValues: {
      type: Array,
      default: () => [],
    },
    v: {
      type: Object,
      default: () => null,
    },
    showActionInput: {
      type: Boolean,
      default: true,
    },
    initialFileName: {
      type: String,
      default: '',
    },
    isMacro: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    action_name: {
      get() {
        if (!this.value) return null;
        return this.value.action_name;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, action_name: value });
      },
    },
    action_params: {
      get() {
        if (!this.value) return null;
        return this.value.action_params;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, action_params: value });
      },
    },
    inputType() {
      return this.actionTypes.find(action => action.key === this.action_name)
        .inputType;
    },
    actionInputStyles() {
      return {
        'has-error': this.v.action_params.$dirty && this.v.action_params.$error,
        'is-a-macro': this.isMacro,
      };
    },
    castMessageVmodel: {
      get() {
        if (Array.isArray(this.action_params)) {
          return this.action_params[0];
        }
        return this.action_params;
      },
      set(value) {
        this.action_params = value;
      },
    },
  },
  methods: {
    removeAction() {
      this.$emit('removeAction');
    },
    resetAction() {
      this.$emit('resetAction');
    },
  },
};
</script>

<style lang="scss" scoped>
.filter {
  background: var(--color-background);
  padding: var(--space-small);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-medium);
  margin-bottom: var(--space-small);

  &.is-a-macro {
    margin-bottom: 0;
    background: var(--white);
    padding: var(--space-zero);
    border: unset;
    border-radius: unset;
  }
}

.no-margin-bottom {
  margin-bottom: 0;
}

.filter.has-error {
  background: var(--r-50);
}

.filter-inputs {
  display: flex;
}

.filter-error {
  color: var(--r-500);
  display: block;
  margin: var(--space-smaller) 0;
}

.action__question,
.filter__operator {
  margin-bottom: var(--space-zero);
  margin-right: var(--space-smaller);
}

.action__question {
  max-width: 50%;
}

.action__question.full-width {
  max-width: 100%;
}

.filter__answer--wrap {
  margin-right: var(--space-smaller);
  flex-grow: 1;
  max-width: 50%;

  input {
    margin-bottom: 0;
  }
}
.filter__answer {
  &.answer--text-input {
    margin-bottom: var(--space-zero);
  }
}

.filter__join-operator-wrap {
  position: relative;
  z-index: var(--z-index-twenty);
  margin: var(--space-zero);
}

.filter__join-operator {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  margin: var(--space-one) var(--space-zero);

  .operator__line {
    position: absolute;
    width: 100%;
    border-bottom: 1px solid var(--color-border);
  }

  .operator__select {
    position: relative;
    width: auto;
    margin-bottom: var(--space-zero) !important;
  }
}

.multiselect {
  margin-bottom: var(--space-zero);
}
.action-message {
  margin: var(--space-small) var(--space-zero) var(--space-zero);
}
// Prosemirror does not have a native way of hiding the menu bar, hence
::v-deep .ProseMirror-menubar {
  display: none;
}
</style>
