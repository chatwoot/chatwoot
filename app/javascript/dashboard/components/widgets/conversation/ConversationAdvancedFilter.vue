<script>
import { useAlert } from 'dashboard/composables';
import FilterInputBox from '../FilterInput/Index.vue';
import languages from './advancedFilterItems/languages';
import countries from 'shared/constants/countries.js';
import { mapGetters } from 'vuex';
import { filterAttributeGroups } from './advancedFilterItems';
import { useFilter } from 'shared/composables/useFilter';
import * as OPERATORS from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { validateConversationOrContactFilters } from 'dashboard/helper/validations.js';
import { useTrack } from 'dashboard/composables';

export default {
  components: {
    FilterInputBox,
  },
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
    activeFolderName: {
      type: String,
      default: '',
    },
    isFolderView: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['applyFilter', 'updateFolder'],
  setup() {
    const { setFilterAttributes } = useFilter({
      filteri18nKey: 'FILTER',
      attributeModel: 'conversation_attribute',
    });
    return {
      setFilterAttributes,
    };
  },
  data() {
    return {
      show: true,
      appliedFilters: this.initialAppliedFilters,
      activeFolderNewName: this.activeFolderName,
      filterTypes: this.initialFilterTypes,
      filterAttributeGroups,
      filterGroups: [],
      allCustomAttributes: [],
      attributeModel: 'conversation_attribute',
      filtersFori18n: 'FILTER',
      validationErrors: {},
    };
  },
  computed: {
    ...mapGetters({
      getAppliedConversationFilters: 'getAppliedConversationFilters',
    }),
    filterModalHeaderTitle() {
      return !this.isFolderView
        ? this.$t('FILTER.TITLE')
        : this.$t('FILTER.EDIT_CUSTOM_FILTER');
    },
    filterModalSubTitle() {
      return !this.isFolderView
        ? this.$t('FILTER.SUBTITLE')
        : this.$t('FILTER.CUSTOM_VIEWS_SUBTITLE');
    },
  },
  mounted() {
    const { filterGroups, filterTypes } = this.setFilterAttributes();

    this.filterTypes = [...this.filterTypes, ...filterTypes];
    this.filterGroups = filterGroups;

    this.$store.dispatch('campaigns/get');
    if (this.getAppliedConversationFilters.length) {
      this.appliedFilters = [];
      this.appliedFilters = [...this.getAppliedConversationFilters];
    } else if (!this.isFolderView) {
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
    getInputType(key, operator) {
      if (key === 'created_at' || key === 'last_activity_at')
        if (operator === 'days_before') return 'plain_text';
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type?.inputType;
    },
    getOperators(key) {
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type?.filterOperators;
    },
    statusFilterItems() {
      return {
        open: {
          TEXT: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT'),
        },
        resolved: {
          TEXT: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved.TEXT'),
        },
        pending: {
          TEXT: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending.TEXT'),
        },
        snoozed: {
          TEXT: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed.TEXT'),
        },
        all: {
          TEXT: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.all.TEXT'),
        },
      };
    },
    getDropdownValues(type) {
      const statusFilters = this.statusFilterItems();
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
      if (this.isFolderView) {
        this.setQueryOperatorOnLastQuery();
      } else {
        this.appliedFilters.push({
          attribute_key: 'status',
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
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: '',
          query_operator: 'and',
        });
      });
    },
    removeFilter(index) {
      if (this.appliedFilters.length <= 1) {
        useAlert(this.$t('FILTER.FILTER_DELETE_ERROR'));
      } else {
        this.appliedFilters.splice(index, 1);
      }
    },
    submitFilterQuery() {
      this.validationErrors = validateConversationOrContactFilters(
        this.appliedFilters
      );
      if (Object.keys(this.validationErrors).length === 0) {
        this.$store.dispatch(
          'setConversationFilters',
          JSON.parse(JSON.stringify(this.appliedFilters))
        );
        this.$emit('applyFilter', this.appliedFilters);
        useTrack(CONVERSATION_EVENTS.APPLY_FILTER, {
          applied_filters: this.appliedFilters.map(filter => ({
            key: filter.attribute_key,
            operator: filter.filter_operator,
            query_operator: filter.query_operator,
          })),
        });
      }
    },
    updateSavedCustomViews() {
      this.$emit('updateFolder', this.appliedFilters, this.activeFolderNewName);
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

<template>
  <div>
    <woot-modal-header :header-title="filterModalHeaderTitle">
      <p class="text-slate-600 dark:text-slate-200">
        {{ filterModalSubTitle }}
      </p>
    </woot-modal-header>
    <div class="p-8">
      <div v-if="isFolderView">
        <label class="input-label" :class="{ error: !activeFolderNewName }">
          {{ $t('FILTER.FOLDER_LABEL') }}
          <input
            v-model="activeFolderNewName"
            type="text"
            class="bg-white folder-input border-slate-75 dark:border-slate-600 dark:bg-slate-900 text-slate-900 dark:text-slate-100"
          />
          <span v-if="!activeFolderNewName" class="message">
            {{ $t('FILTER.EMPTY_VALUE_ERROR') }}
          </span>
        </label>
        <label class="mb-1">
          {{ $t('FILTER.FOLDER_QUERY_LABEL') }}
        </label>
      </div>
      <div
        class="p-4 mb-4 border border-solid rounded-lg bg-slate-25 dark:bg-slate-900 border-slate-50 dark:border-slate-700/50"
      >
        <FilterInputBox
          v-for="(filter, i) in appliedFilters"
          :key="i"
          v-model="appliedFilters[i]"
          :filter-groups="filterGroups"
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
          grouped-filters
          :error-message="
            validationErrors[`filter_${i}`]
              ? $t(`CONTACTS_FILTER.ERRORS.VALUE_REQUIRED`)
              : ''
          "
          @reset-filter="resetFilter(i, appliedFilters[i])"
          @remove-filter="removeFilter(i)"
        />
        <div class="mt-4">
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
      <div class="w-full">
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('FILTER.CANCEL_BUTTON_LABEL') }}
          </woot-button>
          <woot-button
            v-if="isFolderView"
            :disabled="!activeFolderNewName"
            @click="updateSavedCustomViews"
          >
            {{ $t('FILTER.UPDATE_BUTTON_LABEL') }}
          </woot-button>
          <woot-button v-else @click="submitFilterQuery">
            {{ $t('FILTER.SUBMIT_BUTTON_LABEL') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.folder-input {
  @apply w-[50%];
}
</style>
