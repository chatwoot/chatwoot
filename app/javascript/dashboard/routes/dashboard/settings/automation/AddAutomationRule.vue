<template>
  <div class="column">
    <woot-modal-header :header-title="$t('AUTOMATION.ADD.TITLE')" />
    <div class="row modal-content">
      <div class="medium-12 columns">
        <woot-input
          v-model="automation.name"
          :label="$t('AUTOMATION.ADD.FORM.NAME.LABEL')"
          type="text"
          :class="{ error: $v.automationRuleName.$error }"
          :error="
            $v.automationRuleName.$error
              ? $t('AUTOMATION.ADD.FORM.NAME.ERROR')
              : ''
          "
          :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
          @blur="$v.automationRuleName.$touch"
        />
        <woot-input
          v-model="automation.description"
          :label="$t('AUTOMATION.ADD.FORM.DESC.LABEL')"
          type="text"
          :class="{ error: $v.automationRuleDescription.$error }"
          :error="
            $v.automationRuleDescription.$error
              ? $t('AUTOMATION.ADD.FORM.DESC.ERROR')
              : ''
          "
          :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
          @blur="$v.automationRuleDescription.$touch"
        />
        <label :class="{ error: $v.automationRuleEvent.$error }">
          {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
          <select v-model="automation.event_name" @change="onEventChange()">
            <option
              v-for="event in automationRuleEvents"
              :key="event.key"
              :value="event.key"
            >
              {{ event.value }}
            </option>
          </select>
          <span v-if="$v.automationRuleEvent.$error" class="message">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
          </span>
        </label>
        <!-- // Conditions Start -->
        <section>
          <label>
            {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
          </label>
          <div class="medium-12 columns filters-wrap">
            <filter-input-box
              v-for="(condition, i) in automation.conditions"
              :key="i"
              v-model="automation.conditions[i]"
              :filter-attributes="filterAttributes"
              :input-type="getInputType(automation.conditions[i].attribute_key)"
              :operators="getOperators(automation.conditions[i].attribute_key)"
              :dropdown-values="
                getDropdownValues(automation.conditions[i].attribute_key)
              "
              :show-query-operator="i !== automation.conditions.length - 1"
              :v="$v.automation.conditions.$each[i]"
              @resetFilter="resetFilter(i, automation.conditions[i])"
              @removeFilter="removeFilter(i)"
            />
            <div class="filter-actions">
              <woot-button
                icon="ion-plus"
                color-scheme="success"
                variant="smooth"
                size="small"
                @click="appendNewFilter"
              >
                {{ $t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL') }}
              </woot-button>
            </div>
          </div>
        </section>
        <!-- // Conditions End -->
        <!-- // Actions End -->
        <section>
          <label>
            {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
          </label>
          <div class="medium-12 columns filters-wrap">
            <filter-input-box
              v-for="(condition, i) in automation.conditions"
              :key="i"
              v-model="automation.conditions[i]"
              :filter-attributes="filterAttributes"
              :input-type="getInputType(automation.conditions[i].attribute_key)"
              :operators="getOperators(automation.conditions[i].attribute_key)"
              :dropdown-values="
                getDropdownValues(automation.conditions[i].attribute_key)
              "
              :show-query-operator="i !== automation.conditions.length - 1"
              :v="$v.automation.conditions.$each[i]"
              @resetFilter="resetFilter(i, automation.conditions[i])"
              @removeFilter="removeFilter(i)"
            />
            <div class="filter-actions">
              <woot-button
                icon="ion-plus"
                color-scheme="success"
                variant="smooth"
                size="small"
                @click="appendNewFilter"
              >
                {{ $t('AUTOMATION.ADD.ACTION_BUTTON_LABEL') }}
              </woot-button>
            </div>
          </div>
        </section>
        <!-- // Actions End -->
        <div class="medium-12 columns">
          <div class="modal-footer justify-content-end w-full">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('AUTOMATION.ADD.CANCEL_BUTTON_TEXT') }}
            </woot-button>
            <woot-button @click="submitFilterQuery">
              {{ $t('AUTOMATION.ADD.SUBMIT') }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required, requiredIf } from 'vuelidate/lib/validators';
import filterInputBox from 'dashboard/components/widgets/conversation/components/FilterInput.vue';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'dashboard/components/widgets/conversation/advancedFilterItems/countries';
import { AUTOMATION_RULE_EVENTS } from './constants';

import { getAutomationCondition } from './automationConditions';

export default {
  components: {
    filterInputBox,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  validations: {
    automationRuleName: {
      required,
    },
    automationRuleDescription: {
      required,
    },
    automationRuleEvent: {
      required,
    },
    automation: {
      conditions: {
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
  },
  data() {
    return {
      filterTypes: getAutomationCondition({
        actionType: 'conversation_created',
      }).map(filter => ({
        ...filter,
        attributeName: this.$t(`FILTER.ATTRIBUTES.${filter.attributeI18nKey}`),
      })),
      automationRuleName: '',
      automationRuleDescription: '',
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationRuleEvents: AUTOMATION_RULE_EVENTS,
      show: true,
      automation: {
        name: null,
        description: null,
        event_name: 'conversation_created',
        conditions: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          },
        ],
        actions: [
          {
            action_name: 'send_message',
            action_params: ['Welcome to the chatwoot platform.'],
          },
        ],
      },
    };
  },
  computed: {
    filterAttributes() {
      return this.filterTypes.map(type => {
        return {
          key: type.attributeKey,
          name: type.attributeName,
          attributeI18nKey: type.attributeI18nKey,
        };
      });
    },
  },
  methods: {
    onEventChange() {
      if (this.automationRuleEvent === 'conversation_created') {
        this.filterTypes = getAutomationCondition({
          actionType: 'conversation_created',
        }).map(filter => ({
          ...filter,
          attributeName: this.$t(
            `FILTER.ATTRIBUTES.${filter.attributeI18nKey}`
          ),
        }));
      }
      if (this.automationRuleEvent === 'conversation_updated') {
        this.filterTypes = getAutomationCondition({
          actionType: 'conversation_updated',
        }).map(filter => ({
          ...filter,
          attributeName: this.$t(
            `FILTER.ATTRIBUTES.${filter.attributeI18nKey}`
          ),
        }));
      }
      if (this.automationRuleEvent === 'messaged_created') {
        this.filterTypes = getAutomationCondition({
          actionType: 'messaged_created',
        }).map(filter => ({
          ...filter,
          attributeName: this.$t(
            `FILTER.ATTRIBUTES.${filter.attributeI18nKey}`
          ),
        }));
      }
    },
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
      const statusFilters = this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS');
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
      this.automation.conditions.push({
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
      });
    },
    removeFilter(index) {
      if (this.automation.conditions.length <= 1) {
        this.showAlert(this.$t('FILTER.FILTER_DELETE_ERROR'));
      } else {
        this.automation.conditions.splice(index, 1);
      }
    },
    submitFilterQuery() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      this.appliedFilters[this.appliedFilters.length - 1].query_operator = null;
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
