<script setup>
import { computed, onMounted, reactive, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import EmployeeAPI from 'dashboard/api/employees';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();
const isRTL = computed(() => getters['accounts/isRTL'].value);

const employees = ref([]);
const sessions = ref([]);
const loginHistory = ref([]);
const activityDetails = ref(null);
const isFetching = ref(false);
const isSaving = ref(false);
const selectedIds = ref([]);
const showFormModal = ref(false);
const showPasswordModal = ref(false);
const showDetailsModal = ref(false);
const showReasonModal = ref(false);
const showDeleteModal = ref(false);
const showNewPassword = ref(false);
const showNewPasswordConfirmation = ref(false);
const currentEmployee = ref(null);
const pendingAction = ref('');
const pendingEmployee = ref(null);
const pendingBulkIds = ref([]);
const lastUpdatedAt = ref(null);
const showAdvancedFilters = ref(false);
const expandedRowIds = ref([]);

const filters = reactive({
  q: '',
  role: '',
  status: '',
  presence_status: '',
  work_status: '',
  attention_status: '',
  team_id: '',
  has_open_conversations: '',
  has_unreplied_conversations: '',
  has_delayed_unreplied_conversations: '',
  has_response_today: '',
  oldest_waiting_over_target: '',
  offline_with_unreplied: '',
  high_workload: '',
  has_resolved_today: '',
  idle_more_than: '',
  last_reply_before: '',
  last_login: '',
  last_activity: '',
});

const activeFilterCard = ref(null);
const firstFieldRef = ref(null);
const openDropdownId = ref(null);

const toggleDropdown = id => {
  if (openDropdownId.value === id) {
    openDropdownId.value = null;
  } else {
    openDropdownId.value = id;
  }
};

const form = reactive({
  name: '',
  phone_number: '',
  username: '',
  role: 'agent',
  team_ids: [],
  job_title: '',
  employee_notes: '',
  active: true,
  deactivation_reason: '',
  password: '',
  password_confirmation: '',
});

const passwordForm = reactive({
  password: '',
  password_confirmation: '',
});

const reasonForm = reactive({
  reason: '',
});

const teams = computed(() => getters['teams/getTeams'].value || []);
const isEditing = computed(() => Boolean(currentEmployee.value?.id));
const metric = employee => employee.metrics || {};

const presenceStatus = employee =>
  metric(employee).presence_status || 'offline';

const workStatus = employee => {
  if (!employee.active || employee.archived_at) return null;
  if (presenceStatus(employee) === 'offline') return null;
  return metric(employee).work_status || null;
};

const onlineEmployees = computed(
  () =>
    employees.value.filter(employee => presenceStatus(employee) === 'online')
      .length
);
const offlineEmployees = computed(
  () =>
    employees.value.filter(employee => presenceStatus(employee) === 'offline')
      .length
);
const workingEmployees = computed(
  () =>
    employees.value.filter(employee => workStatus(employee) === 'working')
      .length
);
const idleEmployees = computed(
  () =>
    employees.value.filter(employee => workStatus(employee) === 'idle').length
);
const notRespondingEmployees = computed(
  () =>
    employees.value.filter(
      employee => workStatus(employee) === 'not_responding'
    ).length
);

const passwordScore = computed(() => {
  const password = isEditing.value ? passwordForm.password : form.password;
  let score = 0;
  if (password.length >= 8) score += 1;
  if (/[A-Z]/.test(password)) score += 1;
  if (/[a-z]/.test(password)) score += 1;
  if (/[0-9]/.test(password)) score += 1;
  if (/[^A-Za-z0-9]/.test(password)) score += 1;
  return score;
});

const passwordStrength = computed(() => {
  if (passwordScore.value >= 5) return 'strong';
  if (passwordScore.value >= 4) return 'medium';
  return 'weak';
});

const passwordStrengthLabel = computed(() => {
  if (passwordStrength.value === 'strong') {
    return t('EMPLOYEE_MGMT.PASSWORD.STRONG');
  }

  if (passwordStrength.value === 'medium') {
    return t('EMPLOYEE_MGMT.PASSWORD.MEDIUM');
  }

  return t('EMPLOYEE_MGMT.PASSWORD.WEAK');
});

const passwordStrengthClass = computed(() => {
  if (passwordStrength.value === 'strong') {
    return 'bg-n-teal-3 text-n-teal-11 border-n-teal-4';
  }

  if (passwordStrength.value === 'medium') {
    return 'bg-n-amber-3 text-n-amber-11 border-n-amber-4';
  }

  return 'bg-n-ruby-3 text-n-ruby-11 border-n-ruby-4';
});

const canSubmitPassword = computed(() => {
  const password = isEditing.value ? passwordForm.password : form.password;
  const confirmation = isEditing.value
    ? passwordForm.password_confirmation
    : form.password_confirmation;
  return passwordStrength.value !== 'weak' && password === confirmation;
});

const requiredFieldsPresent = computed(() => {
  const requiredFields = [
    form.name,
    form.phone_number,
    form.username,
    form.role,
  ];
  const hasPassword = isEditing.value || canSubmitPassword.value;
  return requiredFields.every(value => value?.toString().trim()) && hasPassword;
});

const saveDisabledReason = computed(() => {
  if (isSaving.value) return '';
  if (!form.name.trim()) return t('EMPLOYEE_MGMT.VALIDATION.NAME_REQUIRED');
  if (!form.phone_number.trim())
    return t('EMPLOYEE_MGMT.VALIDATION.PHONE_REQUIRED');
  if (!form.username.trim())
    return t('EMPLOYEE_MGMT.VALIDATION.USERNAME_REQUIRED');
  if (!isEditing.value && !canSubmitPassword.value) {
    return t('EMPLOYEE_MGMT.PASSWORD.WEAK_BLOCK');
  }
  return '';
});

const canSaveEmployee = computed(() => {
  return !isSaving.value && requiredFieldsPresent.value;
});

const resetForm = () => {
  Object.assign(form, {
    name: '',
    phone_number: '',
    username: '',
    role: 'agent',
    team_ids: [],
    job_title: '',
    employee_notes: '',
    active: true,
    deactivation_reason: '',
    password: '',
    password_confirmation: '',
  });
};

const formatDate = value => {
  return value ? new Date(value).toLocaleString() : t('EMPLOYEE_MGMT.EMPTY');
};

const formatDuration = seconds => {
  if (!Number(seconds)) return t('EMPLOYEE_MGMT.EMPTY');
  const minutes = Math.floor(Number(seconds) / 60);
  if (minutes < 1) return t('EMPLOYEE_MGMT.DURATION.LESS_THAN_MINUTE');
  if (minutes < 60)
    return t('EMPLOYEE_MGMT.DURATION.MINUTES', { count: minutes });
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return t('EMPLOYEE_MGMT.DURATION.HOURS', { count: hours });
  const days = Math.floor(hours / 24);
  return t('EMPLOYEE_MGMT.DURATION.DAYS', { count: days });
};

const formatSince = value => {
  if (!value) return t('EMPLOYEE_MGMT.EMPTY');
  return t('EMPLOYEE_MGMT.DURATION.AGO', {
    duration: formatDuration((Date.now() - new Date(value).getTime()) / 1000),
  });
};

const lastUpdatedLabel = computed(() => formatSince(lastUpdatedAt.value));

const roleLabel = role => {
  return role === 'administrator'
    ? t('EMPLOYEE_MGMT.ROLES.ADMINISTRATOR')
    : t('EMPLOYEE_MGMT.ROLES.AGENT');
};

const roleBadgeClass = role => {
  return role === 'administrator'
    ? 'bg-n-amber-3 text-n-amber-11 border-n-amber-4'
    : 'bg-n-slate-3 text-n-slate-11 border-n-slate-4';
};

const statusLabel = employee => {
  if (employee.archived_at) return t('EMPLOYEE_MGMT.STATUS.ARCHIVED');
  if (employee.active) return t('EMPLOYEE_MGMT.STATUS.ACTIVE');
  return t('EMPLOYEE_MGMT.STATUS.INACTIVE');
};

const statusBadgeClass = employee => {
  if (employee.archived_at) {
    return 'bg-n-slate-3 text-n-slate-11 border-n-slate-4';
  }

  if (employee.active) {
    return 'bg-n-teal-3 text-n-teal-11 border-n-teal-4';
  }

  return 'bg-n-ruby-3 text-n-ruby-11 border-n-ruby-4';
};

const employeeInitials = employee => {
  return (employee.name || employee.username || '?')
    .split(' ')
    .slice(0, 2)
    .map(part => part[0])
    .join('')
    .toUpperCase();
};

const presenceLabel = employee => {
  if (presenceStatus(employee) === 'online') {
    return t('EMPLOYEE_MGMT.PRESENCE.ONLINE');
  }
  return t('EMPLOYEE_MGMT.PRESENCE.OFFLINE');
};

const presenceDotClass = employee => {
  if (presenceStatus(employee) === 'online') return 'bg-n-teal-9';
  return 'bg-n-slate-8';
};

const presenceTooltip = employee => {
  if (presenceStatus(employee) === 'online') {
    return t('EMPLOYEE_MGMT.TOOLTIPS.PRESENCE_ONLINE');
  }
  return t('EMPLOYEE_MGMT.TOOLTIPS.PRESENCE_OFFLINE');
};

const workStatusLabel = employee => {
  const status = workStatus(employee);
  if (status === 'working') return t('EMPLOYEE_MGMT.WORK_STATUS.WORKING');
  if (status === 'idle') return t('EMPLOYEE_MGMT.WORK_STATUS.IDLE');
  if (status === 'not_responding') {
    return t('EMPLOYEE_MGMT.WORK_STATUS.NOT_RESPONDING');
  }
  return t('EMPLOYEE_MGMT.EMPTY_STATUS');
};

const workStatusBadgeClass = employee => {
  const status = workStatus(employee);
  if (status === 'working') {
    return 'rounded-full border border-solid bg-n-teal-3 text-n-teal-11 border-n-teal-4';
  }
  if (status === 'idle') {
    return 'rounded-full border border-solid bg-n-amber-3 text-n-amber-11 border-n-amber-4';
  }
  if (status === 'not_responding') {
    return 'rounded-full border border-solid bg-n-ruby-3 text-n-ruby-11 border-n-ruby-4';
  }
  return 'text-n-slate-9';
};

const workStatusTooltip = employee => {
  const status = workStatus(employee);
  const tooltips = {
    working: t('EMPLOYEE_MGMT.TOOLTIPS.ACTIVITY_WORKING'),
    idle: t('EMPLOYEE_MGMT.TOOLTIPS.ACTIVITY_IDLE'),
    not_responding: t('EMPLOYEE_MGMT.TOOLTIPS.ACTIVITY_NOT_RESPONDING'),
  };
  return tooltips[status] || t('EMPLOYEE_MGMT.TOOLTIPS.ACTIVITY_EMPTY');
};

const attentionStatus = employee => {
  const employeeMetric = metric(employee);
  const delayedCount = Number(
    employeeMetric.delayed_unreplied_conversations_count
  );
  const unrepliedCount = Number(employeeMetric.unreplied_conversations_count);
  const oldestWaitingSeconds = Number(
    employeeMetric.oldest_waiting_customer_seconds
  );

  if (!employee.active || employee.archived_at) return null;
  if (delayedCount > 0 || oldestWaitingSeconds >= 20 * 60) {
    return 'critical';
  }
  if (presenceStatus(employee) === 'offline') {
    return unrepliedCount > 0 ? 'critical' : null;
  }
  if (
    workStatus(employee) === 'not_responding' ||
    unrepliedCount > 0 ||
    oldestWaitingSeconds >= 10 * 60
  ) {
    return 'at_risk';
  }
  if (workStatus(employee) === 'idle') return 'watch';
  return 'healthy';
};

const attentionReason = employee => {
  const employeeMetric = metric(employee);
  const delayedCount = Number(
    employeeMetric.delayed_unreplied_conversations_count
  );
  const unrepliedCount = Number(employeeMetric.unreplied_conversations_count);
  const openCount = Number(employeeMetric.open_conversations_count);
  const oldestWaitingSeconds = Number(
    employeeMetric.oldest_waiting_customer_seconds
  );
  const isOffline = presenceStatus(employee) === 'offline';

  if (isOffline && unrepliedCount > 0) {
    return t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_CRITICAL_OFFLINE_UNREPLIED', {
      count: unrepliedCount,
    });
  }

  if (delayedCount > 0) {
    return t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_CRITICAL_DELAYED', {
      count: delayedCount,
    });
  }

  if (oldestWaitingSeconds >= 20 * 60) {
    return t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_CRITICAL_WAITING', {
      duration: formatDuration(oldestWaitingSeconds),
    });
  }

  if (openCount > 0 || unrepliedCount > 0) {
    return t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_WORKLOAD', {
      open: openCount,
      unreplied: unrepliedCount,
    });
  }

  return '';
};

const attentionLabel = employee => {
  const labels = {
    healthy: t('EMPLOYEE_MGMT.HEALTH.HEALTHY'),
    watch: t('EMPLOYEE_MGMT.HEALTH.WATCH'),
    at_risk: t('EMPLOYEE_MGMT.HEALTH.AT_RISK'),
    critical: t('EMPLOYEE_MGMT.HEALTH.CRITICAL'),
  };
  return labels[attentionStatus(employee)] || t('EMPLOYEE_MGMT.EMPTY_STATUS');
};

