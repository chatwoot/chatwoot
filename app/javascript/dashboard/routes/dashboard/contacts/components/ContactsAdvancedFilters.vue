<template>
  <div class="column">
    <woot-modal-header :header-title="$t('CONTACTS_FILTER.TITLE')">
      <p>{{ $t('CONTACTS_FILTER.SUBTITLE') }}</p>
    </woot-modal-header>
    <div class="row modal-content">
      <div class="medium-12 columns filters-wrap">
        <filter-input-box
          v-for="(filter, i) in appliedFilters"
          :key="i"
          v-model="appliedFilters[i]"
          :filter-groups="filterGroups"
          :grouped-filters="true"
          :input-type="getInputType(appliedFilters[i].attribute_key)"
          :operators="getOperators(appliedFilters[i].attribute_key)"
          :dropdown-values="getDropdownValues(appliedFilters[i].attribute_key)"
          :show-query-operator="i !== appliedFilters.length - 1"
          :show-user-input="showUserInput(appliedFilters[i].filter_operator)"
          :v="$v.appliedFilters.$each[i]"
          @resetFilter="resetFilter(i, appliedFilters[i])"
          @removeFilter="removeFilter(i)"
        />
        <div class="filter-actions">
          <woot-button
            icon="add"
            color-scheme="success"
            variant="smooth"
            size="small"
            @click="appendNewFilter"
          >
            {{ $t('CONTACTS_FILTER.ADD_NEW_FILTER') }}
          </woot-button>
          <woot-button
            v-if="hasAppliedFilters"
            icon="subtract"
            color-scheme="alert"
            variant="smooth"
            size="small"
            @click="clearFilters"
          >
            {{ $t('CONTACTS_FILTER.CLEAR_ALL_FILTERS') }}
          </woot-button>
        </div>
      </div>
      <div class="medium-12 columns">
        <div class="modal-footer justify-content-end w-full">
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('CONTACTS_FILTER.CANCEL_BUTTON_LABEL') }}
          </woot-button>
          <woot-button @click="submitFilterQuery">
            {{ $t('CONTACTS_FILTER.SUBMIT_BUTTON_LABEL') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import FilterInputBox from '../../../../components/widgets/FilterInput/Index.vue';
import countries from 'shared/constants/countries.js';
import { mapGetters } from 'vuex';
import { filterAttributeGroups } from '../contactFilterItems';
import filterMixin from 'shared/mixins/filterMixin';
import * as OPERATORS from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';
export default {
  components: {
    FilterInputBox,
  },
  mixins: [alertMixin, filterMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    initialFilterTypes: {
      type: Array,
      default: () => [],
    },
  },
  validations: {
    appliedFilters: {
      required,
      $each: {
        values: {
          required,
        },
      },
    },
  },
  data() {
    return {
      show: true,
      appliedFilters: [],
      filterTypes: this.initialFilterTypes,
      filterGroups: [],
      allCustomAttributes: [],
      filterAttributeGroups,
      attributeModel: 'contact_attribute',
      filtersFori18n: 'CONTACTS_FILTER',
    };
  },
  computed: {
    ...mapGetters({
      getAppliedContactFilters: 'contacts/getAppliedContactFilters',
    }),
    hasAppliedFilters() {
      return this.getAppliedContactFilters.length;
    },
  },
  mounted() {
    this.setFilterAttributes();
    if (this.getAppliedContactFilters.length) {
      this.appliedFilters = [...this.getAppliedContactFilters];
    } else {
      this.appliedFilters.push({
        attribute_key: 'name',
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
        default:
          return 'plain_text';
      }
    },
    getAttributeModel(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.attributeModel;
    },
    getInputType(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.inputType;
    },
    getOperators(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.filterOperators;
    },
    getDropdownValues(type) {
      switch (type) {
        case 'country_code':
          return countries;
        default:
          return undefined;
      }
    },
    appendNewFilter() {
      this.appliedFilters.push({
        attribute_key: 'name',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
      });
    },
    removeFilter(index) {
      if (this.appliedFilters.length <= 1) {
        this.showAlert(this.$t('CONTACTS_FILTER.FILTER_DELETE_ERROR'));
      } else {
        this.appliedFilters.splice(index, 1);
      }
    },
    submitFilterQuery() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      this.$store.dispatch(
        'contacts/setContactFilters',
        JSON.parse(JSON.stringify(this.appliedFilters))
      );
      this.$emit('applyFilter', this.appliedFilters);
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
.filters-wrap {
  padding: var(--space-normal);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--color-border);
  background: var(--color-background-light);
  margin-bottom: var(--space-normal);
}

.filter-actions {
  margin-top: var(--space-normal);
}
</style>
