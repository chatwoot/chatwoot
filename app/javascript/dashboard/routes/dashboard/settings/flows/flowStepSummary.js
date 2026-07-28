import { FLOW_ACTION_TYPES } from './constants';

export const filledButtons = step =>
  (step?.buttons || []).filter(b => (b.title || '').trim());

export const actionLabels = (step, flowActionTypes, t) => {
  const types = flowActionTypes?.length ? flowActionTypes : FLOW_ACTION_TYPES;
  return (step?.actions || []).map(action => {
    const meta = types.find(item => item.key === action.action_name);
    const translated =
      meta?.label ||
      (() => {
        const raw = FLOW_ACTION_TYPES.find(a => a.key === action.action_name);
        return raw ? t(`AUTOMATION.ACTIONS.${raw.label}`) : action.action_name;
      })();
    if (action.action_name === 'send_message') {
      const raw = Array.isArray(action.action_params)
        ? action.action_params[0]
        : action.action_params;
      if (typeof raw === 'string' && raw.trim()) {
        const preview = raw.trim().slice(0, 60);
        return `${translated}: "${preview}${raw.length > 60 ? '…' : ''}"`;
      }
    }
    return translated;
  });
};

export const targetLabel = (targetId, stepTargets, t) => {
  const found = (stepTargets || []).find(o => o.id === targetId);
  if (found) return found.label;
  if (targetId === 'end') return t('FLOWS.EDIT.PREVIEW_OUTCOME_END');
  if (targetId === 'handoff') return t('FLOWS.EDIT.PREVIEW_OUTCOME_HANDOFF');
  return t('FLOWS.EDIT.PREVIEW_OUTCOME_STEP', { label: targetId });
};

export const outcomeLines = (step, stepTargets, t) => {
  const buttons = filledButtons(step);
  if (buttons.length) {
    return buttons.map((btn, i) => {
      const btnIndex = step.buttons.indexOf(btn);
      const target = step.branches?.[btnIndex] || 'end';
      return t('FLOWS.EDIT.PREVIEW_BUTTON_N', {
        n: i + 1,
        button: btn.title,
        target: targetLabel(target, stepTargets, t),
      });
    });
  }
  const next = step.next || 'end';
  return [
    t('FLOWS.EDIT.PREVIEW_THEN_GO', {
      target: targetLabel(next, stepTargets, t),
    }),
  ];
};

export const stepHeadline = (step, index, t) => {
  const n = index + 1;
  const title = (step?.title || '').trim();
  if (title) return t('FLOWS.EDIT.OVERVIEW_STEP_NAMED', { n, title });
  return t('FLOWS.EDIT.STEP_N', { n });
};

export const summarizeSteps = (steps, stepTargets, flowActionTypes, t) =>
  (steps || []).map((step, index) => ({
    id: step.id,
    headline: stepHeadline(step, index, t),
    actions: actionLabels(step, flowActionTypes, t),
    waiting: filledButtons(step).length > 0,
    outcomes: outcomeLines(step, stepTargets, t),
  }));
