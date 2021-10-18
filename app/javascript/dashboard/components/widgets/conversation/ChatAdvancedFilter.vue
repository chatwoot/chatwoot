<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column">
      <woot-modal-header header-title="Filter Conversations">
        <p>
          Add filters below and hit "Submit" to filter conversations.
        </p>
      </woot-modal-header>
      <div class="row modal-content">
        <div class="medium-12 columns filter-modal-content">
          <div v-for="(filter, i) in appliedFilters" :key="i" class="filters">
            <div class="filter--attributes">
              <select
                v-model="filter.attribute_key"
                class="filter--attributes_select"
              >
                <option
                  v-for="attribute in filterAttributes"
                  :key="attribute.key"
                  :value="attribute.key"
                >
                  {{ attribute.name }}
                </option>
              </select>
              <button
                class="filter--attribute_clearbtn"
                @click="removeFilter(i)"
              >
                <i class="icon ion-close-circled" />
              </button>
            </div>
            <div class="filter-values">
              <div class="row">
                <div class="small-4 columns padding-right-small">
                  <select
                    v-model="filter.filter_operator"
                    class="filter--values_select"
                  >
                    <option
                      v-for="(operator, o) in getOperators(
                        filter.attribute_key
                      )"
                      :key="o"
                      :value="operator.key"
                    >
                      {{ operator.value }}
                    </option>
                  </select>
                </div>
                <div class="small-8 columns">
                  <input
                    v-if="getInputType(filter.attribute_key) === 'plain_text'"
                    v-model="filter.values"
                    type="text"
                    class="filter--attributes_input"
                    placeholder="Enter value"
                  />
                  <div class="multiselect-wrap--small">
                    <multiselect
                      v-if="
                        getInputType(filter.attribute_key) === 'multi_select'
                      "
                      v-model="filter.values"
                      track-by="id"
                      label="name"
                      :placeholder="'Select'"
                      :multiple="true"
                      selected-label
                      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
                      deselect-label=""
                      :options="getDropdownValues(filter.attribute_key)"
                      :allow-empty="false"
                    />
                  </div>
                  <div class="multiselect-wrap--small">
                    <multiselect
                      v-if="
                        getInputType(filter.attribute_key) === 'search_select'
                      "
                      v-model="filter.values"
                      track-by="id"
                      label="name"
                      :placeholder="'Select'"
                      selected-label
                      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
                      deselect-label=""
                      :options="getDropdownValues(filter.attribute_key)"
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
            <div
              v-if="i !== appliedFilters.length - 1"
              class="filter--query_operator"
            >
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
            </div>
          </div>
          <div class="filter-actions">
            <button class="append-filter-btn" @click="appendNewFilter">
              <i class="icon ion-plus-circled margin-right-small" />
              <span>Add Filter</span>
            </button>
          </div>
          <div class="modal-footer justify-content-end">
            <button class="button clear" @click.prevent="onClose">
              Cancel
            </button>
            <woot-button @click="submitFilterQuery">
              Submit
            </woot-button>
          </div>
        </div>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from '../../../components/Modal';
import alertMixin from 'shared/mixins/alertMixin';
import advancedFilterTypes from './advancedFilterItems';
import { required } from 'vuelidate/lib/validators';

