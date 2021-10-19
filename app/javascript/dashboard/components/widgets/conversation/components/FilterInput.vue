<template>
  <div class="filters">
    <div class="filter--attributes">
      <select
        v-model="attribute_key"
        class="filter--attributes_select"
        @change="values = ''"
      >
        <option
          v-for="attribute in filterAttributes"
          :key="attribute.key"
          :value="attribute.key"
        >
          {{ attribute.name }}
        </option>
      </select>
      <button class="filter--attribute_clearbtn" @click="removeFilter(i)">
        <i class="icon ion-close-circled" />
      </button>
    </div>
    <div class="filter-values">
      <div class="row">
        <div class="small-4 columns padding-right-small">
          <select v-model="filter_operator" class="filter--values_select">
            <option
              v-for="(operator, o) in operators"
              :key="o"
              :value="operator.key"
            >
              {{ operator.value }}
            </option>
          </select>
        </div>
        <div class="small-8 columns">
          <input
            v-if="inputType === 'plain_text'"
            v-model="values"
            type="text"
            class="filter--attributes_input"
            placeholder="Enter value"
          />
          <div class="multiselect-wrap--small">
            <multiselect
              v-if="inputType === 'multi_select'"
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
          <div class="multiselect-wrap--small">
            <multiselect
              v-if="inputType === 'search_select'"
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
          <!-- <div v-if="!v.filter.values.required" class="error">
                    Value is required.
                  </div> -->
        </div>
      </div>
    </div>
    <!-- <div v-if="i !== appliedFilters.length - 1" class="filter--query_operator">
      <hr class="filter--query_operator_line" />
      <div class="filter--query_operator_container">
        <select
          v-model="filter.query_operator"
          class="filter--query_operator_select"
        >
          <option value="and">
            AND
          </option>
          <option value="or">
            OR
          </option>
        </select>
      </div>
    </div> -->
  </div>
</template>

<script>
export default {
  props: {
    filterData: {
      type: Object,
      default: () => {},
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
      default: () => ['op1', 'op2', 'op3'],
    },
  },
  data() {
    return {
      filter: this.filterData,
    };
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
      this.$emit('remove-filter');
    },
  },
};
</script>

<style></style>
