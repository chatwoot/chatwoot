import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  attributeBlank,
  attributeMatches,
  requiredKeysForStatusChange,
} from 'dashboard/composables/useConversationRequiredAttributes';
import { isHumanAssigneeMeta } from 'dashboard/helper/assigneeHelper';

const FE_SAFE_OPERATORS = new Set([
  'equal_to',
  'not_equal_to',
  'is_present',
  'is_not_present',
  'contains',
  'does_not_contain',
]);

// ConditionRow stores SingleSelect/Input as a scalar; MultiSelect as array.
const asArray = value => {
  if (Array.isArray(value)) return value;
  if (value == null || value === '') return [];
  return [value];
};

// Dropdown options often persist as { id, name } — never String(object).
const coerceConditionValue = value => {
  if (value == null) return '';
  if (typeof value !== 'object') return String(value);
  if (Array.isArray(value)) return value.map(coerceConditionValue).join(',');
  const pick = value.id ?? value.name ?? value.title ?? value.value;
  if (pick != null && pick !== '') return String(pick);
  return '';
};

const resolveCategoryKeys = (attributes, categoryNames = []) => {
  const categories = new Set(
    asArray(categoryNames).map(coerceConditionValue).filter(Boolean)
  );
  if (!categories.size) return [];
  return (attributes || [])
    .filter(attr => !attr.formula)
    .filter(attr => categories.has((attr.category || '').trim()))
    .map(attr => attr.attributeKey || attr.attribute_key)
    .filter(Boolean);
};

const conditionValueMatches = (actual, operator, expectedValues) => {
  const values = asArray(expectedValues).map(coerceConditionValue);
  if (operator === 'is_present') {
    return !(
      actual == null ||
      actual === '' ||
      (Array.isArray(actual) && !actual.length)
    );
  }
  if (operator === 'is_not_present') {
    return (
      actual == null ||
      actual === '' ||
      (Array.isArray(actual) && !actual.length)
    );
  }
  const normalizedActual = Array.isArray(actual)
    ? actual.map(coerceConditionValue)
    : [coerceConditionValue(actual ?? '')];
  const lowerExpected = values.map(v => v.toLowerCase());
  const hit = normalizedActual.some(v =>
    lowerExpected.includes(String(v).toLowerCase())
  );
  if (operator === 'equal_to') return hit;
  if (operator === 'not_equal_to') return !hit;
  if (operator === 'contains') {
    return normalizedActual.some(a =>
      lowerExpected.some(e => a.toLowerCase().includes(e))
    );
  }
  if (operator === 'does_not_contain') {
    return !normalizedActual.some(a =>
      lowerExpected.some(e => a.toLowerCase().includes(e))
    );
  }
  return null;
};

const readConversationField = (conversation, key) => {
  if (!conversation) return undefined;
  if (key === 'status') return conversation.status;
  if (key === 'priority') return conversation.priority;
  if (key === 'assignee_id') return conversation.meta?.assignee?.id;
  if (key === 'team_id') return conversation.meta?.team?.id;
  if (key === 'inbox_id') return conversation.inbox_id;
  if (key === 'labels') {
    return (conversation.labels || []).map(l =>
      typeof l === 'string' ? l : l.title || l
    );
  }
  return (
    conversation.custom_attributes?.[key] ??
    conversation.meta?.sender?.custom_attributes?.[key]
  );
};

/**
 * Lightweight FE condition check. Unsupported operators → null (defer to API).
 */
export const evaluateConditionsClientSide = (conditions, conversation) => {
  const list = Array.isArray(conditions) ? conditions : [];
  if (!list.length) return true;

  let result = null;
  let pendingOperator = 'and';

  for (let i = 0; i < list.length; i += 1) {
    const condition = list[i] || {};
    const operator = condition.filter_operator || condition.filterOperator;
    if (!FE_SAFE_OPERATORS.has(operator)) {
      return null;
    }
    const key = condition.attribute_key || condition.attributeKey;
    const actual = readConversationField(conversation, key);
    const match = conditionValueMatches(actual, operator, condition.values);
    if (match === null) return null;

    if (result === null) result = match;
    else if (pendingOperator === 'or') result = result || match;
    else result = result && match;

    pendingOperator = String(
      condition.query_operator || condition.queryOperator || 'and'
    ).toLowerCase();
  }

  return result !== false;
};

