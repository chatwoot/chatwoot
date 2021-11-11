<template>
  <div class="filters">
    <div class="filter--attributes">
      <select
        v-model="attribute_key"
        class="filter--attributes_select"
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
      <button class="filter--attribute_clearbtn" @click="removeFilter">
        <i class="icon ion-close-circled" />
      </button>
    </div>
    <div class="filter-values">
      <div class="row">
        <div
          class="columns padding-right-small"
          :class="showUserInput ? 'small-4' : 'small-12'"
        >
          <select v-model="filter_operator" class="filter--values_select">
            <option
              v-for="(operator, o) in operators"
              :key="o"
              :value="operator.value"
            >
              {{ $t(`FILTER.OPERATOR_LABELS.${operator.value}`) }}
            </option>
          </select>
        </div>
        <div v-if="showUserInput" class="small-8 columns">
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
            class="filter--attributes_input"
            placeholder="Enter value"
          />
          <div v-if="v.values.$dirty && v.values.$error" class="filter-error">
            {{ $t('FILTER.EMPTY_VALUE_ERROR') }}
          </div>
        </div>
      </div>
    </div>
    <div v-if="showQueryOperator" class="filter--query_operator">
      <hr class="filter--query_operator_line" />
      <div class="filter--query_operator_container">
        <select v-model="query_operator" class="filter--query_operator_select">
          <option value="and">
            {{ $t('FILTER.QUERY_DROPDOWN_LABELS.AND') }}
          </option>
          <option value="or">
            {{ $t('FILTER.QUERY_DROPDOWN_LABELS.OR') }}
          </option>
        </select>
      </div>
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
    attribute_key: {
      get() {
        if (!this.value) return null;
        return this.value.attribute_key;
      },
      set(value) {
        const payload = this.value || {};
        this.$emit('input', { ...payload, attribute_key: value });
      },
    },
    filter_operator: {
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

<style scoped>
.multiselect {
  margin-bottom: var(--space-zero) !important;
}
.filter-error {
  color: var(--r-500);
}
</style>
