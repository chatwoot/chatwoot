import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';

export const AUTOMATION_QUERY = {
  MONITOR_ID: 'monitor_id',
  SLA_POLICY_ID: 'sla_policy_id',
  EDIT_ID: 'edit_id',
};

/**
 * Opens the automation page with a create or edit form.
 */
export function useAutomationRoute() {
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

  return { createAutomation, editAutomation };
}