const attentionBadgeClass = employee => {
  const classes = {
    healthy:
      'rounded-md border border-solid bg-n-teal-2 text-n-teal-11 border-n-teal-5',
    watch:
      'rounded-md border border-solid bg-n-blue-2 text-n-blue-11 border-n-blue-5',
    at_risk:
      'rounded-md border border-solid bg-n-amber-2 text-n-amber-11 border-n-amber-5',
    critical:
      'rounded-md border border-solid bg-n-ruby-2 text-n-ruby-11 border-n-ruby-5',
  };
  return classes[attentionStatus(employee)] || 'text-n-slate-9';
};

const attentionTooltip = employee => {
  if (attentionStatus(employee) === 'critical') {
    return attentionReason(employee);
  }

  const tooltips = {
    healthy: t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_HEALTHY'),
    watch: t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_WATCH'),
    at_risk: t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_AT_RISK'),
    critical: t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_CRITICAL'),
  };
  return (
    tooltips[attentionStatus(employee)] ||
    t('EMPLOYEE_MGMT.TOOLTIPS.ATTENTION_EMPTY')
  );
};

const waitingTextClass = seconds => {
  if (Number(seconds) >= 20 * 60) return 'text-n-ruby-11';
  if (Number(seconds) >= 10 * 60) return 'text-n-amber-11';
  return 'text-n-slate-11';
};

const toggleRowDetails = employeeId => {
  if (expandedRowIds.value.includes(employeeId)) {
    expandedRowIds.value = expandedRowIds.value.filter(id => id !== employeeId);
  } else {
    expandedRowIds.value = [...expandedRowIds.value, employeeId];
  }
};

const isRowExpanded = employeeId => expandedRowIds.value.includes(employeeId);

const timelineLabel = event => {
  const conversationId = event.metadata?.conversation_display_id;
  if (event.event_type === 'logged_in') {
    return t('EMPLOYEE_MGMT.TIMELINE.LOGGED_IN');
  }
  if (event.event_type === 'reply') {
    return t('EMPLOYEE_MGMT.TIMELINE.REPLIED', { id: conversationId });
  }
  if (event.event_type === 'resolved') {
    return t('EMPLOYEE_MGMT.TIMELINE.RESOLVED', { id: conversationId });
  }
  if (event.event_type === 'idle') {
    return t('EMPLOYEE_MGMT.TIMELINE.IDLE', {
      duration: formatDuration(event.metadata?.idle_duration),
    });
  }
  if (event.event_type === 'not_responding') {
    return t('EMPLOYEE_MGMT.TIMELINE.NOT_RESPONDING', {
      duration: formatDuration(event.metadata?.waiting_seconds),
    });
  }
  return t('EMPLOYEE_MGMT.TIMELINE.ACTIVITY');
};

const conversationLabel = conversation => {
  return t('EMPLOYEE_MGMT.DETAILS.CONVERSATION', {
    id: conversation.display_id,
  });
};

const isHighWorkload = employee =>
  Number(metric(employee).open_conversations_count) >= 10 ||
  Number(metric(employee).unreplied_conversations_count) >= 5;

const summaryCards = computed(() => [
  {
    key: 'online',
    label: t('EMPLOYEE_MGMT.SUMMARY.ONLINE'),
    subtitle: t('EMPLOYEE_MGMT.SUMMARY.SUBTITLES.ONLINE'),
    value: onlineEmployees.value,
    icon: 'i-lucide-wifi',
    tone: 'teal',
    metricLabel: t('EMPLOYEE_MGMT.SUMMARY.METRICS.AGENTS'),
    filters: { presence_status: 'online' },
  },
  {
    key: 'offline',
    label: t('EMPLOYEE_MGMT.SUMMARY.OFFLINE'),
    subtitle: t('EMPLOYEE_MGMT.SUMMARY.SUBTITLES.OFFLINE'),
    value: offlineEmployees.value,
    icon: 'i-lucide-wifi-off',
    tone: 'slate',
    metricLabel: t('EMPLOYEE_MGMT.SUMMARY.METRICS.AGENTS'),
    filters: { presence_status: 'offline' },
  },
  {
    key: 'working',
    label: t('EMPLOYEE_MGMT.SUMMARY.WORKING'),
    subtitle: t('EMPLOYEE_MGMT.SUMMARY.SUBTITLES.WORKING'),
    value: workingEmployees.value,
    icon: 'i-lucide-activity',
    tone: 'teal',
    metricLabel: t('EMPLOYEE_MGMT.SUMMARY.METRICS.AGENTS'),
    filters: { work_status: 'working' },
  },
  {
    key: 'idle',
    label: t('EMPLOYEE_MGMT.SUMMARY.IDLE'),
    subtitle: t('EMPLOYEE_MGMT.SUMMARY.SUBTITLES.IDLE'),
    value: idleEmployees.value,
    icon: 'i-lucide-clock-3',
    tone: 'amber',
    metricLabel: t('EMPLOYEE_MGMT.SUMMARY.METRICS.AGENTS'),
    filters: { work_status: 'idle' },
  },
  {
    key: 'not_responding',
    label: t('EMPLOYEE_MGMT.SUMMARY.NOT_RESPONDING'),
    subtitle: t('EMPLOYEE_MGMT.SUMMARY.SUBTITLES.NOT_RESPONDING'),
    value: notRespondingEmployees.value,
    icon: 'i-lucide-message-circle-warning',
    tone: 'ruby',
    metricLabel: t('EMPLOYEE_MGMT.SUMMARY.METRICS.AGENTS'),
    filters: { work_status: 'not_responding' },
  },
]);

const toneFillClass = tone => {
  const classes = {
    teal: 'bg-n-teal-8',
    ruby: 'bg-n-ruby-8',
    amber: 'bg-n-amber-8',
    blue: 'bg-n-blue-8',
    slate: 'bg-n-slate-8',
  };
  return classes[tone] || classes.slate;
};

const toneTextClass = tone => {
  const classes = {
    teal: 'text-n-teal-11',
    ruby: 'text-n-ruby-11',
    amber: 'text-n-amber-11',
    blue: 'text-n-blue-11',
    slate: 'text-n-slate-12',
  };
  return classes[tone] || classes.slate;
};

const summaryValueClass = card =>
  card.tone === 'slate' ? 'text-n-slate-12' : toneTextClass(card.tone);

const summaryIconMotionClass = card => {
  if (activeFilterCard.value === card.key) return 'scale-110 shadow-md';
  if (['ruby', 'amber'].includes(card.tone)) return 'animate-pulse';
  return 'group-hover:scale-110';
};

const summaryLiveDotClass = card => `${toneFillClass(card.tone)} animate-pulse`;

const summaryCardClass = card => {
  if (activeFilterCard.value === card.key) {
    return 'ring-2 ring-n-brand-7 border-n-brand-7 bg-n-brand-2 shadow-md shadow-n-brand-4/30 dark:bg-n-brand-3';
  }

  const classes = {
    teal: 'hover:border-n-teal-6 hover:bg-n-teal-2/30 hover:shadow-xl hover:shadow-n-teal-3/30 hover:-translate-y-0.5',
    ruby: 'hover:border-n-ruby-6 hover:bg-n-ruby-2/30 hover:shadow-xl hover:shadow-n-ruby-3/30 hover:-translate-y-0.5',
    amber:
      'hover:border-n-amber-6 hover:bg-n-amber-2/30 hover:shadow-xl hover:shadow-n-amber-3/30 hover:-translate-y-0.5',
    blue: 'hover:border-n-blue-6 hover:bg-n-blue-2/30 hover:shadow-xl hover:shadow-n-blue-3/30 hover:-translate-y-0.5',
    slate:
      'hover:border-n-slate-6 hover:bg-n-slate-2/50 hover:shadow-xl hover:-translate-y-0.5',
  };
  return `border-n-weak bg-n-solid-1 text-n-slate-12 shadow-sm dark:bg-n-solid-2 ${classes[card.tone]}`;
};

const summaryIconClass = card => {
  const classes = {
    teal: 'bg-n-teal-3 text-n-teal-11 ring-n-teal-5/30',
    ruby: 'bg-n-ruby-3 text-n-ruby-11 ring-n-ruby-5/30',
    amber: 'bg-n-amber-3 text-n-amber-11 ring-n-amber-5/30',
    blue: 'bg-n-blue-3 text-n-blue-11 ring-n-blue-5/30',
    slate: 'bg-n-slate-3 text-n-slate-11 ring-n-slate-5/30',
  };
  return classes[card.tone] || classes.slate;
};

const accentBarClass = card => {
  const classes = {
    teal: 'bg-n-teal-6',
    ruby: 'bg-n-ruby-6',
    amber: 'bg-n-amber-6',
    blue: 'bg-n-blue-6',
    slate: 'bg-n-slate-6',
  };
  return classes[card.tone] || classes.slate;
};

const detailMetricCards = computed(() => {
  const metrics = activityDetails.value?.metrics;
  if (!metrics) return [];

  return [
    {
      key: 'open',
      label: t('EMPLOYEE_MGMT.TABLE.OPEN_CONVERSATIONS'),
      value: metrics.open_conversations_count || 0,
      icon: 'i-lucide-inbox',
      tone: 'slate',
    },
    {
      key: 'unreplied',
      label: t('EMPLOYEE_MGMT.TABLE.UNREPLIED'),
      value: metrics.unreplied_conversations_count || 0,
      icon: 'i-lucide-message-square-warning',
      tone: metrics.unreplied_conversations_count ? 'ruby' : 'slate',
    },
    {
      key: 'delayed',
      label: t('EMPLOYEE_MGMT.DETAILS.DELAYED'),
      value: metrics.delayed_unreplied_conversations_count || 0,
      icon: 'i-lucide-hourglass',
      tone: metrics.delayed_unreplied_conversations_count ? 'ruby' : 'slate',
    },
    {
      key: 'oldest_waiting',
      label: t('EMPLOYEE_MGMT.TABLE.OLDEST_WAITING'),
      value: formatDuration(metrics.oldest_waiting_customer_seconds),
      icon: 'i-lucide-clock-3',
      tone: metrics.oldest_waiting_customer_seconds ? 'amber' : 'slate',
    },
    {
      key: 'replies_today',
      label: t('EMPLOYEE_MGMT.TABLE.REPLIES_TODAY'),
      value: metrics.replies_count_today || 0,
      icon: 'i-lucide-send',
      tone: 'blue',
    },
    {
      key: 'resolved_today',
      label: t('EMPLOYEE_MGMT.TABLE.RESOLVED_TODAY'),
      value: metrics.resolved_conversations_today || 0,
      icon: 'i-lucide-check-check',
      tone: 'teal',
    },
  ];
});

const detailMetricCardClass = card => {
  const classes = {
    teal: 'hover:border-n-teal-6 hover:bg-n-teal-2/30 hover:shadow-n-teal-3/30',
    ruby: 'hover:border-n-ruby-6 hover:bg-n-ruby-2/30 hover:shadow-n-ruby-3/30',
    amber:
      'hover:border-n-amber-6 hover:bg-n-amber-2/30 hover:shadow-n-amber-3/30',
    blue: 'hover:border-n-blue-6 hover:bg-n-blue-2/30 hover:shadow-n-blue-3/30',
    slate: 'hover:border-n-slate-6 hover:bg-n-slate-2/50',
  };
  return classes[card.tone] || classes.slate;
};

const detailMetricIconClass = card => summaryIconClass(card);
const detailMetricValueClass = card => summaryValueClass(card);

