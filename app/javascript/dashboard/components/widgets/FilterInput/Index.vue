<!-- eslint-disable vue/no-mutating-props -->
<template>
  <div>
    <div
      class="rounded-md p-2 border border-solid"
      :class="getInputErrorClass(v.values.$dirty, v.values.$error)"
    >
      <div class="flex">
        <select
          v-if="groupedFilters"
          v-model="attributeKey"
          class="bg-white max-w-[30%] dark:bg-slate-900 mb-0 mr-1 text-slate-800 dark:text-slate-100 border-slate-75 dark:border-slate-600"
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
          class="bg-white max-w-[30%] dark:bg-slate-900 mb-0 mr-1 text-slate-800 dark:text-slate-100 border-slate-75 dark:border-slate-600"
          @change="resetFilter()"
        >
          <option
            v-for="attribute in filterAttributes"
            :key="attribute.key"
            :value="attribute.key"
            :disabled="attribute.disabled"
          >
            {{ attribute.name }}
          </option>
        </select>

        <select
          v-model="filterOperator"
          class="bg-white dark:bg-slate-900 max-w-[20%] mb-0 mr-1 text-slate-800 dark:text-slate-100 border-slate-75 dark:border-slate-600"
        >
          <option
            v-for="(operator, o) in operators"
            :key="o"
            :value="operator.value"
          >
            {{ $t(`FILTER.OPERATOR_LABELS.${operator.value}`) }}
          </option>
        </select>

        <div v-if="showUserInput" class="filter__answer--wrap mr-1 flex-grow">
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
              class="mb-0 datepicker"
            />
          </div>
          <input
            v-else
            v-model="values"
            type="text"
            class="mb-0"
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

    <div
      v-if="showQueryOperator"
      class="flex items-center justify-center relative my-2.5 mx-0"
    >
      <hr
        class="w-full absolute border-b border-solid border-slate-75 dark:border-slate-800"
      />
      <select
        v-model="query_operator"
        class="bg-white dark:bg-slate-900 mb-0 w-auto relative text-slate-800 dark:text-slate-100 border-slate-75 dark:border-slate-600"
      >
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
    customAttributeType: {
      type: String,
      default: '',
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
          // eslint-disable-next-line vue/no-mutating-props
          this.value.custom_attribute_type = this.customAttributeType;
          // eslint-disable-next-line vue/no-mutating-props
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
    getInputErrorClass(isDirty, hasError) {
      return isDirty && hasError
        ? 'bg-red-50 dark:bg-red-800/50 border-red-100 dark:border-red-700/50'
        : 'bg-slate-50 dark:bg-slate-800 border-slate-75 dark:border-slate-700/50';
    },
  },
};
</script>
<style lang="scss" scoped>
.filter__answer--wrap {
  input {
    @apply bg-white dark:bg-slate-900 mb-0 text-slate-800 dark:text-slate-100 border-slate-75 dark:border-slate-600;
  }
}

.filter-error {
  @apply text-red-500 dark:text-red-200 block my-1 mx-0;
}

.multiselect {
  @apply mb-0;
}
</style>