export function useBusinessRulesStatusGuard() {
  const { currentAccount } = useAccount();
  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );
  const contactAttributes = useMapGetter('attributes/getContactAttributes');

  const businessRules = computed(
    () => currentAccount.value?.settings?.business_rules || []
  );

  const legacyKeys = computed(
    () => currentAccount.value?.settings?.conversation_required_attributes || []
  );

  const allAttributeOptions = computed(() => {
    const mapOptions = (attrs, attributeModel) =>
      (attrs || [])
        .filter(attribute => !attribute.formula)
        .map(attribute => ({
          ...attribute,
          value: attribute.attributeKey,
          label: attribute.attributeDisplayName,
          type: attribute.attributeDisplayType,
          attributeValues: attribute.attributeValues,
          attributeModel,
          category: attribute.category || '',
        }));
    return [
      ...mapOptions(conversationAttributes.value, 'conversation'),
      ...mapOptions(contactAttributes.value, 'contact'),
    ];
  });

  const expandRequiredItems = (config, type) => {
    const items = [];
    const add = (key, attributeModel) => {
      if (!key) return;
      items.push({ key: String(key), attributeModel });
    };

    if (type === 'require_attributes_on_status') {
      asArray(config.attribute_keys).forEach(key => add(key, 'conversation'));
      resolveCategoryKeys(
        conversationAttributes.value,
        config.attribute_category_keys
      ).forEach(key => add(key, 'conversation'));
      asArray(config.contact_attribute_keys).forEach(key =>
        add(key, 'contact')
      );
      resolveCategoryKeys(
        contactAttributes.value,
        config.contact_attribute_category_keys
      ).forEach(key => add(key, 'contact'));
    }

    if (type === 'if_attribute_then_require') {
      asArray(config.require_attribute_keys).forEach(key =>
        add(key, 'conversation')
      );
      resolveCategoryKeys(
        conversationAttributes.value,
        config.require_attribute_category_keys
      ).forEach(key => add(key, 'conversation'));
      asArray(config.require_contact_attribute_keys).forEach(key =>
        add(key, 'contact')
      );
      resolveCategoryKeys(
        contactAttributes.value,
        config.require_contact_attribute_category_keys
      ).forEach(key => add(key, 'contact'));
    }

    return items;
  };

  const checkStatusChange = (conversation, targetStatus = 'resolved') => {
    const convAttrs = conversation?.custom_attributes || {};
    const contactAttrs = conversation?.meta?.sender?.custom_attributes || {};
    const labels = (conversation?.labels || []).map(l =>
      typeof l === 'string' ? l : l.title || l
    );

    const requiredKeySet = new Set();
    const requiredItems = [];
    const missingItems = [];
    let needsPrivateNote = false;
    let needsReasonKey = null;
    const forbiddenLabels = [];
    let needsAssignee = false;
    let deferredToApi = false;

    const resolveDef = item => {
      const def = allAttributeOptions.value.find(
        attr =>
          attr.value === item.key && attr.attributeModel === item.attributeModel
      );
      return (
        def || {
          value: item.key,
          label: item.key,
          type: 'text',
          attributeModel: item.attributeModel,
        }
      );
    };

    // Track every field the rules require for this draft (filled or blank).
    // Modal chaining must keep filled triggers (e.g. tipo=Venta) visible.
    const addRequired = item => {
      const id = `${item.attributeModel}:${item.key}`;
      if (requiredKeySet.has(id)) return;
      requiredKeySet.add(id);
      const def = resolveDef(item);
      requiredItems.push(def);
      const attrs =
        item.attributeModel === 'contact' ? contactAttrs : convAttrs;
      if (attributeBlank(attrs, item.key, def.type || 'text')) {
        missingItems.push(def);
      }
    };

    // Legacy + require/if via shared helper (keys only), then expand categories per rule.
    const baseRequired = requiredKeysForStatusChange({
      businessRules: businessRules.value,
      legacyKeys: legacyKeys.value,
      targetStatus,
      customAttributes: convAttrs,
      contactCustomAttributes: contactAttrs,
    });
    baseRequired.forEach(item => addRequired(item));

    (businessRules.value || [])
      .filter(rule => rule?.enabled !== false)
      .forEach(rule => {
        const config = rule.config || {};
        const conditionsResult = evaluateConditionsClientSide(
          rule.conditions,
          conversation
        );
        if (conditionsResult === null) {
          deferredToApi = true;
        }

        if (
          rule.type === 'require_attributes_on_status' ||
          rule.type === 'if_attribute_then_require'
        ) {
          const onStatus =
            rule.type === 'if_attribute_then_require'
              ? config.on_status || 'resolved'
              : config.status;
          if (String(onStatus) !== String(targetStatus)) return;

          // if_attribute: apply when conditions match OR legacy when_* matches.
          // (UI often stores both; FE label filters can fail while when_* is correct.)
          if (rule.type === 'if_attribute_then_require') {
            const whenKey = config.when_attribute;
            const whenModel = config.when_attribute_model || 'conversation';
            const whenAttrs =
              whenModel === 'contact' ? contactAttrs : convAttrs;
            const whenMatches =
              Boolean(whenKey) &&
              attributeMatches(whenAttrs, whenKey, config.when_values);
            if (!(whenMatches || conditionsResult === true)) return;
          } else if (conditionsResult === false || conditionsResult === null) {
            return;
          }

          expandRequiredItems(config, rule.type).forEach(item => {
            addRequired(item);
          });
          return;
        }

        // Unsupported operators already deferred above — skip hard FE checks.
        if (conditionsResult === false || conditionsResult === null) return;

        if (rule.type === 'require_reason_on_status') {
          const statuses = asArray(config.statuses).map(String);
          if (!statuses.includes(String(targetStatus))) return;
          if (config.reason_attribute_key) {
            needsReasonKey = config.reason_attribute_key;
            addRequired({
              key: config.reason_attribute_key,
              attributeModel: 'conversation',
            });
          }
          // Private notes are only known server-side (15-min window). Never
          // hard-block in FE — defer to BusinessRulesGuard / API error.
          if (config.require_private_note) {
            deferredToApi = true;
          }
        }

        if (rule.type === 'forbid_status_if') {
          if (String(config.status) !== String(targetStatus)) return;
          const label = String(config.label || '');
          if (
            label &&
            labels
              .map(l => String(l).toLowerCase())
              .includes(label.toLowerCase())
          ) {
            forbiddenLabels.push(label);
          }
        }

        if (rule.type === 'require_assignee_on_status') {
          if (String(config.status) !== String(targetStatus)) return;
          if (!config.require_team_or_agent) return;
          // Inbox bots count as meta.assignee but do not satisfy the rule.
          const hasHumanOrTeam =
            isHumanAssigneeMeta(conversation?.meta) ||
            Boolean(conversation?.meta?.team?.id);
          if (!hasHumanOrTeam) {
            needsAssignee = true;
          }
        }
      });

    const blocked =
      missingItems.length > 0 ||
      needsPrivateNote ||
      Boolean(needsReasonKey) ||
      forbiddenLabels.length > 0 ||
      needsAssignee;

    return {
      blocked,
      deferredToApi,
      // All fields required for this draft (includes already-filled triggers).
      requiredAttributes: requiredItems,
      missingAttributes: missingItems,
      needsPrivateNote,
      needsReasonKey,
      forbiddenLabels,
      needsAssignee,
    };
  };

  return {
    checkStatusChange,
    businessRules,
    allAttributeOptions,
  };
}
