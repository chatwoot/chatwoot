/**
 * Lightweight client-side lint mirroring BusinessRules::LintService
 * (impossible AND on same attribute). Full validation stays on the API.
 */

const normalizeValues = raw => {
  if (raw == null) return [];
  if (Array.isArray(raw)) return raw.flatMap(normalizeValues);
  if (typeof raw === 'object') {
    const pick = raw.id ?? raw.name ?? raw.title ?? raw.value;
    return pick == null || pick === '' ? [] : [String(pick)];
  }
  const text = String(raw).trim();
  return text ? [text] : [];
};

const EQUALITY_OPS = ['equal_to', 'not_equal_to'];

export const findImpossibleAndErrors = (rules = []) => {
  const errors = [];
  (rules || [])
    .filter(rule => rule?.enabled !== false)
    .forEach(rule => {
      const conditions = Array.isArray(rule.conditions) ? rule.conditions : [];
      for (let i = 0; i < conditions.length - 1; i += 1) {
        const left = conditions[i] || {};
        const right = conditions[i + 1] || {};
        const isAnd = String(left.query_operator || '').toLowerCase() === 'and';
        const sameKey = left.attribute_key === right.attribute_key;
        const equalityOps =
          EQUALITY_OPS.includes(left.filter_operator) &&
          EQUALITY_OPS.includes(right.filter_operator);

        if (isAnd && sameKey && equalityOps) {
          const leftVals = normalizeValues(left.values).map(v =>
            String(v).toLowerCase()
          );
          const rightVals = normalizeValues(right.values).map(v =>
            String(v).toLowerCase()
          );
          const disjoint =
            leftVals.length &&
            rightVals.length &&
            !leftVals.some(v => rightVals.includes(v));

          if (disjoint) {
            errors.push({
              rule_id: rule.id,
              code: 'impossible_and',
              message_key: 'BUSINESS_RULES.LINT.IMPOSSIBLE_AND',
              meta: { attribute_key: left.attribute_key },
            });
          }
        }
      }
    });
  return errors;
};

export const formatBusinessRuleLintErrors = (errors, t, rules = []) => {
  const list = Array.isArray(errors) ? errors : [];
  if (!list.length) return '';
  return list
    .map(err => {
      const rule = rules.find(r => String(r.id) === String(err.rule_id));
      const name = rule?.name || err.rule_id || '';
      const key =
        err.message_key ||
        `BUSINESS_RULES.LINT.${String(err.code || '').toUpperCase()}`;
      const detail = t(key, {
        ...(err.meta || {}),
        ruleName: name,
        attribute_key: err.meta?.attribute_key,
        category: err.meta?.category,
        status: err.meta?.status,
        other_rule_name: err.meta?.other_rule_name,
      });
      return name ? `${name}: ${detail}` : detail;
    })
    .join(' · ');
};
