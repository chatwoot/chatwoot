<template>
  <div class="filters">
    <div class="filter" :class="{ error: v.values.$dirty && v.values.$error }">
      <div class="filter-inputs">
        <select
          v-if="groupedFilters"
          v-model="attributeKey"
          class="filter__question"
          @change="resetFilter()"
        >
          <optgroup
            v-for="(group, i) in filterGroups"
            :key="i"
            :label="group.name"
          >
            <option
              v-for="attribute in group.attributes"
              :key="attribute.key"
              :value="attribute.key"
            >
              {{ attribute.name }}
            </option>
          </optgroup>
        </select>
        <select
          v-else
          v-model="attributeKey"
          class="filter__question"
          @change="resetFilter()"
        >
          <option
            v-for="attribute in filterAttributes"
            :key="attribute.key"
            :value="attribute.key"
          >
            {{ attribute.name }}
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
              :max-height="160"
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
              :max-height="160"
              :options="dropdownValues"
              :allow-empty="false"
              :option-height="104"
            />
          </div>
          <div v-else-if="inputType === 'date'" class="multiselect-wrap--small">
            <input
              v-model="values"
              type="date"
              :editable="false"
              class="answer--text-input datepicker"
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
          icon="dismiss"
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
    dataType: {
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
    groupedFilters: {
      type: Boolean,
      default: false,
    },
    filterGroups: {
      type: Array,
      default: () => [],
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
    custom_attribute_type: {
      get() {
        if (!this.customAttributeType) return '';
        return this.customAttributeType;
      },
      set() {
        const payload = this.value || {};
        this.$emit('input', {
          ...payload,
          custom_attribute_type: this.customAttributeType,
        });
      },
    },
  },
  watch: {
    customAttributeType: {
      handler(value) {
        if (
          value === 'conversation_attribute' ||
          value === 'contact_attribute'
        ) {
          this.value.custom_attribute_type = this.customAttributeType;
        } else this.value.custom_attribute_type = '';
      },
      immediate: true,
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
