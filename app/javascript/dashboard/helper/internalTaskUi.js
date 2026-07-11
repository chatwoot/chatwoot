export const TASK_TAB_TYPE = {
  MINE: 'mine',
  UNCLAIMED: 'unclaimed',
  ALL: 'all',
};

export const TASK_STATUS_FILTER = {
  OPEN: 'open',
  COMPLETED: 'completed',
  ALL: 'all',
};

export const OPEN_TASK_STATUSES = [
  'pending',
  'in_progress',
  'blocked',
  'waiting_external',
];

export const ALL_TASK_STATUSES = [
  ...OPEN_TASK_STATUSES,
  'completed',
  'cancelled',
];

export const CLOSED_TASK_STATUSES = ['completed', 'cancelled'];

export const KANBAN_COLUMN = {
  UNASSIGNED: 'unassigned',
  PENDING: 'pending',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
};

export const KANBAN_COLUMNS = [
  KANBAN_COLUMN.UNASSIGNED,
  KANBAN_COLUMN.PENDING,
  KANBAN_COLUMN.IN_PROGRESS,
  KANBAN_COLUMN.COMPLETED,
];

export const kanbanColumnForTask = task => {
  if (CLOSED_TASK_STATUSES.includes(task.status)) {
    return KANBAN_COLUMN.COMPLETED;
  }
  if (!task.assignedToId) {
    return KANBAN_COLUMN.UNASSIGNED;
  }
  if (task.status === 'pending') {
    return KANBAN_COLUMN.PENDING;
  }
  return KANBAN_COLUMN.IN_PROGRESS;
};

export const groupTasksByKanbanColumn = tasks => {
  const groups = {
    [KANBAN_COLUMN.UNASSIGNED]: [],
    [KANBAN_COLUMN.PENDING]: [],
    [KANBAN_COLUMN.IN_PROGRESS]: [],
    [KANBAN_COLUMN.COMPLETED]: [],
  };
  tasks.forEach(task => {
    groups[kanbanColumnForTask(task)].push(task);
  });
  return groups;
};

export const TASK_STATUS = {
  pending: {
    icon: 'i-lucide-circle-dashed',
    badge: 'bg-n-slate-3 text-n-slate-12',
    dot: 'bg-n-slate-8',
  },
  in_progress: {
    icon: 'i-lucide-loader-circle',
    badge: 'bg-n-slate-3 text-n-slate-12',
    dot: 'bg-n-slate-9',
  },
  blocked: {
    icon: 'i-lucide-octagon-alert',
    badge: 'bg-n-slate-3 text-n-slate-12',
    dot: 'bg-n-slate-9',
  },
  waiting_external: {
    icon: 'i-lucide-hourglass',
    badge: 'bg-n-slate-3 text-n-slate-12',
    dot: 'bg-n-slate-8',
  },
  completed: {
    icon: 'i-lucide-circle-check',
    badge: 'bg-n-slate-3 text-n-slate-11',
    dot: 'bg-n-slate-7',
  },
  cancelled: {
    icon: 'i-lucide-circle-x',
    badge: 'bg-n-slate-3 text-n-slate-11',
    dot: 'bg-n-slate-6',
  },
};

export const TASK_PRIORITY = {
  normal: { badge: 'bg-n-slate-3 text-n-slate-11', label: 'Normal' },
  high: { badge: 'bg-n-slate-3 text-n-slate-12', label: 'High' },
  urgent: { badge: 'bg-n-slate-3 text-n-slate-12', label: 'Urgent' },
};

export const TEMPLATE_ICONS = {
  verify_payment: 'i-lucide-badge-dollar-sign',
  issue_invoice: 'i-lucide-file-text',
  prepare_order: 'i-lucide-package',
  ship_order: 'i-lucide-truck',
  call_customer: 'i-lucide-phone',
  other: 'i-lucide-list-plus',
};

export const templateIcon = key => TEMPLATE_ICONS[key] || TEMPLATE_ICONS.other;

export const statusConfig = status =>
  TASK_STATUS[status] || TASK_STATUS.pending;

export const priorityConfig = priority =>
  TASK_PRIORITY[priority] || TASK_PRIORITY.normal;

export const processSteps = task => [
  {
    key: 'created',
    done: true,
    active: task.status === 'pending' && !task.claimedAt,
  },
  {
    key: 'claimed',
    done: Boolean(task.claimedAt || task.assignedToId),
    active:
      task.status === 'pending' && Boolean(task.claimedAt || task.assignedToId),
  },
  {
    key: 'working',
    done:
      Boolean(task.startedAt) ||
      ['in_progress', 'blocked', 'waiting_external', 'completed'].includes(
        task.status
      ),
    active: ['in_progress', 'blocked', 'waiting_external'].includes(
      task.status
    ),
  },
  { key: 'done', done: task.status === 'completed', active: false },
];

export const taskContactLabel = task => {
  const name = task?.conversation?.contactName;
  const id = task?.conversation?.id;
  if (!name && !id) return '';
  return id ? `${name || '—'} · #${id}` : name;
};

export const taskAssigneeLabel = task => {
  if (task?.assignedTo?.name) return task.assignedTo.name;
  if (task?.team?.name) return task.team.name;
  return null;
};

export const taskListParams = (
  tab,
  teamId = null,
  statusFilter = TASK_STATUS_FILTER.OPEN
) => {
  const params = {};
  if (tab === TASK_TAB_TYPE.MINE) params.assigned_to = 'me';
  if (tab === TASK_TAB_TYPE.UNCLAIMED) params.unclaimed = true;
  if (teamId) params.team_id = teamId;

  if (statusFilter === TASK_STATUS_FILTER.COMPLETED) {
    params.status = CLOSED_TASK_STATUSES.join(',');
  } else if (statusFilter === TASK_STATUS_FILTER.ALL) {
    params.status = ALL_TASK_STATUSES.join(',');
  }

  return params;
};
