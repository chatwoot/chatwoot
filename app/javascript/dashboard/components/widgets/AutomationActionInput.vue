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
        <div v-if="inputType" class="w-full">
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
      :enable-variables="true"
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
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
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
  @apply bg-slate-50 dark:bg-slate-800 p-2 border border-solid border-slate-75 dark:border-slate-600 rounded-md mb-2;

  &.is-a-macro {
    @apply mb-0 bg-white dark:bg-slate-700 p-0 border-0 rounded-none;
  }
}

.no-margin-bottom {
  @apply mb-0;
}

.filter.has-error {
  @apply bg-red-50 dark:bg-red-800/50 border-red-100 dark:border-red-700/50;
}

.filter-inputs {
  @apply flex;
}

.filter-error {
  @apply text-red-500 dark:text-red-200 block my-1 mx-0;
}

.action__question,
.filter__operator {
  @apply mb-0 mr-1;
}

.action__question {
  @apply max-w-[50%];
}

.action__question.full-width {
  @apply max-w-full;
}

.filter__answer--wrap {
  @apply max-w-[50%] flex-grow mr-1 flex w-full items-center justify-start;

  input {
    @apply mb-0;
  }
}
.filter__answer {
  &.answer--text-input {
    @apply mb-0;
  }
}

.filter__join-operator-wrap {
  @apply relative z-20 m-0;
}

.filter__join-operator {
  @apply flex items-center justify-center relative my-2.5 mx-0;

  .operator__line {
    @apply absolute w-full border-b border-solid border-slate-75 dark:border-slate-600;
  }

  .operator__select {
    margin-bottom: var(--space-zero) !important;
    @apply relative w-auto;
  }
}

.multiselect {
  @apply mb-0;
}
.action-message {
  @apply mt-2 mx-0 mb-0;
}
// Prosemirror does not have a native way of hiding the menu bar, hence
::v-deep .ProseMirror-menubar {
  @apply hidden;
}
</style>
