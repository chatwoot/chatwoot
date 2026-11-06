import { computed, ref } from 'vue';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useTranslationPlan } from 'dashboard/composables/useTranslationPlan';
import FilterRecommendationsApi from 'dashboard/api/filterRecommendations';
import {
  buildRecommendationGroups,
  DESCRIBE_QUERY_MAX_LENGTH,
  DESCRIBE_QUERY_MIN_LENGTH,
} from 'dashboard/components-next/filter/helper/filterHelper';
import { toAutomationCondition } from 'dashboard/helper/automationHelper';

const FILTER_TYPE = 'automation';

// The action value the actions editor shows for parameters from the API.
const toActionParams = (actionType, params, options = []) => {
  if (actionType.inputType === 'multi_select') {
    return options.filter(option => params.includes(option.id));
  }
  if (actionType.inputType === 'search_select') {
    return options.find(option => option.id === params[0]) ?? [];
  }
  if (actionType.inputType === 'textarea') return params[0] ?? '';
  return [];
};

const describeParams = params => {
  if (Array.isArray(params)) {
    return params.map(param => param?.name ?? param).join(', ');
  }
  return params?.name ?? params ?? '';
};

/**
 * Recommends an event, conditions and actions from the rule's name and description.
 * The event is set for the person while they have not picked one. Conditions and actions are offered in
 * the row pickers, and one applied to a row is not offered again.
 * Recommendations are a convenience, so failures leave the form as it is.
 * @param {Object} options
 * @param {import('vue').Ref<Object>} options.automation - The rule being edited
 * @param {import('vue').ComputedRef<Array>} options.filterTypes - The condition types of the rule's event
 * @param {import('vue').ComputedRef<Object<string, string[]>>} options.eventConditionKeys - Each event the
 *   rule can have, with that event's condition keys
 * @param {import('vue').ComputedRef<boolean>} options.canSetEvent - Whether the event may still be set
 * @param {(eventName: string) => void} options.setEvent - Sets the rule's event
 * @param {import('vue').ComputedRef<Array>} options.actionTypes - The actions the form offers, with labels
 * @param {(actionName: string) => Array} options.getActionDropdownValues - The options of an action
 */
export function useAutomationRecommendations({
  automation,
  filterTypes,
  eventConditionKeys,
  canSetEvent,
  setEvent,
  actionTypes,
  getActionDropdownValues,
}) {
  const { isAvailable } = useTranslationPlan();
  const { run, abort } = useAbortableRequest();
  // The recommendations from the API. Conditions belong to the rule's event.
  const recommendedConditions = ref([]);
  const recommendedActions = ref([]);
  // Keys of recommendations applied to a row, so they are not offered again.
  const appliedKeys = ref(new Set());
  // The text of the last request, so leaving the description unchanged does not ask again.
  let requestedQuery = '';

  const isOpen = key => !appliedKeys.value.has(key);
  const markApplied = key => {
    appliedKeys.value = new Set(appliedKeys.value).add(key);
  };

  const conditionRecommendations = computed(() =>
    buildRecommendationGroups(recommendedConditions.value, filterTypes.value)
      .map(group => ({ ...group, key: `condition:${group.label}` }))
      .filter(group => isOpen(group.key))
  );

  const actionRecommendations = computed(() =>
    recommendedActions.value.flatMap(action => {
      const actionType = actionTypes.value.find(
        type => type.key === action.action_name
      );
      if (!actionType) return [];

      const params = toActionParams(
        actionType,
        action.action_params,
        getActionDropdownValues(action.action_name)
      );
      const paramsText = describeParams(params);
      const label = paramsText
        ? `${actionType.label}: ${paramsText}`
        : actionType.label;
      const key = `action:${label}`;
      if (!isOpen(key)) return [];
      return [
        {
          key,
          label,
          action: { action_name: action.action_name, action_params: params },
        },
      ];
    })
  );

  // Replaces the condition row with the recommended conditions. Returns whether more remain.
  const applyConditionRecommendation = (rowIndex, key) => {
    const group = conditionRecommendations.value.find(item => item.key === key);
    if (!group) return false;
    automation.value.conditions.splice(
      rowIndex,
      1,
      ...group.rows.map(toAutomationCondition)
    );
    markApplied(key);
    return conditionRecommendations.value.length > 0;
  };

  // Replaces the action row with the recommended action. Returns whether more remain.
  const applyActionRecommendation = (rowIndex, key) => {
    const recommendation = actionRecommendations.value.find(
      item => item.key === key
    );
    if (!recommendation) return false;
    automation.value.actions.splice(
      rowIndex,
      1,
      structuredClone(recommendation.action)
    );
    markApplied(key);
    return actionRecommendations.value.length > 0;
  };

  const describedRule = () =>
    [automation.value?.name, automation.value?.description]
      .map(text => text?.trim())
      .filter(Boolean)
      .join('. ')
      .slice(0, DESCRIBE_QUERY_MAX_LENGTH);

  // The current event's keys are sent either way. When Jev picks no event, the API recommends from them.
  const requestFor = query => {
    const attributeKeys = filterTypes.value
      .filter(type => type.attributeKey && !type.disabled)
      .map(type => type.attributeKey);
    return {
      query,
      filterType: FILTER_TYPE,
      attributeKeys,
      events: canSetEvent.value ? eventConditionKeys.value : undefined,
      actionNames: actionTypes.value.map(type => type.key),
    };
  };

  const clear = () => {
    recommendedConditions.value = [];
    recommendedActions.value = [];
    appliedKeys.value = new Set();
  };

  // Asks for recommendations from the rule's name and description. The form calls it when the description
  // loses focus, because asking while the person types sends half sentences that can switch the event.
  // `force` asks again for the same text, such as after the person picks another event.
  const recommend = async ({ force = false } = {}) => {
    const query = describedRule();
    if (!force && query === requestedQuery) return;
    requestedQuery = query;
    if (!isAvailable.value || query.length < DESCRIBE_QUERY_MIN_LENGTH) {
      abort();
      clear();
      return;
    }

    try {
      const response = await run(signal =>
        FilterRecommendationsApi.create(requestFor(query), { signal })
      );
      // A newer name, description or event superseded this request.
      if (response === undefined) return;

      const { event_name: eventName, payload, actions } = response.data;
      // The conditions were recommended for this event, so it is set before they are offered.
      if (eventName && canSetEvent.value) setEvent(eventName);
      clear();
      recommendedConditions.value = payload ?? [];
      recommendedActions.value = actions ?? [];
    } catch {
      clear();
    }
  };

  const reset = () => {
    abort();
    clear();
    requestedQuery = '';
  };

  return {
    conditionRecommendations,
    actionRecommendations,
    applyConditionRecommendation,
    applyActionRecommendation,
    recommend,
    reset,
  };
}
