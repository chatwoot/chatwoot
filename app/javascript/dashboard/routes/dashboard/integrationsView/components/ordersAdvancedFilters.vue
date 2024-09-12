<template>
  <div>
    <woot-modal-header :header-title="filterModalHeaderTitle">
      <p class="text-slate-600 dark:text-slate-200">
        {{ filterModalSubTitle }}
      </p>
    </woot-modal-header>
    <div class="p-8">
      <div v-if="isSegmentsView">
        <label class="input-label" :class="{ error: !activeSegmentNewName }">
          {{ $t('ORDERS_FILTER.SEGMENT_LABEL') }}
          <input
            v-model="activeSegmentNewName"
            type="text"
            class="folder-input border-slate-75 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100"
          />
          <span v-if="!activeSegmentNewName" class="message">
            {{ $t('ORDERS_FILTER.EMPTY_VALUE_ERROR') }}
          </span>
        </label>
        <label class="input-label">
          {{ $t('ORDERS_FILTER.SEGMENT_QUERY_LABEL') }}
        </label>
      </div>
      <div
        class="p-4 rounded-lg bg-slate-25 dark:bg-slate-900 border border-solid border-slate-50 dark:border-slate-700/50 mb-4"
      >
        <filter-input-box
          v-for="(filter, i) in appliedFilters"
          :key="i"
          v-model="appliedFilters[i]"
          :filter-groups="filterGroups"
          :grouped-filters="true"
          :input-type="
            getInputType(
              appliedFilters[i].attribute_key,
              appliedFilters[i].filter_operator
            )
          "
          :operators="getOperators(appliedFilters[i].attribute_key)"
          :dropdown-values="getDropdownValues(appliedFilters[i].attribute_key)"
          :show-query-operator="i !== appliedFilters.length - 1"
          :show-user-input="showUserInput(appliedFilters[i].filter_operator)"
          :v="$v.appliedFilters.$each[i]"
          @resetFilter="resetFilter(i, appliedFilters[i])"
          @removeFilter="removeFilter(i)"
        />
        <div class="mt-4">
          <woot-button
            icon="add"
            color-scheme="success"
            variant="smooth"
            size="small"
            @click="appendNewFilter"
          >
            {{ $t('ORDERS_FILTER.ADD_NEW_FILTER') }}
          </woot-button>
          <woot-button
            v-if="hasAppliedFilters && !isSegmentsView"
            icon="subtract"
            color-scheme="alert"
            variant="smooth"
            size="small"
            @click="clearFilters"
          >
            {{ $t('ORDERS_FILTER.CLEAR_ALL_FILTERS') }}
          </woot-button>
        </div>
      </div>
      <div class="w-full">
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('ORDERS_FILTER.CANCEL_BUTTON_LABEL') }}
          </woot-button>
          <woot-button
            v-if="isSegmentsView"
            :disabled="!activeSegmentNewName"
            @click="updateSegment"
          >
            {{ $t('ORDERS_FILTER.UPDATE_BUTTON_LABEL') }}
          </woot-button>
          <woot-button v-else @click="submitFilterQuery">
            {{ $t('ORDERS_FILTER.SUBMIT_BUTTON_LABEL') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import { required } from 'vuelidate/lib/validators';
import FilterInputBox from '../../../../components/widgets/FilterInput/Index.vue';
import countries from 'shared/constants/countries.js';
import { mapGetters } from 'vuex';
import { filterAttributeGroups } from '../orderFilterItems';
import filterMixin from 'shared/mixins/filterMixin';
import * as OPERATORS from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';
import {
  CONTACTS_EVENTS,
  ORDERS_EVENTS,
} from '../../../../helper/AnalyticsHelper/events';
export default {
  components: {
    FilterInputBox,
  },
  mixins: [filterMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    initialFilterTypes: {
      type: Array,
      default: () => [],
    },
    initialAppliedFilters: {
      type: Array,
      default: () => [],
    },
    isSegmentsView: {
      type: Boolean,
      default: false,
    },
    activeSegmentName: {
      type: String,
      default: '',
    },
  },
  validations: {
    appliedFilters: {
      required,
      $each: {
        values: {
          required,
          ensureBetween0to999(value, prop) {
            if (prop.filter_operator === 'days_before') {
              return parseInt(value, 10) > 0 && parseInt(value, 10) < 999;
            }
            return true;
          },
        },
      },
    },
  },
  data() {
    return {
      show: true,
      appliedFilters: this.initialAppliedFilters,
      activeSegmentNewName: this.activeSegmentName,
      filterTypes: this.initialFilterTypes,
      filterGroups: [],
      allCustomAttributes: [],
      filterAttributeGroups,
      attributeModel: 'order_attribute',
      filtersFori18n: 'ORDERS_FILTER',
    };
  },
  computed: {
    ...mapGetters({
      getAppliedOrdersFilters: 'integrationsView/getAppliedOrdersFilters',
    }),
    hasAppliedFilters() {
      return this.getAppliedOrdersFilters.length;
    },
    filterModalHeaderTitle() {
      return !this.isSegmentsView
        ? this.$t('ORDERS_FILTER.TITLE')
        : this.$t('ORDERS_FILTER.EDIT_CUSTOM_SEGMENT');
    },
    filterModalSubTitle() {
      return !this.isSegmentsView
        ? this.$t('ORDERS_FILTER.SUBTITLE')
        : this.$t('ORDERS_FILTER.CUSTOM_VIEWS_SUBTITLE');
    },
  },
  mounted() {
    this.setFilterAttributes();
    if (this.getAppliedOrdersFilters.length) {
      this.appliedFilters = [...this.getAppliedOrdersFilters];
    } else if (!this.isSegmentsView) {
      this.appliedFilters.push({
        attribute_key: 'order_number',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
        attribute_model: 'standard',
      });
    }
  },
  methods: {
    getOperatorTypes(key) {
      switch (key) {
        case 'list':
          return OPERATORS.OPERATOR_TYPES_1;
        case 'text':
          return OPERATORS.OPERATOR_TYPES_3;
        case 'number':
          return OPERATORS.OPERATOR_TYPES_1;
        case 'link':
          return OPERATORS.OPERATOR_TYPES_1;
        case 'date':
          return OPERATORS.OPERATOR_TYPES_4;
        case 'checkbox':
          return OPERATORS.OPERATOR_TYPES_1;
        default:
          return OPERATORS.OPERATOR_TYPES_1;
      }
    },
    customAttributeInputType(key) {
      switch (key) {
        case 'date':
          return 'date';
        case 'text':
          return 'plain_text';
        case 'list':
          return 'search_select';
        case 'checkbox':
          return 'search_select';
        default:
          return 'plain_text';
      }
    },
    getAttributeModel(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.attributeModel;
    },
    getInputType(key, operator) {
      if (key === 'created_at' || key === 'modified_at')
        if (operator === 'days_before') return 'plain_text';
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type?.inputType;
    },
    getOperators(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type?.filterOperators;
    },
    getDropdownValues(type) {
      const allCustomAttributes = this.$store.getters[
        'attributes/getAttributesByModel'
      ](this.attributeModel);
      const isCustomAttributeCheckbox = allCustomAttributes.find(attr => {
        return (
          attr.attribute_key === type &&
          attr.attribute_display_type === 'checkbox'
        );
      });
      if (isCustomAttributeCheckbox || type === 'blocked') {
        return [
          {
            id: true,
            name: this.$t('FILTER.ATTRIBUTE_LABELS.TRUE'),
          },
          {
            id: false,
            name: this.$t('FILTER.ATTRIBUTE_LABELS.FALSE'),
          },
        ];
      }

      const isCustomAttributeList = allCustomAttributes.find(attr => {
        return (
          attr.attribute_key === type && attr.attribute_display_type === 'list'
        );
      });

      if (isCustomAttributeList) {
        return allCustomAttributes
          .find(attr => attr.attribute_key === type)
          .attribute_values.map(item => {
            return {
              id: item,
              name: item,
            };
          });
      }
      switch (type) {
        case 'country_code':
          return countries;
        default:
          return undefined;
      }
    },
    appendNewFilter() {
      if (this.isSegmentsView) {
        this.setQueryOperatorOnLastQuery();
      } else {
        this.appliedFilters.push({
          attribute_key: 'order_number',
          filter_operator: 'equal_to',
          values: '',
          query_operator: 'and',
        });
      }
    },
    setQueryOperatorOnLastQuery() {
      const lastItemIndex = this.appliedFilters.length - 1;
      this.appliedFilters[lastItemIndex] = {
        ...this.appliedFilters[lastItemIndex],
        query_operator: 'and',
      };
      this.$nextTick(() => {
        this.appliedFilters.push({
          attribute_key: 'order_number',
          filter_operator: 'equal_to',
          values: '',
          query_operator: 'and',
        });
      });
    },
    removeFilter(index) {
      if (this.appliedFilters.length <= 1) {
        useAlert(this.$t('ORDERS_FILTER.FILTER_DELETE_ERROR'));
      } else {
        this.appliedFilters.splice(index, 1);
      }
    },
    submitFilterQuery() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      this.$store.dispatch(
        'integrationsView/setOrdersFilters',
        JSON.parse(JSON.stringify(this.appliedFilters))
      );
      this.$emit('applyFilter', this.appliedFilters);
      this.$track(ORDERS_EVENTS.APPLY_FILTER, {
        applied_filters: this.appliedFilters.map(filter => ({
          key: filter.attribute_key,
          operator: filter.filter_operator,
          query_operator: filter.query_operator,
        })),
      });
    },
    updateSegment() {
      this.$emit(
        'updateSegment',
        this.appliedFilters,
        this.activeSegmentNewName
      );
    },
    resetFilter(index, currentFilter) {
      this.appliedFilters[index].filter_operator = this.filterTypes.find(
        filter => filter.attributeKey === currentFilter.attribute_key
      ).filterOperators[0].value;
      this.appliedFilters[index].values = '';
    },
    showUserInput(operatorType) {
      if (operatorType === 'is_present' || operatorType === 'is_not_present')
        return false;
      return true;
    },
    clearFilters() {
      this.$emit('clearFilters');
      this.onClose();
    },
  },
};
</script>
<style lang="scss" scoped>
.folder-input {
  @apply w-[50%];
}
</style>
