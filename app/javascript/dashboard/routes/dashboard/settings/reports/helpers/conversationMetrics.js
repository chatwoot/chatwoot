// The three ways a report counts conversations, and what each one means for the
// dimension being read. "Conversations" is the trap: it counts conversations
// opened in the period by whoever holds them today, which for an agent says
// nothing about who handled them, so on an agent or team it is named after the
// assignment.
const HINTS = {
  resolved: { agent: 'RESOLVED_AGENT', default: 'RESOLVED' },
  handled: { agent: 'HANDLED_AGENT', default: 'HANDLED' },
  conversations: {
    agent: 'ASSIGNED_AGENT',
    team: 'ASSIGNED_TEAM',
    default: 'OPENED',
  },
};

export const metricHintKey = (metric, type) =>
  `REPORT.METRIC_HINTS.${HINTS[metric][type] ?? HINTS[metric].default}`;

// Assigned on an agent or team, opened anywhere else.
export const conversationsLabel = type =>
  ['agent', 'team'].includes(type) ? 'ASSIGNED' : 'OPENED';

// The summary table computes handled conversations per agent, inbox and team;
// labels go through a summary builder of their own that does not.
export const supportsHandled = type =>
  ['agent', 'inbox', 'team'].includes(type);
