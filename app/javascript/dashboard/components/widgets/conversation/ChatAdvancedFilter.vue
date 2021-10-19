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
          <filter-input-box
            v-for="(filter, i) in appliedFilters"
            :key="i"
            v-model="appliedFilters[i]"
            :filter-data="filter"
            :filter-attributes="filterAttributes"
            :input-type="getInputType(appliedFilters[i].attribute_key)"
            :operators="getOperators(appliedFilters[i].attribute_key)"
            :dropdown-values="
              getDropdownValues(appliedFilters[i].attribute_key)
            "
            :show-query-operator="i !== appliedFilters.length - 1"
            @clearPreviousValues="clearPreviousValues(i)"
            @removeFilter="removeFilter(i)"
          />
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
import { required } from 'vuelidate/lib/validators';
import filterInputBox from './components/FilterInput.vue';

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
      let check = this.appliedFilters.every(item => {
        return item.values;
      });
      if (check) {
        this.appliedFilters[this.appliedFilters.length - 1].query_operator =
          'nil';
        fetch('https://enogvpwj2uxd.x.pipedream.net/', {
          method: 'POST',
          body: JSON.stringify(this.appliedFilters),
        });
        alert('filter succesfully applied');
      } else {
        alert('You have left some filters blank');
      }
    },
    clearPreviousValues(index) {
      this.appliedFilters[index].values = '';
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