export default {
  components: {
    Modal,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  validations: {
    appliedFilters: {
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
      filterTypes: advancedFilterTypes,
      mockOptions: [
        {
          id: 1,
          name: 'Option 1',
        },
        {
          id: 2,
          name: 'Option 2',
        },
        {
          id: 3,
          name: 'Option 3',
        },
        {
          id: 4,
          name: 'Option 4',
        },
      ],
    };
  },
  computed: {
    filterAttributes() {
      return this.filterTypes.map(type => {
        return {
          key: type.attribute_key,
          name: type.attribute_name,
        };
      });
    },
  },
  methods: {
    getInputType(key) {
      const type = this.filterTypes.find(
        filter => filter.attribute_key === key
      );
      return type.input_type;
    },
    getOperators(key) {
      const type = this.filterTypes.find(
        filter => filter.attribute_key === key
      );
      return type.filter_operators;
    },
    // Replace getDropdownValues this with actual getters
    // eslint-disable-next-line consistent-return
    getDropdownValues(type) {
      switch (type) {
        case 'status':
          return [
            {
              id: 1,
              name: 'Open',
            },
            {
              id: 2,
              name: 'Closed',
            },
            {
              id: 3,
              name: 'Pending',
            },
          ];
        case 'assignee':
          return [
            {
              id: 1,
              name: 'Fayaz',
            },
            {
              id: 2,
              name: 'Pranav',
            },
            {
              id: 3,
              name: 'Nithin',
            },
            {
              id: 4,
              name: 'Sojan',
            },
          ];
        case 'contact':
          return [
            {
              id: 1,
              name: 'User 1',
            },
            {
              id: 2,
              name: 'User 2',
            },
            {
              id: 3,
              name: 'User 3',
            },
            {
              id: 4,
              name: 'User 4',
            },
          ];
        case 'inbox':
          return [
            {
              id: 1,
              name: 'Inbox 1',
            },
            {
              id: 2,
              name: 'Inbox 2',
            },
            {
              id: 3,
              name: 'Inbox 3',
            },
          ];
        case 'team_id':
          return [
            {
              id: 1,
              name: 'Team 1',
            },
            {
              id: 2,
              name: 'Team 2',
            },
            {
              id: 3,
              name: 'Team 3',
            },
          ];
        case 'campaign_id':
          return [
            {
              id: 1,
              name: 'Campaign 1',
            },
            {
              id: 2,
              name: 'Campaign 2',
            },
            {
              id: 3,
              name: 'Campaign 3',
            },
          ];
        case 'labels':
          return [
            {
              id: 1,
              name: 'Label 1',
            },
            {
              id: 2,
              name: 'Label 2',
            },
            {
              id: 3,
              name: 'Label 3',
            },
          ];
        case 'browser':
          return [
            {
              id: 1,
              name: 'Browser 1',
            },
            {
              id: 2,
              name: 'Browser 2',
            },
            {
              id: 3,
              name: 'Browser 3',
            },
          ];
        case 'country_code':
          return [
            {
              id: 1,
              name: 'Country 1',
            },
            {
              id: 2,
              name: 'Country 2',
            },
            {
              id: 3,
              name: 'Country 3',
            },
          ];
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
        this.showAlert('You should have atleast 1 filter to save');
      } else {
        this.appliedFilters.splice(index, 1);
      }
    },
    submitFilterQuery() {
      // this.$v.$touch();
      // if (this.$v.$invalid) {
      //   alert('Error');
      // } else {
      //   this.appliedFilters[this.appliedFilters.length - 1].query_operator =
      //     'nil';
      //   fetch('https://enogvpwj2uxd.x.pipedream.net/', {
      //     method: 'POST',
      //     body: JSON.stringify(this.appliedFilters),
      //   });
      // }
      this.appliedFilters[this.appliedFilters.length - 1].query_operator =
        'nil';
      fetch('https://enogvpwj2uxd.x.pipedream.net/', {
        method: 'POST',
        body: JSON.stringify(this.appliedFilters),
      });
    },
  },
};
</script>

<style>
.filter-modal-content {
  border: 1px solid #d9d7d7;
  border-radius: 0.35rem;
  padding: 1rem;
}
.filter--attributes {
  display: flex;
  align-items: center;
  margin-bottom: 1rem;
}
.filter--attribute_clearbtn {
  font-size: 2rem;
  margin-left: 1rem;
  cursor: pointer;
}
.filter--attributes_select {
  margin-bottom: 0 !important;
}

.filter--values_select {
  margin-bottom: 0 !important;
}

.padding-right-small {
  padding-right: 1rem;
}
.margin-right-small {
  margin-right: 0.75rem;
}
.append-filter-btn {
  width: 100%;
  border: 1px solid #d9d7d7;
  border-radius: 0.35rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #1f93ff;
  font-size: 1.5rem;
  padding: 1rem;
  height: 38px;
}
.filter-actions {
  margin: 2rem 0 1rem 0;
}
.filter--attributes_input {
  margin-bottom: 0 !important;
}
.filter--query_operator {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  margin: 1rem 0;
}
.filter--query_operator_line {
  position: absolute;
  z-index: 10;
  width: 100%;
  border-bottom: 1px solid #e4e9ef;
}
.filter--query_operator_container {
  position: relative;
  z-index: 20;
  margin: 0 0rem;
}
.filter--query_operator_select {
  width: 100%;
  margin-bottom: 0 !important;
  border: none;
  padding: 0 3rem;
}

.multiselect__tags {
  min-height: 32px;
  display: block;
  padding: 3px 40px 0 8px;
  border-radius: 5px;
  border: 1px solid #e8e8e8;
  background: #fff;
  font-size: 14px;
}
</style>
