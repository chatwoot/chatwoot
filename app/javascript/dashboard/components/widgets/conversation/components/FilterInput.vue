<template>
  <div class="filters">
    <div class="filter">
      <div class="filter-inputs">
        <select
          v-model="attributeKey"
          class="filter__question"
          @change="resetFilter()"
        >
          <option
            v-for="attribute in filterAttributes"
            :key="attribute.key"
            :value="attribute.key"
          >
            {{ $t(`FILTER.ATTRIBUTES.${attribute.attributeI18nKey}`) }}
          </option>
        </select>

        <select v-model="filterOperator" class="filter__operator">
          <option
            v-for="(operator, o) in operators"
            :key="o"
            :value="operator.value"
          >
            {{ $t(`FILTER.OPERATOR_LABELS.${operator.value}`) }}
          </option>
        </select>

        <div v-if="showUserInput" class="filter__answer--wrap">
          <div
            v-if="inputType === 'multi_select'"
            class="multiselect-wrap--small"
          >
            <multiselect
              v-model="values"
              track-by="id"
              label="name"
              :placeholder="'Select'"
              :multiple="true"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              deselect-label=""
              :options="dropdownValues"
              :allow-empty="false"
            />
          </div>
          <div
            v-else-if="inputType === 'search_select'"
            class="multiselect-wrap--small"
          >
            <multiselect
              v-model="values"
              track-by="id"
              label="name"
              :placeholder="'Select'"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              deselect-label=""
              :options="dropdownValues"
              :allow-empty="false"
              :option-height="104"
            />
          </div>
          <input
            v-else
            v-model="values"
            type="text"
            class="answer--text-input"
            placeholder="Enter value"
          />
        </div>
        <woot-button
          icon="ion-close"
          variant="clear"
          color-scheme="secondary"
          @click="removeFilter"
        />
      </div>
      <p v-if="v.values.$dirty && v.values.$error" class="filter-error">
        {{ $t('FILTER.EMPTY_VALUE_ERROR') }}
      </p>
    </div>

    <div v-if="showQueryOperator" class="filter__join-operator">
      <hr class="operator__line" />
      <select v-model="query_operator" class="operator__select">
        <option value="and">
          {{ $t('FILTER.QUERY_DROPDOWN_LABELS.AND') }}
        </option>
        <option value="or">
          {{ $t('FILTER.QUERY_DROPDOWN_LABELS.OR') }}
        </option>
      </select>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    value: {
      type: Object,
      default: () => null,
    },
    filterAttributes: {
      type: Array,
      default: () => [],
    },
    inputType: {
      type: String,
      default: 'plain_text',
    },
    operators: {
      type: Array,
      default: () => [],
    },
    dropdownValues: {
      type: Array,
      default: () => [],
    },
    showQueryOperator: {
      type: Boolean,
      default: false,
    },
    v: {
      type: Object,
      default: () => null,
    },
    showUserInput: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    attributeKey: {
      get() {
        if (!this.value) return null;
        return this.value.attribute_key;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, attribute_key: value });
      },
    },
    filterOperator: {
      get() {
        if (!this.value) return null;
        return this.value.filter_operator;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, filter_operator: value });
      },
    },
    values: {
      get() {
        if (!this.value) return null;
        return this.value.values;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, values: value });
      },
    },
    query_operator: {
      get() {
        if (!this.value) return null;
        return this.value.query_operator;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, query_operator: value });
      },
    },
  },
  methods: {
    removeFilter() {
      this.$emit('removeFilter');
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
}

.filter-inputs {
  display: flex;
}

.filter-error {
  color: var(--r-500);
  display: block;
  margin: var(--space-smaller) 0;
}

.filter__question,
.filter__operator {
  margin-bottom: var(--space-zero);
  margin-right: var(--space-smaller);
}

.filter__question {
  max-width: 30%;
}

.filter__operator {
  max-width: 20%;
}

.filter__answer--wrap {
  margin-right: var(--space-smaller);
  flex-grow: 1;
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
