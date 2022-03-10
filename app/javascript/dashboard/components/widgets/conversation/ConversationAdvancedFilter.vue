<template>
  <div class="column">
    <woot-modal-header :header-title="$t('FILTER.TITLE')">
      <p>{{ $t('FILTER.SUBTITLE') }}</p>
    </woot-modal-header>
    <div class="row modal-content">
      <div class="medium-12 columns filters-wrap">
        <filter-input-box
          v-for="(filter, i) in appliedFilters"
          :key="i"
          v-model="appliedFilters[i]"
          :filter-groups="filterGroups"
          :input-type="getInputType(appliedFilters[i].attribute_key)"
          :operators="getOperators(appliedFilters[i].attribute_key)"
          :dropdown-values="getDropdownValues(appliedFilters[i].attribute_key)"
          :show-query-operator="i !== appliedFilters.length - 1"
          :show-user-input="showUserInput(appliedFilters[i].filter_operator)"
          :grouped-filters="true"
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
            {{ $t('FILTER.ADD_NEW_FILTER') }}
          </woot-button>
        </div>
      </div>
      <div class="medium-12 columns">
        <div class="modal-footer justify-content-end w-full">
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('FILTER.CANCEL_BUTTON_LABEL') }}
          </woot-button>
          <woot-button @click="submitFilterQuery">
            {{ $t('FILTER.SUBMIT_BUTTON_LABEL') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required, requiredIf } from 'vuelidate/lib/validators';
import FilterInputBox from '../FilterInput/Index.vue';
import languages from './advancedFilterItems/languages';
import countries from 'shared/constants/countries.js';
import { mapGetters } from 'vuex';
import { filterAttributeGroups } from './advancedFilterItems';
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
          required: requiredIf(prop => {
            return !(
              prop.filter_operator === 'is_present' ||
              prop.filter_operator === 'is_not_present'
            );
          }),
        },
      },
    },
  },
  data() {
    return {
      show: true,
      appliedFilters: [],
      filterTypes: this.initialFilterTypes,
      filterAttributeGroups,
      filterGroups: [],
      allCustomAttributes: [],
      attributeModel: 'conversation_attribute',
      filtersFori18n: 'FILTER',
    };
  },
  computed: {
    ...mapGetters({
      getAppliedConversationFilters: 'getAppliedConversationFilters',
    }),
  },
  mounted() {
    this.setFilterAttributes();
    this.$store.dispatch('campaigns/get');
    if (this.getAppliedConversationFilters.length) {
      this.appliedFilters = [...this.getAppliedConversationFilters];
    } else {
      this.appliedFilters.push({
        attribute_key: 'status',
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
    getInputType(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.inputType;
    },
    getOperators(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type.filterOperators;
    },
    getDropdownValues(type) {
      const statusFilters = this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS');
      const allCustomAttributes = this.$store.getters[
        'attributes/getAttributesByModel'
      ](this.attributeModel);

      const isCustomAttributeCheckbox = allCustomAttributes.find(attr => {
        return (
          attr.attribute_key === type &&
          attr.attribute_display_type === 'checkbox'
        );
      });

      if (isCustomAttributeCheckbox) {
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
        case 'status':
          return [
            ...Object.keys(statusFilters).map(status => {
              return {
                id: status,
                name: statusFilters[status].TEXT,
              };
            }),
            {
              id: 'all',
              name: this.$t('CHAT_LIST.FILTER_ALL'),
            },
          ];
        case 'assignee_id':
          return this.$store.getters['agents/getAgents'];
        case 'contact':
          return this.$store.getters['contacts/getContacts'];
        case 'inbox_id':
          return this.$store.getters['inboxes/getInboxes'];
        case 'team_id':
          return this.$store.getters['teams/getTeams'];
        case 'campaign_id':
          return this.$store.getters['campaigns/getAllCampaigns'].map(i => {
            return {
              id: i.id,
              name: i.title,
            };
          });
        case 'labels':
          return this.$store.getters['labels/getLabels'].map(i => {
            return {
              id: i.title,
              name: i.title,
            };
          });
        case 'browser_language':
          return languages;
        case 'country_code':
          return countries;
        default:
          return undefined;
      }
    },
    appendNewFilter() {
      this.appliedFilters.push({
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
      });
    },
    removeFilter(index) {
      if (this.appliedFilters.length <= 1) {
        this.showAlert(this.$t('FILTER.FILTER_DELETE_ERROR'));
      } else {
        this.appliedFilters.splice(index, 1);
      }
    },
    submitFilterQuery() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      this.$store.dispatch(
        'setConversationFilters',
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
