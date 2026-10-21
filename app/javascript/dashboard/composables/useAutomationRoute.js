import { watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';

export const AUTOMATION_QUERY = {
  MONITOR_ID: 'monitor_id',
  SLA_POLICY_ID: 'sla_policy_id',
  EDIT_ID: 'edit_id',
};

const parseId = value =>
  typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : null;

/**
 * Opens the automation page with a create or edit form, and lets the
 * automation page react to those links.
 */
export function useAutomationRoute() {
  const route = useRoute();
  const router = useRouter();
  const { accountScopedRoute } = useAccount();

  const pushAutomationList = query =>
    router.push(accountScopedRoute('automation_list', {}, query));

  const createAutomation = ({ monitorId, slaPolicyId } = {}) =>
    pushAutomationList({
      ...(monitorId && { [AUTOMATION_QUERY.MONITOR_ID]: monitorId }),
      ...(slaPolicyId && { [AUTOMATION_QUERY.SLA_POLICY_ID]: slaPolicyId }),
    });

  const editAutomation = ruleId =>
    pushAutomationList({ [AUTOMATION_QUERY.EDIT_ID]: ruleId });

  const clearQuery = keys =>
    router.replace({
      query: {
        ...route.query,
        ...Object.fromEntries(keys.map(key => [key, undefined])),
      },
    });

  /**
   * Calls `create` or `edit` when the route carries an automation query,
   * then removes the query. `edit` returns false while the rule is not loaded
   * yet, so the query is kept and retried when `rules` changes.
   */
  const onAutomationQuery = ({ create, edit, rules }) => {
    watch(
      () => [
        route.query[AUTOMATION_QUERY.MONITOR_ID],
        route.query[AUTOMATION_QUERY.SLA_POLICY_ID],
      ],
      async ([rawMonitorId, rawSlaPolicyId]) => {
        const monitorId = parseId(rawMonitorId);
        const slaPolicyId = parseId(rawSlaPolicyId);
        if (!monitorId && !slaPolicyId) return;
        await create({ monitorId, slaPolicyId });
        clearQuery([
          AUTOMATION_QUERY.MONITOR_ID,
          AUTOMATION_QUERY.SLA_POLICY_ID,
        ]);
      },
      { immediate: true }
    );

    watch(
      [() => route.query[AUTOMATION_QUERY.EDIT_ID], rules],
      async ([rawRuleId]) => {
        const ruleId = parseId(rawRuleId);
        if (!ruleId) return;
        if (!(await edit(ruleId))) return;
        clearQuery([AUTOMATION_QUERY.EDIT_ID]);
      },
      { immediate: true }
    );
  };

  return { createAutomation, editAutomation, onAutomationQuery };
}