const filterLabel = (key, value) => {
  const statusLabels = {
    active: t('EMPLOYEE_MGMT.STATUS.ACTIVE'),
    inactive: t('EMPLOYEE_MGMT.STATUS.INACTIVE'),
    archived: t('EMPLOYEE_MGMT.STATUS.ARCHIVED'),
  };
  const presenceLabels = {
    online: t('EMPLOYEE_MGMT.PRESENCE.ONLINE'),
    offline: t('EMPLOYEE_MGMT.PRESENCE.OFFLINE'),
  };
  const workStatusLabels = {
    working: t('EMPLOYEE_MGMT.WORK_STATUS.WORKING'),
    idle: t('EMPLOYEE_MGMT.WORK_STATUS.IDLE'),
    not_responding: t('EMPLOYEE_MGMT.WORK_STATUS.NOT_RESPONDING'),
  };
  const attentionLabels = {
    healthy: t('EMPLOYEE_MGMT.HEALTH.HEALTHY'),
    watch: t('EMPLOYEE_MGMT.HEALTH.WATCH'),
    at_risk: t('EMPLOYEE_MGMT.HEALTH.AT_RISK'),
    critical: t('EMPLOYEE_MGMT.HEALTH.CRITICAL'),
  };
  const dateLabels = {
    '7_days': t('EMPLOYEE_MGMT.FILTERS.OPTIONS.7_DAYS'),
    '30_days': t('EMPLOYEE_MGMT.FILTERS.OPTIONS.30_DAYS'),
    never: t('EMPLOYEE_MGMT.FILTERS.OPTIONS.NEVER'),
  };
  const labels = {
    role:
      value === 'administrator'
        ? roleLabel('administrator')
        : roleLabel('agent'),
    status: statusLabels[value],
    presence_status: presenceLabels[value],
    work_status: workStatusLabels[value],
    attention_status: attentionLabels[value],
    team_id: teams.value.find(team => team.id.toString() === value.toString())
      ?.name,
    last_login: dateLabels[value],
    last_activity: dateLabels[value],
    idle_more_than: t('EMPLOYEE_MGMT.FILTERS.IDLE_CHIP', { count: value }),
    last_reply_before: t('EMPLOYEE_MGMT.FILTERS.REPLY_CHIP', { count: value }),
    has_open_conversations: t('EMPLOYEE_MGMT.FILTERS.HAS_OPEN'),
    has_unreplied_conversations: t('EMPLOYEE_MGMT.FILTERS.HAS_UNREPLIED'),
    has_delayed_unreplied_conversations: t('EMPLOYEE_MGMT.FILTERS.HAS_DELAYED'),
    has_response_today: t('EMPLOYEE_MGMT.FILTERS.HAS_RESPONSE_TODAY'),
    oldest_waiting_over_target: t(
      'EMPLOYEE_MGMT.FILTERS.OLDEST_WAITING_OVER_TARGET'
    ),
    offline_with_unreplied: t('EMPLOYEE_MGMT.SUMMARY.OFFLINE_UNREPLIED'),
    high_workload: t('EMPLOYEE_MGMT.SUMMARY.HIGH_WORKLOAD'),
    has_resolved_today: t('EMPLOYEE_MGMT.SUMMARY.RESOLVED_TODAY'),
  };
  return labels[key] || value;
};

const activeFilterChips = computed(() =>
  Object.entries(filters)
    .filter(([, value]) => value)
    .map(([key, value]) => ({
      key,
      label: key === 'q' ? value : filterLabel(key, value),
    }))
);

const attentionSortRank = employee => {
  const ranks = {
    critical: 0,
    at_risk: 1,
    watch: 2,
    healthy: 3,
  };
  return ranks[attentionStatus(employee)] ?? 4;
};

const sortedByAttention = employeeList =>
  [...employeeList].sort((a, b) => {
    const rankDifference = attentionSortRank(a) - attentionSortRank(b);
    if (rankDifference) return rankDifference;

    const unrepliedDifference =
      Number(metric(b).unreplied_conversations_count) -
      Number(metric(a).unreplied_conversations_count);
    if (unrepliedDifference) return unrepliedDifference;

    return (
      Number(metric(b).open_conversations_count) -
      Number(metric(a).open_conversations_count)
    );
  });

const filteredEmployees = computed(() => {
  let result = employees.value;

  if (filters.q) {
    const query = filters.q.toLowerCase();
    result = result.filter(
      e =>
        (e.name || '').toLowerCase().includes(query) ||
        (e.phone_number || '').toLowerCase().includes(query) ||
        (e.username || '').toLowerCase().includes(query)
    );
  }

  if (filters.role) {
    result = result.filter(e => e.role === filters.role);
  }

  if (filters.status) {
    if (filters.status === 'archived') {
      result = result.filter(e => !!e.archived_at);
    } else if (filters.status === 'active') {
      result = result.filter(e => e.active && !e.archived_at);
    } else if (filters.status === 'inactive') {
      result = result.filter(e => !e.active && !e.archived_at);
    }
  }

  if (filters.presence_status) {
    result = result.filter(e => presenceStatus(e) === filters.presence_status);
  }

  if (filters.work_status) {
    result = result.filter(e => workStatus(e) === filters.work_status);
  }

  if (filters.attention_status) {
    result = result.filter(
      e => attentionStatus(e) === filters.attention_status
    );
  }

  if (filters.team_id) {
    result = result.filter(e =>
      e.team_ids?.map(id => id.toString()).includes(filters.team_id.toString())
    );
  }

  if (filters.has_open_conversations) {
    result = result.filter(e => metric(e).open_conversations_count > 0);
  }

  if (filters.has_unreplied_conversations) {
    result = result.filter(e => metric(e).unreplied_conversations_count > 0);
  }

  if (filters.has_delayed_unreplied_conversations) {
    result = result.filter(
      e => Number(metric(e).delayed_unreplied_conversations_count) > 0
    );
  }

  if (filters.has_response_today) {
    result = result.filter(
      e => Number(metric(e).average_response_time_today) > 0
    );
  }

  if (filters.oldest_waiting_over_target) {
    result = result.filter(
      e => Number(metric(e).oldest_waiting_customer_seconds) >= 20 * 60
    );
  }

  if (filters.offline_with_unreplied) {
    result = result.filter(
      e =>
        presenceStatus(e) === 'offline' &&
        Number(metric(e).unreplied_conversations_count) > 0
    );
  }

  if (filters.high_workload) {
    result = result.filter(e => isHighWorkload(e));
  }

  if (filters.has_resolved_today) {
    result = result.filter(e => metric(e).resolved_conversations_today > 0);
  }

  if (filters.idle_more_than) {
    const thresholdSeconds = Number(filters.idle_more_than) * 60;
    result = result.filter(
      e => Number(metric(e).idle_duration) >= thresholdSeconds
    );
  }

  if (filters.last_reply_before) {
    const now = Date.now();
    const threshold = Number(filters.last_reply_before) * 60 * 1000;
    result = result.filter(e => {
      const lastReplyAt = metric(e).last_reply_at;
      return lastReplyAt && now - new Date(lastReplyAt).getTime() >= threshold;
    });
  }

  if (filters.last_login) {
    const now = Date.now();
    result = result.filter(e => {
      const loginTime = e.current_sign_in_at || e.last_sign_in_at;
      if (filters.last_login === 'never') return !loginTime;
      if (!loginTime) return false;
      const days = (now - new Date(loginTime).getTime()) / (1000 * 3600 * 24);
      if (filters.last_login === '7_days') return days <= 7;
      if (filters.last_login === '30_days') return days <= 30;
      return true;
    });
  }

  if (filters.last_activity) {
    const now = Date.now();
    result = result.filter(e => {
      const activityTime = metric(e).last_activity_at || e.last_activity_at;
      if (filters.last_activity === 'never') return !activityTime;
      if (!activityTime) return false;
      const days =
        (now - new Date(activityTime).getTime()) / (1000 * 3600 * 24);
      if (filters.last_activity === '7_days') return days <= 7;
      if (filters.last_activity === '30_days') return days <= 30;
      return true;
    });
  }

  return sortedByAttention(result);
});

const allSelected = computed(
  () =>
    filteredEmployees.value.length > 0 &&
    selectedIds.value.length === filteredEmployees.value.length
);

const tableEmpty = computed(
  () =>
    !isFetching.value &&
    employees.value.length > 0 &&
    !filteredEmployees.value.length
);

const employeeTeams = employee => {
  return employee.teams.length
    ? employee.teams
    : [{ id: 'empty', name: t('EMPLOYEE_MGMT.EMPTY') }];
};

const toggleTeam = teamId => {
  if (form.team_ids.includes(teamId)) {
    form.team_ids = form.team_ids.filter(id => id !== teamId);
  } else {
    form.team_ids = [...form.team_ids, teamId];
  }
};

const isTeamSelected = teamId => form.team_ids.includes(teamId);

const showMessage = message => {
  useAlert(message);
};

