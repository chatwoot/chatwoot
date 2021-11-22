<template>
  <div class="column">
    <woot-modal-header :header-title="$t('CONTACTS_FILTER.TITLE')">
      <p>{{ $t('CONTACTS_FILTER.SUBTITLE') }}</p>
    </woot-modal-header>
    <div class="row modal-content">
      <div class="medium-12 columns">
        <filter-input-box
          v-for="(filter, i) in appliedFilters"
          :key="i"
          v-model="appliedFilters[i]"
          :filter-attributes="filterAttributes"
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
          <button class="append-filter-btn" @click="appendNewFilter">
            <i class="icon ion-plus-circled margin-right-small" />
            <span>{{ $t('CONTACTS_FILTER.ADD_NEW_FILTER') }}</span>
          </button>
        </div>
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
import FilterInputBox from '../../../../components/FilterInput.vue';
import countries from '../../../../../shared/constants/countries';

export default {
  components: {
    FilterInputBox,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    filterTypes: {
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
    };
  },
  computed: {
    filterAttributes() {
      return this.filterTypes.map(type => {
        return {
          key: type.attributeKey,
          name: this.$t(`CONTACTS_FILTER.ATTRIBUTES.${type.attributeI18nKey}`),
        };
      });
    },
    getAppliedContactFilters() {
      return this.$store.getters['contacts/getAppliedContactFilters'];
    },
  },
  mounted() {
    if (this.getAppliedContactFilters.length) {
      this.appliedFilters = this.getAppliedContactFilters;
    } else {
      this.appliedFilters.push({
        attribute_key: 'name',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
      });
    }
  },
  methods: {
    getInputType(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.inputType;
    },
    getOperators(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.filterOperators;
    },
    // eslint-disable-next-line consistent-return
    getDropdownValues(type) {
      switch (type) {
        case 'country_code':
          return countries;
        default:
          break;
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
      this.appliedFilters[this.appliedFilters.length - 1].query_operator = null;
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
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/widgets/_filters';
</style>
