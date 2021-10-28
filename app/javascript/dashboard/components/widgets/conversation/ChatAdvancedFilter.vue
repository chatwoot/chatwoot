<template>
  <div class="column">
    <woot-modal-header header-title="Filter Conversations">
      <p>
        {{ $t('FILTER.SUBTITLE') }}
      </p>
    </woot-modal-header>
    <div class="row modal-content">
      <div class="medium-12 columns filter-modal-content">
        <filter-input-box
          v-for="(filter, i) in appliedFilters"
          :key="i"
          v-model="appliedFilters[i]"
          :filter-data="filter"
          :filter-attributes="filterAttributes"
          :input-type="getInputType(appliedFilters[i].attribute_key)"
          :operators="getOperators(appliedFilters[i].attribute_key)"
          :dropdown-values="getDropdownValues(appliedFilters[i].attribute_key)"
          :show-query-operator="i !== appliedFilters.length - 1"
          :v="$v.appliedFilters.$each[i]"
          @clearPreviousValues="clearPreviousValues(i)"
          @removeFilter="removeFilter(i)"
        />
        <div class="filter-actions">
          <button class="append-filter-btn" @click="appendNewFilter">
            <i class="icon ion-plus-circled margin-right-small" />
            <span>{{ $t('FILTER.ADD_NEW_FILTER') }}</span>
          </button>
        </div>
        <div class="modal-footer justify-content-end">
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
import Modal from '../../../components/Modal';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import filterInputBox from './components/FilterInput.vue';
import languages from './advancedFilterItems/languages';
import countries from './advancedFilterItems/countries';

export default {
  components: {
    Modal,
    filterInputBox,
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
      appliedFilters: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: '',
          query_operator: 'and',
        },
      ],
    };
  },
  computed: {
    filterAttributes() {
      return this.filterTypes.map(type => {
        return {
          key: type.attributeKey,
          name: type.attributeName,
        };
      });
    },
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
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
        case 'status':
          return [
            {
              id: 'open',
              name: 'Open',
            },
            {
              id: 'resolved',
              name: 'Resolved',
            },
            {
              id: 'pending',
              name: 'Pending',
            },
            {
              id: 'snoozed',
              name: 'Snoozed',
            },
            {
              id: 'all',
              name: 'All',
            },
          ];
        case 'assignee_id':
          return this.$store.getters['agents/getAgents'];
        case 'contact_id':
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
              id: i.id,
              name: i.title,
            };
          });
        case 'browser_language':
          return languages;
        case 'country_code':
          return countries;
        default:
          break;
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
      this.appliedFilters[this.appliedFilters.length - 1].query_operator = null;
      this.$emit('applyFilter', this.appliedFilters);
    },
    clearPreviousValues(index) {
      this.appliedFilters[index].values = '';
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';
.filter-modal-content {
  border: 1px solid $color-border;
  border-radius: $space-small;
  padding: $space-normal;
}
.filter--attributes {
  display: flex;
  align-items: center;
  margin-bottom: $space-normal;
}
.filter--attribute_clearbtn {
  font-size: $font-size-bigger;
  margin-left: $space-normal;
  cursor: pointer;
}
.filter--attributes_select {
  margin-bottom: $zero !important;
}

.filter--values_select {
  margin-bottom: $zero !important;
}

.padding-right-small {
  padding-right: $space-normal;
}
.margin-right-small {
  margin-right: $space-slab;
}
.append-filter-btn {
  width: 100%;
  border: 1px solid $color-border;
  border-radius: $space-small;
  display: flex;
  align-items: center;
  justify-content: center;
  color: $color-woot;
  font-size: $font-size-big;
  padding: $space-normal;
  height: 38px;
  cursor: pointer;
}
.filter-actions {
  margin: $space-large $zero $space-normal $zero;
}
.filter--attributes_input {
  margin-bottom: $zero !important;
}
.filter--query_operator {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  margin: $space-normal $zero;
}
.filter--query_operator_line {
  position: absolute;
  z-index: 10;
  width: 100%;
  border-bottom: 1px solid $color-border;
}
.filter--query_operator_container {
  position: relative;
  z-index: 20;
  margin: $zero;
}
.filter--query_operator_select {
  width: 100%;
  margin-bottom: $zero !important;
  border: none;
  padding: $zero $space-larger $zero $space-two;
}
</style>