const fetchEmployees = async () => {
  isFetching.value = true;
  try {
    const response = await EmployeeAPI.list({ local_only: false });
    employees.value = response.data;
    lastUpdatedAt.value = new Date().toISOString();
  } catch (error) {
    showMessage(t('EMPLOYEE_MGMT.API.ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const clearFilters = () => {
  activeFilterCard.value = null;
  selectedIds.value = [];
  Object.assign(filters, {
    q: '',
    role: '',
    status: '',
    presence_status: '',
    work_status: '',
    attention_status: '',
    team_id: '',
    has_open_conversations: '',
    has_unreplied_conversations: '',
    has_delayed_unreplied_conversations: '',
    has_response_today: '',
    oldest_waiting_over_target: '',
    offline_with_unreplied: '',
    high_workload: '',
    has_resolved_today: '',
    idle_more_than: '',
    last_reply_before: '',
    last_login: '',
    last_activity: '',
  });
};

const clearFilter = key => {
  filters[key] = '';
  if (activeFilterCard.value) activeFilterCard.value = null;
};

const applyFilters = () => {
  selectedIds.value = selectedIds.value.filter(id =>
    filteredEmployees.value.some(employee => employee.id === id)
  );
  fetchEmployees();
};

const applyCardFilter = card => {
  if (activeFilterCard.value === card.key) {
    clearFilters();
  } else {
    clearFilters();
    activeFilterCard.value = card.key;
    Object.assign(filters, card.filters);
  }
  selectedIds.value = [];
};

const openCreateModal = () => {
  currentEmployee.value = null;
  resetForm();
  showNewPassword.value = false;
  showNewPasswordConfirmation.value = false;
  showFormModal.value = true;
  nextTick(() => {
    setTimeout(() => {
      if (firstFieldRef.value) firstFieldRef.value.focus();
    }, 100);
  });
};

const openEditModal = employee => {
  currentEmployee.value = employee;
  Object.assign(form, {
    name: employee.name || '',
    phone_number: employee.phone_number || '',
    username: employee.username || '',
    role: employee.role || 'agent',
    team_ids: employee.team_ids || [],
    job_title: employee.job_title || '',
    employee_notes: employee.employee_notes || '',
    active: employee.active,
    deactivation_reason: employee.deactivation_reason || '',
    password: '',
    password_confirmation: '',
  });
  showNewPassword.value = false;
  showNewPasswordConfirmation.value = false;
  showFormModal.value = true;
  nextTick(() => {
    setTimeout(() => {
      if (firstFieldRef.value) firstFieldRef.value.focus();
    }, 100);
  });
};

const errorMessage = error => {
  return (
    error?.response?.data?.message ||
    error?.response?.data?.error ||
    error?.response?.data?.errors?.join(', ') ||
    t('EMPLOYEE_MGMT.API.ERROR')
  );
};

const saveEmployee = async () => {
  if (!isEditing.value && !canSubmitPassword.value) {
    showMessage(t('EMPLOYEE_MGMT.PASSWORD.WEAK_BLOCK'));
    return;
  }

  isSaving.value = true;
  try {
    const payload = { employee: { ...form } };
    if (isEditing.value) {
      delete payload.employee.password;
      delete payload.employee.password_confirmation;
      const response = await EmployeeAPI.update(
        currentEmployee.value.id,
        payload
      );
      const index = employees.value.findIndex(
        item => item.id === response.data.id
      );
      employees.value.splice(index, 1, response.data);
      showMessage(t('EMPLOYEE_MGMT.API.UPDATED'));
    } else {
      const response = await EmployeeAPI.create(payload);
      employees.value.unshift(response.data);
      showMessage(t('EMPLOYEE_MGMT.API.CREATED'));
    }
    showFormModal.value = false;
  } catch (error) {
    showMessage(errorMessage(error));
  } finally {
    isSaving.value = false;
  }
};

const openPasswordModal = employee => {
  currentEmployee.value = employee;
  Object.assign(passwordForm, { password: '', password_confirmation: '' });
  showNewPassword.value = false;
  showNewPasswordConfirmation.value = false;
  showPasswordModal.value = true;
};

const changePassword = async () => {
  if (!canSubmitPassword.value) {
    showMessage(t('EMPLOYEE_MGMT.PASSWORD.WEAK_BLOCK'));
    return;
  }

  isSaving.value = true;
  try {
    await EmployeeAPI.changePassword(currentEmployee.value.id, passwordForm);
    showPasswordModal.value = false;
    showMessage(t('EMPLOYEE_MGMT.API.PASSWORD_CHANGED'));
  } catch (error) {
    showMessage(errorMessage(error));
  } finally {
    isSaving.value = false;
  }
};

const refreshEmployee = async employeeId => {
  const response = await EmployeeAPI.show(employeeId);
  const index = employees.value.findIndex(item => item.id === response.data.id);
  employees.value.splice(index, 1, response.data);
  currentEmployee.value = response.data;
};

const openReasonModal = ({ actionType, employee = null, userIds = [] }) => {
  pendingAction.value = actionType;
  pendingEmployee.value = employee;
  pendingBulkIds.value = userIds;
  reasonForm.reason = '';
  showReasonModal.value = true;
};

const deactivateEmployee = async employee => {
  openReasonModal({ actionType: 'deactivate', employee });
};

const activateEmployee = async employee => {
  await EmployeeAPI.activate(employee.id);
  await refreshEmployee(employee.id);
  showMessage(t('EMPLOYEE_MGMT.API.ACTIVATED'));
};

const archiveEmployee = async employee => {
  openReasonModal({ actionType: 'archive', employee });
};

const deleteEmployee = async employee => {
  pendingEmployee.value = employee;
  showDeleteModal.value = true;
};

const openDetails = async employee => {
  currentEmployee.value = employee;
  activityDetails.value = null;
  showDetailsModal.value = true;
  const [sessionResponse, historyResponse, activityResponse] =
    await Promise.all([
      EmployeeAPI.sessions(employee.id),
      EmployeeAPI.loginHistory(employee.id),
      EmployeeAPI.activity(employee.id),
    ]);
  sessions.value = sessionResponse.data;
  loginHistory.value = historyResponse.data;
  activityDetails.value = activityResponse.data;
};

const logoutSession = async session => {
  await EmployeeAPI.deleteSession(currentEmployee.value.id, session.client_id);
  sessions.value = sessions.value.map(item =>
    item.client_id === session.client_id
      ? { ...item, open: false, signed_out_at: new Date().toISOString() }
      : item
  );
  showMessage(t('EMPLOYEE_MGMT.API.SESSION_LOGOUT'));
};

const toggleSelectAll = () => {
  selectedIds.value = allSelected.value
    ? []
    : filteredEmployees.value.map(employee => employee.id);
};

const bulkAction = async actionType => {
  if (!selectedIds.value.length) return;
  if (actionType !== 'activate') {
    openReasonModal({
      actionType: `bulk_${actionType}`,
      userIds: [...selectedIds.value],
    });
    return;
  }

  await EmployeeAPI.bulkUpdate({
    user_ids: selectedIds.value,
    action_type: actionType,
    deactivation_reason: '',
  });
  selectedIds.value = [];
  await fetchEmployees();
  showMessage(t('EMPLOYEE_MGMT.API.BULK_UPDATED'));
};

const confirmReasonAction = async () => {
  const deactivationReason = reasonForm.reason;
  const employee = pendingEmployee.value;

  if (pendingAction.value === 'deactivate') {
    await EmployeeAPI.deactivate(employee.id, {
      deactivation_reason: deactivationReason,
    });
    await refreshEmployee(employee.id);
    showMessage(t('EMPLOYEE_MGMT.API.DEACTIVATED'));
  } else if (pendingAction.value === 'archive') {
    await EmployeeAPI.archive(employee.id, {
      deactivation_reason: deactivationReason,
    });
    await refreshEmployee(employee.id);
    showMessage(t('EMPLOYEE_MGMT.API.ARCHIVED'));
  } else {
    const actionType = pendingAction.value.replace('bulk_', '');
    await EmployeeAPI.bulkUpdate({
      user_ids: pendingBulkIds.value,
      action_type: actionType,
      deactivation_reason: deactivationReason,
    });
    selectedIds.value = [];
    await fetchEmployees();
    showMessage(t('EMPLOYEE_MGMT.API.BULK_UPDATED'));
  }

  showReasonModal.value = false;
};

const confirmDeleteEmployee = async () => {
  await EmployeeAPI.delete(pendingEmployee.value.id);
  employees.value = employees.value.filter(
    item => item.id !== pendingEmployee.value.id
  );
  showDeleteModal.value = false;
  showMessage(t('EMPLOYEE_MGMT.API.DELETED'));
};

const handleEmployeeAction = (employee, action) => {
  openDropdownId.value = null;
  if (!action) return;
  if (action === 'edit') openEditModal(employee);
  if (action === 'password') openPasswordModal(employee);
  if (action === 'activate') activateEmployee(employee);
  if (action === 'deactivate') deactivateEmployee(employee);
  if (action === 'activity') openDetails(employee);
  if (action === 'archive') archiveEmployee(employee);
  if (action === 'delete') deleteEmployee(employee);
};

onMounted(() => {
  fetchEmployees();
  store.dispatch('teams/get');
});
</script>

<template>
  <SettingsLayout
    class="gap-5"
    :is-loading="isFetching"
    :loading-message="$t('EMPLOYEE_MGMT.LOADING')"
    :no-records-found="!employees.length"
    :no-records-message="$t('EMPLOYEE_MGMT.EMPTY_STATE')"
  >
    <template #header>
      <div
        class="flex w-full items-center justify-between rounded-xl border border-solid border-n-weak bg-n-solid-1 px-4 py-3 shadow-sm dark:bg-n-solid-2"
      >
        <div class="flex items-center gap-3">
          <span
            class="inline-flex items-center gap-1.5 rounded-full border border-solid border-n-teal-4 bg-n-teal-2 px-2.5 py-0.5 text-xs font-semibold text-n-teal-11"
          >
            <span class="h-1.5 w-1.5 rounded-full bg-n-teal-9 animate-pulse" />
            {{ $t('EMPLOYEE_MGMT.MONITORING.LIVE') }}
          </span>
          <h1 class="mb-0 text-xl font-semibold tracking-tight text-n-slate-12">
            {{ $t('EMPLOYEE_MGMT.HEADER') }}
          </h1>
          <span class="text-xs text-n-slate-9">
            {{ $t('EMPLOYEE_MGMT.MONITORING.LAST_UPDATED') }}
            {{ lastUpdatedLabel }}
          </span>
        </div>
        <div class="flex shrink-0 items-center gap-2">
          <Button
            faded
            slate
            xs
            icon="i-lucide-refresh-cw"
            :is-loading="isFetching"
            :label="$t('EMPLOYEE_MGMT.MONITORING.REFRESH')"
            @click="fetchEmployees"
          />
          <Button
            xs
            icon="i-lucide-circle-plus"
            :label="$t('EMPLOYEE_MGMT.ADD')"
            @click="openCreateModal"
          />
        </div>
      </div>
    </template>

    <template #preBody>
      <div class="mb-5 flex w-full flex-col gap-5">
        <div
          class="flex flex-col gap-4 rounded-2xl border border-solid border-n-weak bg-n-solid-1 p-5 shadow-sm dark:bg-n-solid-2"
        >
          <div
            class="grid grid-cols-1 gap-3 xl:grid-cols-[minmax(22rem,1.4fr)_repeat(5,minmax(9rem,1fr))_auto]"
          >
            <div class="relative min-w-0">
              <span
                class="pointer-events-none absolute top-1/2 -translate-y-1/2 inline-block h-4 w-4 text-n-slate-10 i-lucide-search ltr:left-3 rtl:right-3"
              />
              <input
                v-model="filters.q"
                class="reset-base no-margin !mb-0 !h-9 w-full min-w-0 rounded-lg border border-solid border-n-weak bg-n-alpha-1 text-sm placeholder:text-n-slate-9 focus:border-n-brand-7 focus:outline-none focus:ring-1 focus:ring-n-brand-7 ltr:pl-10 rtl:pr-10"
                type="search"
                :placeholder="$t('EMPLOYEE_MGMT.FILTERS.SEARCH')"
              />
            </div>
            <select
              v-model="filters.role"
              class="no-margin !mb-0 !h-9 min-w-0 rounded-lg text-sm"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.ALL_ROLES') }}
              </option>
              <option value="administrator">
                {{ $t('EMPLOYEE_MGMT.ROLES.ADMINISTRATOR') }}
              </option>
              <option value="agent">
                {{ $t('EMPLOYEE_MGMT.ROLES.AGENT') }}
              </option>
            </select>
            <select
              v-model="filters.status"
              class="no-margin !mb-0 !h-9 min-w-0 rounded-lg text-sm"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.ALL_STATUS') }}
              </option>
              <option value="active">
                {{ $t('EMPLOYEE_MGMT.STATUS.ACTIVE') }}
              </option>
              <option value="inactive">
                {{ $t('EMPLOYEE_MGMT.STATUS.INACTIVE') }}
              </option>
              <option value="archived">
                {{ $t('EMPLOYEE_MGMT.STATUS.ARCHIVED') }}
              </option>
            </select>
            <select
              v-model="filters.presence_status"
              class="no-margin !mb-0 !h-9 min-w-0 rounded-lg text-sm"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.ALL_PRESENCE') }}
              </option>
              <option value="online">
                {{ $t('EMPLOYEE_MGMT.PRESENCE.ONLINE') }}
              </option>
              <option value="offline">
                {{ $t('EMPLOYEE_MGMT.PRESENCE.OFFLINE') }}
              </option>
            </select>
            <select
              v-model="filters.work_status"
              class="no-margin !mb-0 !h-9 min-w-0 rounded-lg text-sm"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.ALL_WORK_STATUS') }}
              </option>
              <option value="working">
                {{ $t('EMPLOYEE_MGMT.WORK_STATUS.WORKING') }}
              </option>
              <option value="idle">
                {{ $t('EMPLOYEE_MGMT.WORK_STATUS.IDLE') }}
              </option>
              <option value="not_responding">
                {{ $t('EMPLOYEE_MGMT.WORK_STATUS.NOT_RESPONDING') }}
              </option>
            </select>
            <select
              v-model="filters.team_id"
              class="no-margin !mb-0 !h-9 min-w-0 rounded-lg text-sm"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.ALL_TEAMS') }}
              </option>
              <option v-for="team in teams" :key="team.id" :value="team.id">
                {{ team.name }}
              </option>
            </select>
            <button
              type="button"
              class="inline-flex h-9 items-center justify-center gap-2 rounded-lg border border-solid border-n-weak px-3 text-sm font-medium text-n-slate-11 hover:bg-n-slate-2"
              @click="showAdvancedFilters = !showAdvancedFilters"
            >
              <span class="i-lucide-sliders-horizontal" />
              {{ $t('EMPLOYEE_MGMT.FILTERS.ADVANCED') }}
              <span
                class="text-base"
                :class="
                  showAdvancedFilters
                    ? 'i-lucide-chevron-up'
                    : 'i-lucide-chevron-down'
                "
              />
            </button>
          </div>

          <div
            v-if="showAdvancedFilters"
            class="grid grid-cols-1 gap-3 rounded-xl border border-solid border-n-weak bg-n-slate-1 p-4 md:grid-cols-2 xl:grid-cols-[repeat(4,minmax(10rem,1fr))_auto_auto_auto]"
          >
            <select
              v-model="filters.last_login"
              class="h-10 min-w-0 rounded-lg"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_LOGIN') }}
              </option>
              <option value="7_days">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_7_DAYS') }}
              </option>
              <option value="30_days">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_30_DAYS') }}
              </option>
              <option value="never">
                {{ $t('EMPLOYEE_MGMT.FILTERS.NEVER') }}
              </option>
            </select>
            <select
              v-model="filters.last_activity"
              class="h-10 min-w-0 rounded-lg"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_ACTIVITY') }}
              </option>
              <option value="7_days">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_7_DAYS') }}
              </option>
              <option value="30_days">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_30_DAYS') }}
              </option>
              <option value="never">
                {{ $t('EMPLOYEE_MGMT.FILTERS.NEVER') }}
              </option>
            </select>
            <select
              v-model="filters.idle_more_than"
              class="h-10 min-w-0 rounded-lg"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.IDLE_MORE_THAN') }}
              </option>
              <option value="15">
                {{ $t('EMPLOYEE_MGMT.FILTERS.MINUTES_15') }}
              </option>
              <option value="30">
                {{ $t('EMPLOYEE_MGMT.FILTERS.MINUTES_30') }}
              </option>
              <option value="60">
                {{ $t('EMPLOYEE_MGMT.FILTERS.MINUTES_60') }}
              </option>
            </select>
            <select
              v-model="filters.last_reply_before"
              class="h-10 min-w-0 rounded-lg"
            >
              <option value="">
                {{ $t('EMPLOYEE_MGMT.FILTERS.LAST_REPLY_BEFORE') }}
              </option>
              <option value="15">
                {{ $t('EMPLOYEE_MGMT.FILTERS.MINUTES_15') }}
              </option>
              <option value="30">
                {{ $t('EMPLOYEE_MGMT.FILTERS.MINUTES_30') }}
              </option>
              <option value="60">
                {{ $t('EMPLOYEE_MGMT.FILTERS.MINUTES_60') }}
              </option>
            </select>
            <label
              class="flex h-10 items-center gap-2 rounded-lg border border-solid border-n-weak px-3 text-sm text-n-slate-11"
            >
              <input
                v-model="filters.has_open_conversations"
                type="checkbox"
                true-value="true"
                false-value=""
              />
              {{ $t('EMPLOYEE_MGMT.FILTERS.HAS_OPEN') }}
            </label>
            <label
              class="flex h-10 items-center gap-2 rounded-lg border border-solid border-n-weak px-3 text-sm text-n-slate-11"
            >
              <input
                v-model="filters.has_unreplied_conversations"
                type="checkbox"
                true-value="true"
                false-value=""
              />
              {{ $t('EMPLOYEE_MGMT.FILTERS.HAS_UNREPLIED') }}
            </label>
            <div class="flex gap-2 xl:justify-end">
              <Button
                faded
                slate
                :label="$t('EMPLOYEE_MGMT.FILTERS.CLEAR')"
                @click="clearFilters"
              />
              <Button
                icon="i-lucide-refresh-cw"
                :is-loading="isFetching"
                :label="$t('EMPLOYEE_MGMT.FILTERS.APPLY')"
                @click="applyFilters"
              />
            </div>
          </div>

          <div v-if="activeFilterChips.length" class="flex flex-wrap gap-2">
            <button
              v-for="chip in activeFilterChips"
              :key="chip.key"
              type="button"
              class="inline-flex items-center gap-2 rounded-full border border-solid border-n-weak bg-n-slate-2 px-3 py-1 text-xs font-medium text-n-slate-11 hover:bg-n-slate-3"
              @click="clearFilter(chip.key)"
            >
              {{ chip.label }}
              <span class="i-lucide-x text-sm" />
            </button>
          </div>
        </div>

        <div class="mb-4 grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5">
          <button
            v-for="card in summaryCards"
            :key="card.key"
            type="button"
            class="group relative flex min-h-28 overflow-hidden rounded-xl border border-solid p-3 transition-all duration-300 hover:-translate-y-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-brand-7 ltr:text-left rtl:text-right"
            :class="summaryCardClass(card)"
            :title="card.subtitle"
            @click="applyCardFilter(card)"
          >
            <span
              class="absolute top-0 h-full w-1 animate-pulse opacity-80 transition-all duration-500 group-hover:opacity-100 ltr:left-0 rtl:right-0"
              :class="accentBarClass(card)"
            />
            <div
              class="flex min-h-full w-full flex-col gap-2 ltr:pl-1 rtl:pr-1"
            >
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <span
                      class="block text-xs font-semibold uppercase text-n-slate-10 ltr:tracking-widest rtl:tracking-normal"
                    >
                      {{ card.metricLabel }}
                    </span>
                    <span class="flex items-center gap-1.5">
                      <span
                        class="h-1.5 w-1.5 rounded-full"
                        :class="summaryLiveDotClass(card)"
                      />
                      <span
                        class="text-[10px] font-semibold uppercase text-n-slate-9 ltr:tracking-wider rtl:tracking-normal"
                      >
                        {{ $t('EMPLOYEE_MGMT.MONITORING.LIVE_SHORT') }}
                      </span>
                    </span>
                  </div>
                  <span
                    class="mt-1 block text-sm font-semibold leading-5 text-n-slate-12"
                  >
                    {{ card.label }}
                  </span>
                </div>
                <span
                  class="relative flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-lg text-base ring-1 transition-all duration-300 group-hover:scale-110"
                  :class="[
                    summaryIconClass(card),
                    summaryIconMotionClass(card),
                  ]"
                >
                  <span
                    class="absolute -top-1 h-3 w-3 rounded-full opacity-60 ltr:-right-1 rtl:-left-1"
                    :class="summaryLiveDotClass(card)"
                  />
                  <span
                    class="absolute inset-0 opacity-20 transition-opacity duration-300 group-hover:opacity-40"
                    :class="toneFillClass(card.tone)"
                  />
                  <span class="relative" :class="card.icon" />
                </span>
              </div>

              <div class="mt-auto">
                <div class="flex items-end justify-between gap-3">
                  <span
                    class="block truncate text-3xl font-bold tracking-tight text-n-slate-12"
                    :class="summaryValueClass(card)"
                  >
                    {{ card.value }}
                  </span>
                  <span
                    v-if="activeFilterCard === card.key"
                    class="mb-1 shrink-0 rounded-full bg-n-brand-3 px-2 py-1 text-[10px] font-semibold uppercase text-n-brand-11 ltr:tracking-wider rtl:tracking-normal"
                  >
                    {{ $t('EMPLOYEE_MGMT.SUMMARY.ACTIVE_FILTER') }}
                  </span>
                </div>
                <span class="mt-1 block text-xs leading-4 text-n-slate-10">
                  {{ card.subtitle }}
                </span>
              </div>
            </div>
          </button>
        </div>
      </div>

      <div
        v-if="selectedIds.length"
        class="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-xl border border-solid border-n-weak bg-n-slate-1 p-3 dark:bg-n-solid-2"
      >
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('EMPLOYEE_MGMT.BULK.SELECTED', { count: selectedIds.length }) }}
        </span>
        <div class="flex flex-wrap gap-2">
          <Button
            xs
            slate
            faded
            :label="$t('EMPLOYEE_MGMT.BULK.ACTIVATE')"
            @click="bulkAction('activate')"
          />
          <Button
            xs
            amber
            faded
            :label="$t('EMPLOYEE_MGMT.BULK.DEACTIVATE')"
            @click="bulkAction('deactivate')"
          />
          <Button
            xs
            ruby
            faded
            :label="$t('EMPLOYEE_MGMT.BULK.ARCHIVE')"
            @click="bulkAction('archive')"
          />
        </div>
      </div>
    </template>

    <template #body>
      <div
        v-if="openDropdownId"
        class="fixed inset-0 z-[5]"
        @click="openDropdownId = null"
      />
      <div
        class="relative z-10 w-full overflow-x-auto rounded-2xl border border-solid border-n-weak bg-n-solid-1 shadow-sm"
        :dir="isRTL ? 'rtl' : 'ltr'"
      >
        <table class="w-full min-w-[1580px] table-fixed text-sm">
          <colgroup>
            <col class="w-[48px]" />
            <col class="w-[300px]" />
            <col class="w-[110px]" />
            <col class="w-[130px]" />
            <col class="w-[120px]" />
            <col class="w-[130px]" />
            <col class="w-[180px]" />
            <col class="w-[110px]" />
            <col class="w-[230px]" />
            <col class="w-[170px]" />
            <col class="w-[100px]" />
          </colgroup>
          <thead
            class="sticky top-0 z-10 border-b border-solid border-n-weak bg-n-slate-2 text-xs font-semibold uppercase text-n-slate-11 ltr:text-left ltr:tracking-wide rtl:text-right rtl:tracking-normal"
          >
            <tr>
              <th
                class="w-10 px-3 py-3 text-xs font-medium uppercase ltr:tracking-wider rtl:tracking-normal"
              >
                <input
                  type="checkbox"
                  :checked="allSelected"
                  @change="toggleSelectAll"
                />
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.EMPLOYEE') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.STATUS') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.PRESENCE') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.WORK_STATUS') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.HEALTH') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.WORKLOAD') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.WAITING') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.ACTIVITY') }}
              </th>
              <th class="px-3 py-3">
                {{ $t('EMPLOYEE_MGMT.TABLE.TODAY') }}
              </th>
              <th class="px-3 py-3 ltr:text-right rtl:text-left">
                {{ $t('EMPLOYEE_MGMT.TABLE.ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak text-n-slate-12">
            <template v-for="employee in filteredEmployees" :key="employee.id">
              <tr
                class="align-middle transition hover:bg-n-slate-1/70 dark:hover:bg-n-solid-2"
              >
                <td class="px-3 py-4">
                  <input
                    v-model="selectedIds"
                    type="checkbox"
                    :value="employee.id"
                  />
                </td>
                <td class="px-3 py-4">
                  <div class="flex min-w-0 items-center gap-3">
                    <div
                      class="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-solid border-n-slate-4 bg-n-slate-3 text-sm font-semibold text-n-slate-12"
                    >
                      {{ employeeInitials(employee) }}
                      <span
                        class="absolute bottom-0 h-3 w-3 rounded-full border-2 border-solid border-n-solid-1 ltr:right-0 rtl:left-0"
                        :class="presenceDotClass(employee)"
                      />
                    </div>
                    <div class="min-w-0">
                      <span class="block truncate font-medium text-n-slate-12">
                        {{ employee.name }}
                      </span>
                      <span
                        class="block max-w-64 truncate text-xs text-n-slate-10"
                      >
                        {{ employee.username || $t('EMPLOYEE_MGMT.EMPTY') }}
                      </span>
                      <span class="mt-1 flex flex-wrap gap-1">
                        <span
                          class="inline-flex px-1.5 py-0.5 text-xs font-medium border border-solid rounded"
                          :class="roleBadgeClass(employee.role)"
                        >
                          {{ roleLabel(employee.role) }}
                        </span>
                        <span
                          v-for="team in employeeTeams(employee)"
                          :key="team.id"
                          class="px-1.5 py-0.5 text-xs border border-solid rounded border-n-slate-4 bg-n-slate-3 text-n-slate-11"
                        >
                          {{ team.name }}
                        </span>
                      </span>
                    </div>
                  </div>
                </td>
                <td class="px-3 py-4">
                  <span
                    class="inline-flex w-fit px-2 py-1 text-xs font-medium border border-solid rounded-md"
                    :class="statusBadgeClass(employee)"
                  >
                    {{ statusLabel(employee) }}
                  </span>
                </td>
                <td class="px-3 py-4">
                  <span
                    class="inline-flex w-full items-center gap-2 text-xs font-medium text-n-slate-11"
                    :title="presenceTooltip(employee)"
                  >
                    <span
                      class="h-2 w-2 rounded-full shadow-sm"
                      :class="presenceDotClass(employee)"
                    />
                    {{ presenceLabel(employee) }}
                  </span>
                </td>
                <td class="px-3 py-4">
                  <span
                    class="inline-flex min-w-16 justify-center px-2 py-0.5 text-xs font-medium"
                    :class="workStatusBadgeClass(employee)"
                    :title="workStatusTooltip(employee)"
                  >
                    {{ workStatusLabel(employee) }}
                  </span>
                </td>
                <td class="px-3 py-4">
                  <div class="flex min-w-0 items-center gap-2">
                    <span
                      class="inline-flex min-w-16 items-center justify-center gap-1.5 px-2 py-0.5 text-xs font-semibold"
                      :class="attentionBadgeClass(employee)"
                      :title="attentionTooltip(employee)"
                    >
                      {{ attentionLabel(employee) }}
                    </span>
                  </div>
                </td>
                <td class="px-3 py-4">
                  <div class="grid w-full grid-cols-2 gap-1.5 text-center">
                    <div class="min-w-0 rounded-md bg-n-slate-2 px-2 py-1">
                      <span class="block truncate text-[11px] text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.TABLE.OPEN_CONVERSATIONS') }}
                      </span>
                      <span class="font-semibold text-n-slate-12">
                        {{ metric(employee).open_conversations_count || 0 }}
                      </span>
                    </div>
                    <div class="min-w-0 rounded-md bg-n-slate-2 px-2 py-1">
                      <span class="block truncate text-[11px] text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.TABLE.UNREPLIED') }}
                      </span>
                      <span
                        class="font-semibold"
                        :class="
                          metric(employee).unreplied_conversations_count
                            ? 'text-n-ruby-11'
                            : 'text-n-slate-12'
                        "
                      >
                        {{
                          metric(employee).unreplied_conversations_count || 0
                        }}
                      </span>
                    </div>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-n-slate-11">
                  {{
                    formatDuration(
                      metric(employee).oldest_waiting_customer_seconds
                    )
                  }}
                </td>
                <td class="px-3 py-4 text-n-slate-11">
                  <div
                    class="grid min-w-0 grid-cols-[auto_minmax(0,1fr)] gap-x-2 gap-y-1 text-xs leading-5"
                  >
                    <span class="text-n-slate-10">
                      {{ $t('EMPLOYEE_MGMT.TABLE.LAST_REPLY') }}
                    </span>
                    <span class="truncate">{{
                      formatSince(metric(employee).last_reply_at)
                    }}</span>
                    <span class="text-n-slate-10">
                      {{ $t('EMPLOYEE_MGMT.TABLE.LAST_ACTIVITY') }}
                    </span>
                    <span class="truncate">{{
                      formatSince(metric(employee).last_activity_at)
                    }}</span>
                    <span class="text-n-slate-10">
                      {{ $t('EMPLOYEE_MGMT.TABLE.IDLE_DURATION') }}
                    </span>
                    <span class="truncate">
                      {{ formatDuration(metric(employee).idle_duration) }}
                    </span>
                  </div>
                </td>
                <td class="px-3 py-4 text-n-slate-11">
                  <div class="grid w-full grid-cols-2 gap-1.5 text-center">
                    <div class="min-w-0 rounded-md bg-n-slate-2 px-2 py-1">
                      <span class="block truncate text-[11px] text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.TABLE.REPLIES_TODAY') }}
                      </span>
                      <span class="font-semibold text-n-slate-12">
                        {{ metric(employee).replies_count_today || 0 }}
                      </span>
                    </div>
                    <div class="min-w-0 rounded-md bg-n-slate-2 px-2 py-1">
                      <span class="block truncate text-[11px] text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.TABLE.RESOLVED_TODAY') }}
                      </span>
                      <span class="font-semibold text-n-slate-12">
                        {{ metric(employee).resolved_conversations_today || 0 }}
                      </span>
                    </div>
                  </div>
                </td>
                <td class="relative px-3 py-4 ltr:text-right rtl:text-left">
                  <div class="flex gap-1 ltr:justify-end rtl:justify-start">
                    <button
                      type="button"
                      class="flex h-8 w-8 items-center justify-center rounded-md text-n-slate-11 transition-colors hover:bg-n-slate-3 hover:text-n-slate-12 focus:outline-none"
                      @click.stop="toggleRowDetails(employee.id)"
                    >
                      <span
                        class="text-lg"
                        :class="
                          isRowExpanded(employee.id)
                            ? 'i-lucide-chevron-up'
                            : 'i-lucide-chevron-down'
                        "
                      />
                    </button>
                    <button
                      type="button"
                      class="flex items-center justify-center w-8 h-8 transition-colors rounded-md text-n-slate-11 hover:bg-n-slate-3 hover:text-n-slate-12 focus:outline-none"
                      @click.stop="toggleDropdown(employee.id)"
                    >
                      <span class="text-lg i-lucide-more-vertical" />
                    </button>
                  </div>

                  <div
                    v-if="openDropdownId === employee.id"
                    class="absolute top-full z-20 mt-1 w-48 origin-top-right overflow-hidden rounded-lg border border-solid border-n-weak bg-n-solid-1 py-1 shadow-lg focus:outline-none ltr:right-4 rtl:left-4"
                  >
                    <button
                      class="flex w-full items-center px-4 py-2 text-sm transition-colors text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 ltr:text-left rtl:text-right"
                      @click="handleEmployeeAction(employee, 'edit')"
                    >
                      <span class="text-lg i-lucide-pencil ltr:mr-2 rtl:ml-2" />
                      {{ $t('EMPLOYEE_MGMT.ACTIONS.EDIT') }}
                    </button>
                    <button
                      class="flex w-full items-center px-4 py-2 text-sm transition-colors text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 ltr:text-left rtl:text-right"
                      @click="handleEmployeeAction(employee, 'password')"
                    >
                      <span class="text-lg i-lucide-key ltr:mr-2 rtl:ml-2" />
                      {{ $t('EMPLOYEE_MGMT.ACTIONS.PASSWORD') }}
                    </button>
                    <button
                      class="flex w-full items-center px-4 py-2 text-sm transition-colors text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 ltr:text-left rtl:text-right"
                      @click="handleEmployeeAction(employee, 'activity')"
                    >
                      <span
                        class="text-lg i-lucide-activity ltr:mr-2 rtl:ml-2"
                      />
                      {{ $t('EMPLOYEE_MGMT.ACTIONS.ACTIVITY') }}
                    </button>
                    <div class="h-px w-full bg-n-weak my-1" />
                    <button
                      class="flex w-full items-center px-4 py-2 text-sm font-medium transition-colors ltr:text-left rtl:text-right"
                      :class="
                        employee.active
                          ? 'text-n-ruby-11 hover:bg-n-ruby-2 hover:text-n-ruby-12'
                          : 'text-n-teal-11 hover:bg-n-teal-2 hover:text-n-teal-12'
                      "
                      @click="
                        handleEmployeeAction(
                          employee,
                          employee.active ? 'deactivate' : 'activate'
                        )
                      "
                    >
                      <span
                        class="text-lg ltr:mr-2 rtl:ml-2"
                        :class="
                          employee.active
                            ? 'i-lucide-user-minus'
                            : 'i-lucide-user-check'
                        "
                      />
                      {{
                        employee.active
                          ? $t('EMPLOYEE_MGMT.ACTIONS.DEACTIVATE')
                          : $t('EMPLOYEE_MGMT.ACTIONS.ACTIVATE')
                      }}
                    </button>
                    <button
                      class="flex w-full items-center px-4 py-2 text-sm font-medium transition-colors text-n-ruby-11 hover:bg-n-ruby-2 hover:text-n-ruby-12 ltr:text-left rtl:text-right"
                      @click="handleEmployeeAction(employee, 'archive')"
                    >
                      <span
                        class="text-lg i-lucide-archive ltr:mr-2 rtl:ml-2"
                      />
                      {{ $t('EMPLOYEE_MGMT.ACTIONS.ARCHIVE') }}
                    </button>
                    <button
                      class="flex w-full items-center px-4 py-2 text-sm font-medium transition-colors text-n-ruby-11 hover:bg-n-ruby-2 hover:text-n-ruby-12 ltr:text-left rtl:text-right"
                      @click="handleEmployeeAction(employee, 'delete')"
                    >
                      <span
                        class="text-lg i-lucide-trash-2 ltr:mr-2 rtl:ml-2"
                      />
                      {{ $t('EMPLOYEE_MGMT.ACTIONS.DELETE') }}
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="isRowExpanded(employee.id)" class="bg-n-slate-1/60">
                <td colspan="11" class="px-4 py-4">
                  <div
                    class="grid gap-3 rounded-xl border border-solid border-n-weak bg-n-solid-1 p-4 md:grid-cols-4"
                  >
                    <div>
                      <span class="block text-xs font-medium text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.DRILLDOWN.IDENTITY') }}
                      </span>
                      <span class="block text-sm font-medium text-n-slate-12">
                        {{ employee.name }}
                      </span>
                      <span class="block text-xs text-n-slate-10">
                        {{ employee.phone_number || $t('EMPLOYEE_MGMT.EMPTY') }}
                      </span>
                    </div>
                    <div>
                      <span class="block text-xs font-medium text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.DRILLDOWN.WORKLOAD') }}
                      </span>
                      <div
                        class="grid grid-cols-[auto_1fr] gap-x-2 text-sm text-n-slate-12"
                      >
                        <span class="text-n-slate-10">
                          {{ $t('EMPLOYEE_MGMT.TABLE.OPEN_CONVERSATIONS') }}
                        </span>
                        <span>
                          {{ metric(employee).open_conversations_count || 0 }}
                        </span>
                        <span class="text-n-slate-10">
                          {{ $t('EMPLOYEE_MGMT.TABLE.UNREPLIED') }}
                        </span>
                        <span>
                          {{
                            metric(employee).unreplied_conversations_count || 0
                          }}
                        </span>
                      </div>
                    </div>
                    <div>
                      <span class="block text-xs font-medium text-n-slate-10">
                        {{ $t('EMPLOYEE_MGMT.DRILLDOWN.RESPONSE') }}
                      </span>
                      <div
                        class="grid grid-cols-[auto_1fr] gap-x-2 text-sm text-n-slate-12"
                      >
                        <span class="text-n-slate-10">
                          {{ $t('EMPLOYEE_MGMT.TABLE.LAST_REPLY') }}
                        </span>
                        <span>
                          {{ formatSince(metric(employee).last_reply_at) }}
                        </span>
                        <span class="text-n-slate-10">
                          {{ $t('EMPLOYEE_MGMT.TABLE.OLDEST_WAITING') }}
                        </span>
                        <span
                          :class="
                            waitingTextClass(
                              metric(employee).oldest_waiting_customer_seconds
                            )
                          "
                        >
                          {{
                            formatDuration(
                              metric(employee).oldest_waiting_customer_seconds
                            )
                          }}
                        </span>
                      </div>
                    </div>
                    <div class="flex items-center justify-end">
                      <Button
                        faded
                        slate
                        icon="i-lucide-activity"
                        :label="$t('EMPLOYEE_MGMT.ACTIONS.ACTIVITY')"
                        @click="openDetails(employee)"
                      />
                    </div>
                  </div>
                </td>
              </tr>
            </template>
          </tbody>
        </table>
        <div
          v-if="tableEmpty"
          class="flex flex-col items-center gap-3 border-t border-solid border-n-weak px-6 py-10 text-center"
        >
          <span
            class="rounded-full bg-n-slate-2 p-3 text-2xl text-n-slate-10 i-lucide-search-x"
          />
          <div>
            <h3 class="m-0 text-base font-semibold text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.EMPTY_FILTERED.TITLE') }}
            </h3>
            <p class="m-0 text-sm text-n-slate-11">
              {{ $t('EMPLOYEE_MGMT.EMPTY_FILTERED.DESCRIPTION') }}
            </p>
          </div>
          <Button
            faded
            slate
            :label="$t('EMPLOYEE_MGMT.FILTERS.CLEAR')"
            @click="clearFilters"
          />
        </div>
      </div>
    </template>
  </SettingsLayout>

  <woot-modal
    v-model:show="showFormModal"
    :on-close="() => (showFormModal = false)"
    size="medium"
  >
    <div class="flex flex-col w-full h-full max-h-[90vh]">
      <woot-modal-header
        class="px-8 pt-8 pb-4"
        :header-title="
          isEditing
            ? $t('EMPLOYEE_MGMT.FORM.EDIT_TITLE')
            : $t('EMPLOYEE_MGMT.FORM.ADD_TITLE')
        "
        :header-content="$t('EMPLOYEE_MGMT.FORM.DESCRIPTION')"
      />
      <form class="flex flex-col min-h-0" @submit.prevent="saveEmployee">
        <div class="flex flex-col gap-8 px-8 pb-8 overflow-y-auto">
          <!-- Identity Section -->
          <section class="grid grid-cols-1 gap-6 md:grid-cols-2">
            <h3
              class="pb-2 text-xs font-semibold tracking-wide uppercase border-b border-solid md:col-span-2 text-n-slate-11 border-n-weak"
            >
              {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.IDENTITY') }}
            </h3>
            <label class="flex flex-col">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.NAME') }}
                <span class="text-n-ruby-9">{{
                  $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                }}</span>
              </span>
              <input
                ref="firstFieldRef"
                v-model="form.name"
                required
                type="text"
                :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.NAME')"
              />
              <span
                v-if="!form.name.trim()"
                class="mt-1 text-xs text-n-ruby-11"
              >
                {{ $t('EMPLOYEE_MGMT.VALIDATION.NAME_REQUIRED') }}
              </span>
            </label>
            <label class="flex flex-col">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.PHONE') }}
                <span class="text-n-ruby-9">{{
                  $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                }}</span>
              </span>
              <input
                v-model="form.phone_number"
                required
                type="text"
                :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.PHONE')"
              />
              <span
                v-if="!form.phone_number.trim()"
                class="mt-1 text-xs text-n-ruby-11"
              >
                {{ $t('EMPLOYEE_MGMT.VALIDATION.PHONE_REQUIRED') }}
              </span>
            </label>
            <label class="flex flex-col">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.USERNAME') }}
                <span class="text-n-ruby-9">{{
                  $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                }}</span>
              </span>
              <input
                v-model="form.username"
                required
                type="text"
                :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.USERNAME')"
              />
              <span
                v-if="!form.username.trim()"
                class="mt-1 text-xs text-n-ruby-11"
              >
                {{ $t('EMPLOYEE_MGMT.VALIDATION.USERNAME_REQUIRED') }}
              </span>
            </label>
          </section>

          <!-- Access and Teams Section -->
          <section class="grid grid-cols-1 gap-6 md:grid-cols-2">
            <h3
              class="pb-2 text-xs font-semibold tracking-wide uppercase border-b border-solid md:col-span-2 text-n-slate-11 border-n-weak"
            >
              {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.ACCESS') }}
            </h3>
            <label class="flex flex-col">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.ROLE') }}
                <span class="text-n-ruby-9">{{
                  $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                }}</span>
              </span>
              <select v-model="form.role">
                <option value="administrator">
                  {{ $t('EMPLOYEE_MGMT.ROLES.ADMINISTRATOR') }}
                </option>
                <option value="agent">
                  {{ $t('EMPLOYEE_MGMT.ROLES.AGENT') }}
                </option>
              </select>
            </label>
            <label class="flex flex-col">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.JOB_TITLE') }}
              </span>
              <input
                v-model="form.job_title"
                type="text"
                :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.JOB_TITLE')"
              />
            </label>
            <div class="flex flex-col md:col-span-2">
              <span class="mb-2 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.TEAMS') }}
              </span>
              <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 md:grid-cols-3">
                <label
                  v-for="team in teams"
                  :key="team.id"
                  class="flex items-center gap-3 px-4 py-3 m-0 transition-colors border border-solid rounded-lg cursor-pointer"
                  :class="
                    isTeamSelected(team.id)
                      ? 'border-n-brand-5 bg-n-brand-2 text-n-brand-12'
                      : 'border-n-weak bg-n-slate-1 dark:bg-n-solid-2 hover:bg-n-slate-2'
                  "
                >
                  <input
                    type="checkbox"
                    class="w-4 h-4 text-n-brand-9 border-n-slate-4 rounded focus:ring-n-brand-5"
                    :checked="isTeamSelected(team.id)"
                    @change="toggleTeam(team.id)"
                  />
                  <span class="font-medium truncate">{{ team.name }}</span>
                </label>
              </div>
            </div>
          </section>

          <!-- Password Section -->
          <section
            v-if="!isEditing"
            class="grid grid-cols-1 gap-6 md:grid-cols-2"
          >
            <h3
              class="pb-2 text-xs font-semibold tracking-wide uppercase border-b border-solid md:col-span-2 text-n-slate-11 border-n-weak"
            >
              {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.PASSWORD') }}
            </h3>
            <label class="flex flex-col relative">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD') }}
                <span class="text-n-ruby-9">{{
                  $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                }}</span>
              </span>
              <div class="relative w-full">
                <input
                  v-model="form.password"
                  required
                  :type="showNewPassword ? 'text' : 'password'"
                  class="w-full pr-10"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-0 flex items-center px-3 text-n-slate-10 hover:text-n-slate-12"
                  :title="
                    showNewPassword
                      ? $t('EMPLOYEE_MGMT.PASSWORD.HIDE')
                      : $t('EMPLOYEE_MGMT.PASSWORD.SHOW')
                  "
                  @click="showNewPassword = !showNewPassword"
                >
                  <span
                    :class="
                      showNewPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'
                    "
                    class="text-lg"
                  />
                </button>
              </div>
            </label>
            <label class="flex flex-col relative">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD_CONFIRMATION') }}
                <span class="text-n-ruby-9">{{
                  $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                }}</span>
              </span>
              <div class="relative w-full">
                <input
                  v-model="form.password_confirmation"
                  required
                  :type="showNewPasswordConfirmation ? 'text' : 'password'"
                  class="w-full pr-10"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-0 flex items-center px-3 text-n-slate-10 hover:text-n-slate-12"
                  :title="
                    showNewPasswordConfirmation
                      ? $t('EMPLOYEE_MGMT.PASSWORD.HIDE')
                      : $t('EMPLOYEE_MGMT.PASSWORD.SHOW')
                  "
                  @click="
                    showNewPasswordConfirmation = !showNewPasswordConfirmation
                  "
                >
                  <span
                    :class="
                      showNewPasswordConfirmation
                        ? 'i-lucide-eye-off'
                        : 'i-lucide-eye'
                    "
                    class="text-lg"
                  />
                </button>
              </div>
            </label>
            <div class="flex flex-col gap-2 md:col-span-2">
              <div class="flex items-center gap-2">
                <span
                  class="inline-flex items-center px-2 py-1 text-xs font-semibold border border-solid rounded-md"
                  :class="passwordStrengthClass"
                >
                  {{ passwordStrengthLabel }}
                </span>
                <span class="text-xs text-n-slate-11">
                  {{ $t('EMPLOYEE_MGMT.PASSWORD.REQUIREMENTS') }}
                </span>
              </div>
            </div>
          </section>

          <!-- Status Section -->
          <section class="grid grid-cols-1 gap-6 md:grid-cols-2">
            <h3
              class="pb-2 text-xs font-semibold tracking-wide uppercase border-b border-solid md:col-span-2 text-n-slate-11 border-n-weak"
            >
              {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.STATUS') }}
            </h3>
            <label class="flex flex-col gap-2 md:col-span-2">
              <div class="flex items-center gap-3">
                <input
                  v-model="form.active"
                  type="checkbox"
                  class="w-5 h-5 text-n-brand-9 border-n-slate-4 rounded focus:ring-n-brand-5 cursor-pointer"
                />
                <span
                  class="font-medium text-n-slate-12 cursor-pointer"
                  @click="form.active = !form.active"
                >
                  {{ $t('EMPLOYEE_MGMT.FORM.ACTIVE') }}
                </span>
              </div>
            </label>
            <label v-if="!form.active" class="flex flex-col md:col-span-2">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.DEACTIVATION_REASON') }}
              </span>
              <textarea
                v-model="form.deactivation_reason"
                rows="2"
                class="resize-none"
              />
            </label>
            <label class="flex flex-col md:col-span-2">
              <span class="mb-1 font-medium text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.FORM.NOTES') }}
              </span>
              <textarea
                v-model="form.employee_notes"
                rows="3"
                :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.NOTES')"
                class="resize-none"
              />
            </label>
          </section>
        </div>

        <div
          class="sticky bottom-0 flex flex-col gap-2 px-8 py-5 border-t border-solid bg-n-solid-1 border-n-weak"
        >
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-n-ruby-11">
              {{ saveDisabledReason }}
            </span>
            <div class="flex justify-end gap-3 ml-auto">
              <Button
                type="button"
                faded
                slate
                :label="$t('EMPLOYEE_MGMT.CANCEL')"
                @click="showFormModal = false"
              />
              <Button
                type="submit"
                :is-loading="isSaving"
                :disabled="!canSaveEmployee"
                :label="$t('EMPLOYEE_MGMT.SAVE')"
              />
            </div>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>

  <woot-modal
    v-model:show="showPasswordModal"
    :on-close="() => (showPasswordModal = false)"
  >
    <div class="flex flex-col gap-6 p-8 w-full max-w-lg">
      <woot-modal-header
        :header-title="$t('EMPLOYEE_MGMT.PASSWORD.TITLE')"
        :header-content="$t('EMPLOYEE_MGMT.PASSWORD.DESCRIPTION')"
      />
      <form class="flex flex-col gap-6" @submit.prevent="changePassword">
        <label class="flex flex-col relative">
          <span class="mb-1 font-medium text-n-slate-12">
            {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD') }}
            <span class="text-n-ruby-9">{{
              $t('EMPLOYEE_MGMT.REQUIRED_MARK')
            }}</span>
          </span>
          <div class="relative w-full">
            <input
              v-model="passwordForm.password"
              required
              :type="showNewPassword ? 'text' : 'password'"
              class="w-full pr-10"
            />
            <button
              type="button"
              class="absolute inset-y-0 right-0 flex items-center px-3 text-n-slate-10 hover:text-n-slate-12"
              :title="
                showNewPassword
                  ? $t('EMPLOYEE_MGMT.PASSWORD.HIDE')
                  : $t('EMPLOYEE_MGMT.PASSWORD.SHOW')
              "
              @click="showNewPassword = !showNewPassword"
            >
              <span
                :class="showNewPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                class="text-lg"
              />
            </button>
          </div>
        </label>
        <label class="flex flex-col relative">
          <span class="mb-1 font-medium text-n-slate-12">
            {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD_CONFIRMATION') }}
            <span class="text-n-ruby-9">{{
              $t('EMPLOYEE_MGMT.REQUIRED_MARK')
            }}</span>
          </span>
          <div class="relative w-full">
            <input
              v-model="passwordForm.password_confirmation"
              required
              :type="showNewPasswordConfirmation ? 'text' : 'password'"
              class="w-full pr-10"
            />
            <button
              type="button"
              class="absolute inset-y-0 right-0 flex items-center px-3 text-n-slate-10 hover:text-n-slate-12"
              :title="
                showNewPasswordConfirmation
                  ? $t('EMPLOYEE_MGMT.PASSWORD.HIDE')
                  : $t('EMPLOYEE_MGMT.PASSWORD.SHOW')
              "
              @click="
                showNewPasswordConfirmation = !showNewPasswordConfirmation
              "
            >
              <span
                :class="
                  showNewPasswordConfirmation
                    ? 'i-lucide-eye-off'
                    : 'i-lucide-eye'
                "
                class="text-lg"
              />
            </button>
          </div>
        </label>
        <div class="flex items-center gap-2">
          <div
            class="inline-flex items-center px-2 py-1 text-xs font-semibold border border-solid rounded-md"
            :class="passwordStrengthClass"
          >
            {{ passwordStrengthLabel }}
          </div>
          <span class="text-xs text-n-slate-11">
            {{ $t('EMPLOYEE_MGMT.PASSWORD.REQUIREMENTS') }}
          </span>
        </div>
        <div class="flex justify-end gap-3 mt-2">
          <Button
            type="button"
            faded
            slate
            :label="$t('EMPLOYEE_MGMT.CANCEL')"
            @click="showPasswordModal = false"
          />
          <Button
            type="submit"
            :is-loading="isSaving"
            :disabled="!canSubmitPassword || isSaving"
            :label="$t('EMPLOYEE_MGMT.PASSWORD.SAVE')"
          />
        </div>
      </form>
    </div>
  </woot-modal>

  <woot-modal
    v-model:show="showDetailsModal"
    size="medium"
    :on-close="() => (showDetailsModal = false)"
  >
    <div
      class="flex max-h-[90vh] w-full flex-col overflow-hidden bg-n-solid-1 ltr:text-left rtl:text-right"
      :dir="isRTL ? 'rtl' : 'ltr'"
    >
      <div
        class="shrink-0 border-b border-solid border-n-weak bg-n-solid-2/60 px-6 py-5 ltr:pr-12 rtl:pl-12"
      >
        <div
          class="grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-start"
        >
          <div class="min-w-0">
            <span
              class="text-xs font-semibold uppercase text-n-slate-10 ltr:tracking-wider rtl:tracking-normal"
            >
              {{ $t('EMPLOYEE_MGMT.DETAILS.ACTIVITY_TITLE') }}
            </span>
            <h2
              class="mt-2 max-w-3xl break-words text-3xl font-semibold leading-tight text-n-slate-12"
            >
              {{ currentEmployee?.name }}
            </h2>
            <span class="mt-2 block truncate text-sm text-n-slate-10">
              {{ currentEmployee?.username || $t('EMPLOYEE_MGMT.EMPTY') }}
            </span>
          </div>
          <div class="flex min-w-0 shrink-0 flex-wrap items-center gap-2">
            <span
              class="inline-flex min-w-0 items-center gap-2 rounded-full border border-solid border-n-weak bg-n-slate-2 px-3 py-1.5 text-xs font-medium text-n-slate-11"
              :title="presenceTooltip(currentEmployee)"
            >
              <span
                class="h-2 w-2 rounded-full"
                :class="presenceDotClass(currentEmployee)"
              />
              {{ presenceLabel(currentEmployee) }}
            </span>
            <span
              class="inline-flex min-w-0 px-3 py-1.5 text-xs font-medium"
              :class="workStatusBadgeClass(currentEmployee)"
              :title="workStatusTooltip(currentEmployee)"
            >
              {{ workStatusLabel(currentEmployee) }}
            </span>
            <span
              class="inline-flex min-w-0 px-3 py-1.5 text-xs font-semibold"
              :class="attentionBadgeClass(currentEmployee)"
              :title="attentionTooltip(currentEmployee)"
            >
              {{ attentionLabel(currentEmployee) }}
            </span>
          </div>
        </div>
      </div>

      <section
        v-if="activityDetails"
        class="flex flex-1 flex-col gap-5 overflow-y-auto overflow-x-hidden bg-n-surface-1 px-6 py-6"
      >
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3">
          <div
            v-for="card in detailMetricCards"
            :key="card.key"
            class="group relative min-w-0 overflow-hidden rounded-2xl border border-solid border-n-weak bg-n-solid-1 p-4 shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:shadow-xl"
            :class="detailMetricCardClass(card)"
          >
            <span
              class="absolute top-0 h-full w-1 opacity-80 ltr:left-0 rtl:right-0"
              :class="accentBarClass(card)"
            />
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <span
                  class="block truncate text-xs font-semibold uppercase text-n-slate-10 ltr:tracking-wider rtl:tracking-normal"
                >
                  {{ card.label }}
                </span>
                <span
                  class="mt-3 block truncate text-3xl font-semibold"
                  :class="detailMetricValueClass(card)"
                >
                  {{ card.value }}
                </span>
              </div>
              <span
                class="relative flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-xl text-lg ring-1 transition-all duration-300 group-hover:scale-110"
                :class="detailMetricIconClass(card)"
              >
                <span
                  class="absolute -top-1 h-3 w-3 rounded-full opacity-70 ltr:-right-1 rtl:-left-1"
                  :class="summaryLiveDotClass(card)"
                />
                <span class="relative" :class="card.icon" />
              </span>
            </div>
          </div>
        </div>

        <div
          class="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,0.95fr)_minmax(0,1.05fr)]"
        >
          <section
            class="group relative min-w-0 overflow-hidden rounded-2xl border border-solid border-n-weak bg-n-solid-1 p-5 shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:border-n-ruby-6 hover:shadow-xl hover:shadow-n-ruby-3/20"
          >
            <span
              class="absolute top-0 h-full w-1 animate-pulse bg-n-ruby-6 opacity-80 ltr:left-0 rtl:right-0"
            />
            <div
              class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between"
            >
              <div class="flex min-w-0 items-start gap-3">
                <span
                  class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-n-ruby-3 text-xl text-n-ruby-11 ring-1 ring-n-ruby-5/30 transition-transform duration-300 group-hover:scale-110"
                >
                  <span class="i-lucide-shield-alert" />
                </span>
                <div class="min-w-0">
                  <span
                    class="text-xs font-semibold uppercase text-n-slate-10 ltr:tracking-wider rtl:tracking-normal"
                  >
                    {{ $t('EMPLOYEE_MGMT.DETAILS.RESPONSE_RISK') }}
                  </span>
                  <h3 class="mt-1 text-lg font-semibold text-n-slate-12">
                    {{ attentionLabel(currentEmployee) }}
                  </h3>
                </div>
              </div>
              <span
                class="inline-flex w-fit px-2.5 py-1 text-xs font-semibold"
                :class="attentionBadgeClass(currentEmployee)"
              >
                {{ attentionLabel(currentEmployee) }}
              </span>
            </div>
            <p
              class="mt-4 rounded-xl border border-solid border-n-weak bg-n-slate-1 px-4 py-3 text-sm leading-6 text-n-slate-11 transition-colors duration-300 group-hover:bg-n-ruby-2/20"
            >
              {{ attentionTooltip(currentEmployee) }}
            </p>
            <div class="mt-5 grid grid-cols-1 gap-3 text-sm sm:grid-cols-2">
              <div
                class="rounded-xl bg-n-slate-2 px-3 py-2 transition-colors duration-300 group-hover:bg-n-slate-3"
              >
                <span class="block text-xs text-n-slate-10">
                  {{ $t('EMPLOYEE_MGMT.TABLE.LAST_REPLY') }}
                </span>
                <span class="mt-1 block font-medium text-n-slate-12">
                  {{ formatSince(activityDetails.metrics.last_reply_at) }}
                </span>
              </div>
              <div
                class="rounded-xl bg-n-slate-2 px-3 py-2 transition-colors duration-300 group-hover:bg-n-slate-3"
              >
                <span class="block text-xs text-n-slate-10">
                  {{ $t('EMPLOYEE_MGMT.TABLE.LAST_ACTIVITY') }}
                </span>
                <span class="mt-1 block font-medium text-n-slate-12">
                  {{ formatSince(activityDetails.metrics.last_activity_at) }}
                </span>
              </div>
              <div
                class="rounded-xl bg-n-slate-2 px-3 py-2 transition-colors duration-300 group-hover:bg-n-slate-3"
              >
                <span class="block text-xs text-n-slate-10">
                  {{ $t('EMPLOYEE_MGMT.TABLE.IDLE_DURATION') }}
                </span>
                <span class="mt-1 block font-medium text-n-slate-12">
                  {{ formatDuration(activityDetails.metrics.idle_duration) }}
                </span>
              </div>
              <div
                class="rounded-xl bg-n-slate-2 px-3 py-2 transition-colors duration-300 group-hover:bg-n-slate-3"
              >
                <span class="block text-xs text-n-slate-10">
                  {{ $t('EMPLOYEE_MGMT.TABLE.OLDEST_WAITING') }}
                </span>
                <span
                  class="mt-1 block font-medium"
                  :class="
                    waitingTextClass(
                      activityDetails.metrics.oldest_waiting_customer_seconds
                    )
                  "
                >
                  {{
                    formatDuration(
                      activityDetails.metrics.oldest_waiting_customer_seconds
                    )
                  }}
                </span>
              </div>
            </div>
          </section>

          <section
            class="group relative min-w-0 overflow-hidden rounded-2xl border border-solid border-n-weak bg-n-solid-1 p-5 shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:border-n-amber-6 hover:shadow-xl hover:shadow-n-amber-3/20"
          >
            <span
              class="absolute top-0 h-full w-1 animate-pulse bg-n-amber-6 opacity-80 ltr:left-0 rtl:right-0"
            />
            <div class="mb-3 flex items-center justify-between gap-3">
              <div class="flex min-w-0 items-start gap-3">
                <span
                  class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-n-amber-3 text-xl text-n-amber-11 ring-1 ring-n-amber-5/30 transition-transform duration-300 group-hover:scale-110"
                >
                  <span class="i-lucide-briefcase-business" />
                </span>
                <div class="min-w-0">
                  <span
                    class="text-xs font-semibold uppercase text-n-slate-10 ltr:tracking-wider rtl:tracking-normal"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.WORKLOAD') }}
                  </span>
                  <h3
                    class="mt-1 truncate text-lg font-semibold text-n-slate-12"
                  >
                    {{ $t('EMPLOYEE_MGMT.DETAILS.DELAYED_CONVERSATIONS') }}
                  </h3>
                </div>
              </div>
              <span
                class="rounded-md bg-n-ruby-2 px-2 py-1 text-xs font-semibold text-n-ruby-11"
              >
                {{
                  activityDetails.delayed_conversations.length ||
                  $t('EMPLOYEE_MGMT.EMPTY')
                }}
              </span>
            </div>
            <div
              v-if="activityDetails.delayed_conversations.length"
              class="max-h-80 overflow-y-auto overflow-x-hidden rounded-xl border border-solid border-n-weak"
            >
              <div
                v-for="conversation in activityDetails.delayed_conversations"
                :key="conversation.id"
                class="grid grid-cols-[minmax(0,1fr)_auto] gap-4 border-b border-n-weak px-4 py-3 text-sm transition-colors duration-200 hover:bg-n-slate-2 last:border-b-0"
              >
                <div class="min-w-0">
                  <span class="block truncate font-medium text-n-slate-12">
                    {{ conversationLabel(conversation) }}
                  </span>
                  <span class="block text-xs text-n-slate-10">
                    {{ formatDate(conversation.last_activity_at) }}
                  </span>
                </div>
                <span class="shrink-0 font-semibold text-n-ruby-11">
                  {{
                    formatDuration(
                      (Date.now() -
                        new Date(conversation.waiting_since).getTime()) /
                        1000
                    )
                  }}
                </span>
              </div>
            </div>
            <div
              v-else
              class="rounded-lg border border-dashed border-n-weak p-5 text-center text-sm text-n-slate-11"
            >
              {{ $t('EMPLOYEE_MGMT.DETAILS.NO_DELAYED') }}
            </div>
          </section>
        </div>

        <div class="grid grid-cols-1 gap-5 lg:grid-cols-2">
          <section
            class="min-w-0 rounded-xl border border-solid border-n-weak bg-n-solid-2 p-5"
          >
            <h3 class="mb-3 text-base font-semibold text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.DETAILS.TIMELINE') }}
            </h3>
            <div
              v-if="activityDetails.timeline.length"
              class="max-h-96 overflow-y-auto overflow-x-hidden"
            >
              <div
                v-for="event in activityDetails.timeline"
                :key="`${event.event_type}-${event.occurred_at}`"
                class="grid grid-cols-[1rem_1fr] gap-3 border-b border-n-weak py-3 last:border-b-0"
              >
                <span class="mt-1 h-2 w-2 rounded-full bg-n-blue-8" />
                <div class="min-w-0">
                  <span class="block text-sm font-medium text-n-slate-12">
                    {{ timelineLabel(event) }}
                  </span>
                  <span class="mt-1 block text-xs text-n-slate-10">
                    {{ formatDate(event.occurred_at) }}
                  </span>
                </div>
              </div>
            </div>
            <div v-else class="text-sm text-n-slate-11">
              {{ $t('EMPLOYEE_MGMT.DETAILS.NO_ACTIVITY') }}
            </div>
          </section>

          <section
            class="min-w-0 rounded-xl border border-solid border-n-weak bg-n-solid-2 p-5"
          >
            <h3 class="mb-3 text-base font-semibold text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.DETAILS.RECENT_REPLIES') }}
            </h3>
            <div
              v-if="activityDetails.recent_replies.length"
              class="max-h-96 overflow-y-auto overflow-x-hidden"
            >
              <div
                v-for="reply in activityDetails.recent_replies"
                :key="reply.id"
                class="border-b border-n-weak py-3 last:border-b-0"
              >
                <span class="block text-sm font-medium text-n-slate-12">
                  {{
                    $t('EMPLOYEE_MGMT.DETAILS.CONVERSATION', {
                      id: reply.conversation_display_id,
                    })
                  }}
                </span>
                <span class="mt-1 block truncate text-sm text-n-slate-11">
                  {{ reply.content || $t('EMPLOYEE_MGMT.EMPTY') }}
                </span>
                <span class="mt-1 block text-xs text-n-slate-10">
                  {{ formatDate(reply.created_at) }}
                </span>
              </div>
            </div>
            <div v-else class="text-sm text-n-slate-11">
              {{ $t('EMPLOYEE_MGMT.DETAILS.NO_REPLIES') }}
            </div>
          </section>

          <section
            class="min-w-0 rounded-xl border border-solid border-n-weak bg-n-solid-2 p-5 lg:col-span-2"
          >
            <h3 class="mb-3 text-base font-semibold text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.DETAILS.OPEN_CONVERSATIONS') }}
            </h3>
            <div
              v-if="activityDetails.open_conversations.length"
              class="max-h-80 overflow-y-auto overflow-x-hidden"
            >
              <div
                v-for="conversation in activityDetails.open_conversations"
                :key="conversation.id"
                class="flex items-center justify-between gap-3 border-b border-n-weak py-3 text-sm last:border-b-0"
              >
                <span class="truncate font-medium text-n-slate-12">
                  {{ conversationLabel(conversation) }}
                </span>
                <span class="shrink-0 text-xs text-n-slate-10">
                  {{ formatDate(conversation.last_activity_at) }}
                </span>
              </div>
            </div>
            <div v-else class="text-sm text-n-slate-11">
              {{ $t('EMPLOYEE_MGMT.DETAILS.NO_OPEN_CONVERSATIONS') }}
            </div>
          </section>
        </div>

        <div class="grid grid-cols-1 gap-5 lg:grid-cols-2">
          <section
            class="min-w-0 rounded-xl border border-solid border-n-weak bg-n-solid-2 p-5"
          >
            <h3 class="mb-3 text-base font-semibold text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.DETAILS.SESSIONS') }}
            </h3>
            <div
              v-if="sessions.length"
              class="max-h-72 overflow-y-auto overflow-x-hidden"
            >
              <div
                v-for="session in sessions"
                :key="session.client_id"
                class="flex items-center justify-between gap-3 border-b border-n-weak py-3 last:border-b-0"
              >
                <div class="min-w-0">
                  <span class="block text-sm font-medium text-n-slate-12">
                    {{ session.ip_address || $t('EMPLOYEE_MGMT.EMPTY') }}
                  </span>
                  <span class="block truncate text-xs text-n-slate-11">
                    {{ session.user_agent }}
                  </span>
                  <span class="block text-xs text-n-slate-10">
                    {{
                      formatDate(session.last_seen_at || session.signed_in_at)
                    }}
                  </span>
                </div>
                <Button
                  v-if="session.open"
                  xs
                  ruby
                  faded
                  :label="$t('EMPLOYEE_MGMT.DETAILS.LOGOUT_SESSION')"
                  @click="logoutSession(session)"
                />
              </div>
            </div>
            <div
              v-else
              class="rounded-lg border border-dashed border-n-weak p-5 text-center text-sm text-n-slate-11"
            >
              {{ $t('EMPLOYEE_MGMT.DETAILS.NO_SESSIONS') }}
            </div>
          </section>

          <section
            class="min-w-0 rounded-xl border border-solid border-n-weak bg-n-solid-2 p-5"
          >
            <h3 class="mb-3 text-base font-semibold text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.DETAILS.LOGIN_HISTORY') }}
            </h3>
            <div
              v-if="loginHistory.length"
              class="max-h-72 overflow-y-auto overflow-x-hidden"
            >
              <div
                v-for="event in loginHistory"
                :key="event.id"
                class="grid grid-cols-[auto_1fr_auto] gap-3 border-b border-n-weak py-3 text-sm last:border-b-0"
              >
                <span
                  class="inline-flex h-6 items-center rounded-md px-2 text-xs font-semibold"
                  :class="
                    event.success
                      ? 'bg-n-teal-2 text-n-teal-11'
                      : 'bg-n-ruby-2 text-n-ruby-11'
                  "
                >
                  {{
                    event.success
                      ? $t('EMPLOYEE_MGMT.DETAILS.SUCCESS')
                      : $t('EMPLOYEE_MGMT.DETAILS.FAILED')
                  }}
                </span>
                <span class="truncate text-n-slate-11">
                  {{ event.ip_address || $t('EMPLOYEE_MGMT.EMPTY') }}
                </span>
                <span class="text-xs text-n-slate-10">
                  {{ formatDate(event.created_at) }}
                </span>
              </div>
            </div>
            <div
              v-else
              class="rounded-lg border border-dashed border-n-weak p-5 text-center text-sm text-n-slate-11"
            >
              {{ $t('EMPLOYEE_MGMT.DETAILS.NO_LOGIN_HISTORY') }}
            </div>
          </section>
        </div>
      </section>
      <section v-else class="p-8 text-sm text-n-slate-11">
        {{ $t('EMPLOYEE_MGMT.LOADING') }}
      </section>
    </div>
  </woot-modal>

  <woot-modal
    v-model:show="showReasonModal"
    :on-close="() => (showReasonModal = false)"
  >
    <div class="flex flex-col gap-4 p-6">
      <woot-modal-header
        :header-title="$t('EMPLOYEE_MGMT.REASON_MODAL.TITLE')"
        :header-content="$t('EMPLOYEE_MGMT.REASON_MODAL.DESCRIPTION')"
      />
      <form class="flex flex-col gap-4" @submit.prevent="confirmReasonAction">
        <label>
          {{ $t('EMPLOYEE_MGMT.FORM.DEACTIVATION_REASON') }}
          <textarea v-model="reasonForm.reason" rows="3" />
        </label>
        <div class="flex justify-end gap-2">
          <Button
            type="button"
            faded
            slate
            :label="$t('EMPLOYEE_MGMT.CANCEL')"
            @click="showReasonModal = false"
          />
          <Button type="submit" :label="$t('EMPLOYEE_MGMT.SAVE')" />
        </div>
      </form>
    </div>
  </woot-modal>

  <woot-modal
    v-model:show="showDeleteModal"
    :on-close="() => (showDeleteModal = false)"
  >
    <div class="flex flex-col gap-4 p-6">
      <woot-modal-header
        :header-title="$t('EMPLOYEE_MGMT.DELETE_MODAL.TITLE')"
        :header-content="$t('EMPLOYEE_MGMT.DELETE_MODAL.DESCRIPTION')"
      />
      <div class="flex justify-end gap-2">
        <Button
          type="button"
          faded
          slate
          :label="$t('EMPLOYEE_MGMT.CANCEL')"
          @click="showDeleteModal = false"
        />
        <Button
          ruby
          :label="$t('EMPLOYEE_MGMT.DELETE_MODAL.CONFIRM')"
          @click="confirmDeleteEmployee"
        />
      </div>
    </div>
  </woot-modal>
</template>

<style scoped>
.i-lucide-search {
  display: inline-block !important;
}
</style>
