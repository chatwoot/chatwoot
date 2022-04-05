<template>
  <div
    class="filter"
    :class="{ error: v.action_params.$dirty && v.action_params.$error }"
  >
    <div class="filter-inputs">
      <select
        v-model="action_name"
        class="action__question"
        @change="resetFilter()"
      >
        <option
          v-for="attribute in actionTypes"
          :key="attribute.key"
          :value="attribute.key"
        >
          {{ attribute.label }}
        </option>
      </select>
      <div class="filter__answer--wrap">
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="action_params"
            track-by="id"
            label="name"
            :placeholder="'Select'"
            :multiple="true"
            selected-label
            :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
            deselect-label=""
            :max-height="160"
            :options="dropdownValues"
            :allow-empty="false"
          />
        </div>
      </div>
      <woot-button
        icon="dismiss"
        variant="clear"
        color-scheme="secondary"
        @click="removeAction"
      />
    </div>
    <p
      v-if="v.action_params.$dirty && v.action_params.$error"
      class="filter-error"
    >
      {{ $t('FILTER.EMPTY_VALUE_ERROR') }}
    </p>
  </div>
</template>

<script>
export default {
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
  },
  methods: {
    removeAction() {
      this.$emit('removeAction');
    },
    resetFilter() {
      this.$emit('resetFilter');
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
}

.filter.error {
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

.filter__answer--wrap {
  margin-right: var(--space-smaller);
  flex-grow: 1;

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
</style>
