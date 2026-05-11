<script setup>
import { computed, onMounted, reactive, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import EmployeeAPI from 'dashboard/api/employees';
import {
  getInboxIconByType,
  getReadableInboxByType,
} from 'dashboard/helper/inbox';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();
const isRTL = computed(() => getters['accounts/isRTL'].value);

const employees = ref([]);
const activityDetails = ref(null);
const isFetching = ref(false);
const isSaving = ref(false);
const selectedIds = ref([]);
const showFormModal = ref(false);
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

const sortState = reactive({
  key: 'presence',
  direction: 'asc',
});

const activeFilterCard = ref(null);
const firstFieldRef = ref(null);
const openDropdownId = ref(null);
const inboxSearchQuery = ref('');
const showRoleDropdown = ref(false);

const toggleDropdown = id => {
  if (openDropdownId.value === id) {
    openDropdownId.value = null;
  } else {
    openDropdownId.value = id;
  }
};

const form = reactive({
  name: '',
  email: '',
  phone_number: '',
  username: '',
  role: 'agent',
  team_ids: [],
  inbox_ids: [],
  job_title: '',
  employee_notes: '',
  active: true,
  deactivation_reason: '',
  password: '',
  password_confirmation: '',
});

const reasonForm = reactive({
  reason: '',
});

const teams = computed(() => getters['teams/getTeams'].value || []);
const inboxes = computed(() => getters['inboxes/getInboxes'].value || []);
const inboxesUiFlags = computed(
  () => getters['inboxes/getUIFlags'].value || {}
);
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
// TODO: Re-enable when not_responding logic accounts for old unresolved conversations
// const notRespondingEmployees = computed(
//   () =>
//     employees.value.filter(
//       employee => workStatus(employee) === 'not_responding'
//     ).length
// );

const passwordScore = computed(() => {
  const password = form.password;
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

const passwordStrengthBarClass = computed(() => {
  if (passwordStrength.value === 'strong') return 'bg-n-teal-8';
  if (passwordStrength.value === 'medium') return 'bg-n-amber-8';
  return 'bg-gradient-to-r from-n-ruby-8 to-n-amber-8';
});

const canSubmitPassword = computed(() => {
  const password = form.password;
  const confirmation = form.password_confirmation;
  // In edit mode, empty password is fine (means no change)
  if (isEditing.value && !form.password && !form.password_confirmation) {
    return true;
  }
  return passwordStrength.value !== 'weak' && password === confirmation;
});

const requiredFieldsPresent = computed(() => {
  const requiredFields = [form.name, form.email];
  const hasPassword = isEditing.value || canSubmitPassword.value;
  return (
    requiredFields.every(value => value?.toString().trim()) &&
    hasPassword &&
    form.inbox_ids.length > 0
  );
});

const saveDisabledReason = computed(() => {
  if (isSaving.value) return '';
  if (!form.name.trim()) return t('EMPLOYEE_MGMT.VALIDATION.NAME_REQUIRED');
  if (!(form.email || '').trim())
    return t('EMPLOYEE_MGMT.VALIDATION.EMAIL_REQUIRED');
  if (!form.inbox_ids.length)
    return t('EMPLOYEE_MGMT.VALIDATION.INBOX_REQUIRED');
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
    email: '',
    phone_number: '',
    username: '',
    role: 'agent',
    team_ids: [],
    inbox_ids: [],
    job_title: '',
    employee_notes: '',
    active: true,
    deactivation_reason: '',
    password: '',
    password_confirmation: '',
  });
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

const roleOptions = computed(() => [
  { value: 'administrator', label: t('EMPLOYEE_MGMT.ROLES.ADMINISTRATOR') },
  { value: 'agent', label: t('EMPLOYEE_MGMT.ROLES.AGENT') },
]);

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

const presencePulseClass = employee => {
  if (presenceStatus(employee) === 'online') {
    return 'after:absolute after:inset-0 after:rounded-full after:bg-n-teal-9 after:opacity-75 after:animate-ping';
  }
  return '';
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

const attentionStatus = () => 'healthy';

const isHighWorkload = () => false;

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
    return 'border-n-brand-7 bg-n-brand-3/30 shadow-xl shadow-n-brand-9/20 ring-1 ring-n-brand-7/50';
  }

  const classes = {
    teal: 'hover:border-n-teal-7 hover:bg-n-teal-3/20 hover:shadow-n-teal-9/10',
    ruby: 'hover:border-n-ruby-7 hover:bg-n-ruby-3/20 hover:shadow-n-ruby-9/10',
    amber:
      'hover:border-n-amber-7 hover:bg-n-amber-3/20 hover:shadow-n-amber-9/10',
    blue: 'hover:border-n-blue-7 hover:bg-n-blue-3/20 hover:shadow-n-blue-9/10',
    slate:
      'hover:border-n-blue-7 hover:bg-n-slate-3/20 hover:shadow-n-blue-9/10',
  };
  return `border-n-blue-9/30 bg-n-solid-2/45 text-n-slate-12 shadow-lg shadow-n-blue-12/10 ${classes[card.tone]}`;
};

const summaryIconClass = card => {
  const classes = {
    teal: 'bg-n-teal-3/30 text-n-teal-11 ring-n-teal-7/40',
    ruby: 'bg-n-ruby-3/30 text-n-ruby-11 ring-n-ruby-7/40',
    amber: 'bg-n-amber-3/30 text-n-amber-11 ring-n-amber-7/40',
    blue: 'bg-n-blue-3/30 text-n-blue-11 ring-n-blue-7/40',
    slate: 'bg-n-slate-3/30 text-n-slate-11 ring-n-slate-7/40',
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

const performanceCardClass = card => {
  const classes = {
    teal: 'border-n-teal-7/30 bg-n-teal-3/15 text-n-teal-11',
    ruby: 'border-n-ruby-7/30 bg-n-ruby-3/15 text-n-ruby-11',
    amber: 'border-n-amber-7/30 bg-n-amber-3/15 text-n-amber-11',
    blue: 'border-n-blue-7/30 bg-n-blue-3/15 text-n-blue-11',
    slate: 'border-n-blue-9/30 bg-n-solid-2/50 text-n-slate-11',
  };
  return classes[card.tone] || classes.slate;
};

const formatCairoTime = value => {
  if (!value) return t('EMPLOYEE_MGMT.EMPTY');

  return new Intl.DateTimeFormat(undefined, {
    timeZone: 'Africa/Cairo',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
};

const formatReportDuration = seconds => {
  if (seconds === null || seconds === undefined)
    return t('EMPLOYEE_MGMT.EMPTY');
  return formatDuration(seconds);
};

const availabilityLabel = employee => {
  if (employee?.availability_status === 'busy') {
    return t('EMPLOYEE_MGMT.PRESENCE.BUSY');
  }
  return presenceLabel(employee);
};

const activityMetrics = computed(() => activityDetails.value?.metrics || {});
const dailyPerformance = computed(
  () => activityDetails.value?.daily_performance || {}
);

const hasDailyPerformanceData = computed(() => {
  const report = dailyPerformance.value;
  return Boolean(
    report.first_login_at ||
      report.last_activity_at ||
      report.last_reply_at ||
      report.messages_count ||
      report.customers_replied_count
  );
});

const employeeProfileItems = computed(() => [
  {
    key: 'email',
    label: t('EMPLOYEE_MGMT.DETAILS.EMAIL'),
    value: currentEmployee.value?.email || t('EMPLOYEE_MGMT.EMPTY'),
    icon: 'i-lucide-mail',
  },
  {
    key: 'account_status',
    label: t('EMPLOYEE_MGMT.DETAILS.ACCOUNT_STATUS'),
    value: currentEmployee.value
      ? statusLabel(currentEmployee.value)
      : t('EMPLOYEE_MGMT.EMPTY'),
    icon: 'i-lucide-shield-check',
  },
  {
    key: 'connection_status',
    label: t('EMPLOYEE_MGMT.DETAILS.CONNECTION_STATUS'),
    value: currentEmployee.value
      ? availabilityLabel(currentEmployee.value)
      : t('EMPLOYEE_MGMT.EMPTY'),
    icon: 'i-lucide-wifi',
  },
  {
    key: 'last_seen',
    label: t('EMPLOYEE_MGMT.DETAILS.LAST_SEEN'),
    value: formatSince(dailyPerformance.value.last_seen_at),
    icon: 'i-lucide-eye',
  },
  {
    key: 'last_reply',
    label: t('EMPLOYEE_MGMT.DETAILS.LAST_REPLY'),
    value: formatSince(activityMetrics.value.last_reply_at),
    icon: 'i-lucide-reply',
  },
]);

const dailyPerformanceCards = computed(() => {
  const report = dailyPerformance.value;
  return [
    {
      key: 'first_login',
      label: t('EMPLOYEE_MGMT.DETAILS.FIRST_LOGIN'),
      value: formatCairoTime(report.first_login_at),
      icon: 'i-lucide-log-in',
      tone: 'blue',
    },
    {
      key: 'last_activity',
      label: t('EMPLOYEE_MGMT.DETAILS.LAST_ACTIVITY'),
      value: formatCairoTime(report.last_activity_at),
      icon: 'i-lucide-activity',
      tone: 'teal',
    },
    {
      key: 'last_reply',
      label: t('EMPLOYEE_MGMT.DETAILS.LAST_REPLY'),
      value: formatCairoTime(report.last_reply_at),
      icon: 'i-lucide-reply',
      tone: 'blue',
    },
    {
      key: 'messages',
      label: t('EMPLOYEE_MGMT.DETAILS.MESSAGES_TODAY'),
      value: report.messages_count || 0,
      icon: 'i-lucide-send',
      tone: 'teal',
    },
    {
      key: 'customers',
      label: t('EMPLOYEE_MGMT.DETAILS.CUSTOMERS_REPLIED'),
      value: report.customers_replied_count || 0,
      icon: 'i-lucide-users-round',
      tone: 'teal',
    },
    {
      key: 'average_response',
      label: t('EMPLOYEE_MGMT.DETAILS.AVG_RESPONSE'),
      value: formatReportDuration(report.average_response_seconds),
      icon: 'i-lucide-timer',
      tone: 'amber',
    },
    {
      key: 'fastest_response',
      label: t('EMPLOYEE_MGMT.DETAILS.FASTEST_RESPONSE'),
      value: formatReportDuration(report.fastest_response_seconds),
      icon: 'i-lucide-zap',
      tone: 'teal',
    },
    {
      key: 'slowest_response',
      label: t('EMPLOYEE_MGMT.DETAILS.SLOWEST_RESPONSE'),
      value: formatReportDuration(report.slowest_response_seconds),
      icon: 'i-lucide-hourglass',
      tone: 'ruby',
    },
    {
      key: 'idle_duration',
      label: t('EMPLOYEE_MGMT.DETAILS.IDLE_DURATION'),
      value: formatReportDuration(report.idle_duration),
      icon: 'i-lucide-clock-3',
      tone: 'slate',
    },
  ];
});

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

const sortColumns = [
  'employee',
  'status',
  'presence',
  'work_status',
  'activity',
  'replies_today',
];

const defaultSortDirections = {
  employee: 'asc',
  status: 'asc',
  presence: 'asc',
  work_status: 'asc',
  activity: 'desc',
  replies_today: 'desc',
};

const toggleSort = key => {
  if (!sortColumns.includes(key)) return;

  if (sortState.key === key) {
    sortState.direction = sortState.direction === 'asc' ? 'desc' : 'asc';
    return;
  }

  sortState.key = key;
  sortState.direction = defaultSortDirections[key];
};

const sortIcon = key => {
  if (sortState.key !== key) return 'i-lucide-arrow-up-down';
  return sortState.direction === 'asc'
    ? 'i-lucide-arrow-up-narrow-wide'
    : 'i-lucide-arrow-down-wide-narrow';
};

const statusSortRank = employee => {
  if (employee.archived_at) return 2;
  return employee.active ? 0 : 1;
};

const presenceSortRank = employee =>
  presenceStatus(employee) === 'online' ? 0 : 1;

const workStatusSortRank = employee => {
  const ranks = {
    working: 0,
    idle: 1,
    not_responding: 2,
  };
  return ranks[workStatus(employee)] ?? 3;
};

const timestampSortValue = value => {
  if (!value) return 0;
  return new Date(value).getTime() || 0;
};

const sortValue = (employee, key) => {
  if (key === 'employee') {
    return (employee.name || employee.username || '').toLowerCase();
  }
  if (key === 'status') return statusSortRank(employee);
  if (key === 'presence') return presenceSortRank(employee);
  if (key === 'work_status') return workStatusSortRank(employee);
  if (key === 'activity')
    return timestampSortValue(metric(employee).last_reply_at);
  if (key === 'replies_today')
    return Number(metric(employee).replies_count_today) || 0;
  return '';
};

const compareSortValues = (first, second) => {
  if (typeof first === 'string' || typeof second === 'string') {
    return first.toString().localeCompare(second.toString(), undefined, {
      sensitivity: 'base',
    });
  }
  return first - second;
};

const sortEmployees = employeeList =>
  [...employeeList].sort((a, b) => {
    const direction = sortState.direction === 'asc' ? 1 : -1;
    const primary = compareSortValues(
      sortValue(a, sortState.key),
      sortValue(b, sortState.key)
    );
    if (primary) return primary * direction;

    return (a.name || '').localeCompare(b.name || '', undefined, {
      sensitivity: 'base',
    });
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

  return sortEmployees(result);
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

const normalizedInboxQuery = computed(() =>
  inboxSearchQuery.value.trim().toLowerCase()
);

const filteredInboxes = computed(() => {
  if (!normalizedInboxQuery.value) return inboxes.value;

  return inboxes.value.filter(inbox => {
    const readableType = getReadableInboxByType(
      inbox.channel_type,
      inbox.phone_number
    );
    return [inbox.name, inbox.email, inbox.phone_number, readableType]
      .filter(Boolean)
      .some(value =>
        value.toString().toLowerCase().includes(normalizedInboxQuery.value)
      );
  });
});

const filteredInboxIds = computed(() =>
  filteredInboxes.value.map(inbox => inbox.id)
);

const selectedInboxCount = computed(() => form.inbox_ids.length);

const selectedInboxes = computed(() =>
  inboxes.value.filter(inbox => form.inbox_ids.includes(inbox.id))
);

const selectedInboxPreview = computed(() => selectedInboxes.value.slice(0, 4));

const hiddenSelectedInboxCount = computed(() =>
  Math.max(selectedInboxCount.value - selectedInboxPreview.value.length, 0)
);

const allFilteredInboxesSelected = computed(
  () =>
    filteredInboxIds.value.length > 0 &&
    filteredInboxIds.value.every(id => form.inbox_ids.includes(id))
);

const isInboxSelected = inboxId => form.inbox_ids.includes(inboxId);

const toggleInbox = inboxId => {
  if (isInboxSelected(inboxId)) {
    form.inbox_ids = form.inbox_ids.filter(id => id !== inboxId);
  } else {
    form.inbox_ids = [...form.inbox_ids, inboxId];
  }
};

const toggleFilteredInboxes = () => {
  if (allFilteredInboxesSelected.value) {
    form.inbox_ids = form.inbox_ids.filter(
      id => !filteredInboxIds.value.includes(id)
    );
    return;
  }

  form.inbox_ids = Array.from(
    new Set([...form.inbox_ids, ...filteredInboxIds.value])
  );
};

const clearInboxSelection = () => {
  form.inbox_ids = [];
};

const inboxChannelLabel = inbox => {
  const readableType = getReadableInboxByType(
    inbox.channel_type,
    inbox.phone_number
  ).toUpperCase();
  const labels = {
    LIVECHAT: t('EMPLOYEE_MGMT.FORM.CHANNELS.LIVECHAT'),
    FACEBOOK: t('EMPLOYEE_MGMT.FORM.CHANNELS.FACEBOOK'),
    TWITTER: t('EMPLOYEE_MGMT.FORM.CHANNELS.TWITTER'),
    WHATSAPP: t('EMPLOYEE_MGMT.FORM.CHANNELS.WHATSAPP'),
    SMS: t('EMPLOYEE_MGMT.FORM.CHANNELS.SMS'),
    API: t('EMPLOYEE_MGMT.FORM.CHANNELS.API'),
    EMAIL: t('EMPLOYEE_MGMT.FORM.CHANNELS.EMAIL'),
    TELEGRAM: t('EMPLOYEE_MGMT.FORM.CHANNELS.TELEGRAM'),
    LINE: t('EMPLOYEE_MGMT.FORM.CHANNELS.LINE'),
    VOICE: t('EMPLOYEE_MGMT.FORM.CHANNELS.VOICE'),
    CHAT: t('EMPLOYEE_MGMT.FORM.CHANNELS.CHAT'),
  };
  return labels[readableType] || labels.CHAT;
};

const inboxMeta = inbox => inbox.email || inbox.phone_number || '';

const inboxIconToneClass = inbox => {
  const type = getReadableInboxByType(inbox.channel_type, inbox.phone_number);
  const classes = {
    facebook: 'bg-n-blue-5 text-n-blue-12',
    whatsapp: 'bg-n-teal-5 text-n-teal-12',
    email: 'bg-n-amber-5 text-n-amber-12',
    api: 'bg-n-blue-5 text-n-blue-12',
    livechat: 'bg-n-ruby-5 text-n-ruby-12',
    chat: 'bg-n-ruby-5 text-n-ruby-12',
    sms: 'bg-n-amber-5 text-n-amber-12',
    voice: 'bg-n-teal-5 text-n-teal-12',
  };
  return classes[type] || 'bg-n-slate-5 text-n-slate-12';
};

const inboxChannelBadgeClass = inbox => {
  const type = getReadableInboxByType(inbox.channel_type, inbox.phone_number);
  const classes = {
    facebook: 'border-n-blue-7/50 bg-n-blue-3 text-n-blue-11',
    whatsapp: 'border-n-teal-7/50 bg-n-teal-3 text-n-teal-11',
    email: 'border-n-amber-7/50 bg-n-amber-3 text-n-amber-11',
    api: 'border-n-slate-7/50 bg-n-slate-3 text-n-slate-11',
    livechat: 'border-n-ruby-7/50 bg-n-ruby-3 text-n-ruby-11',
    chat: 'border-n-ruby-7/50 bg-n-ruby-3 text-n-ruby-11',
    sms: 'border-n-amber-7/50 bg-n-amber-3 text-n-amber-11',
    voice: 'border-n-teal-7/50 bg-n-teal-3 text-n-teal-11',
  };
  return classes[type] || 'border-n-slate-7/50 bg-n-slate-3 text-n-slate-11';
};

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
  inboxSearchQuery.value = '';
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
    email: employee.email || '',
    phone_number: employee.phone_number || '',
    username: employee.username || '',
    role: employee.role || 'agent',
    team_ids: employee.team_ids || [],
    inbox_ids: employee.inbox_ids || [],
    job_title: employee.job_title || '',
    employee_notes: employee.employee_notes || '',
    active: employee.active,
    deactivation_reason: employee.deactivation_reason || '',
    password: '',
    password_confirmation: '',
  });
  inboxSearchQuery.value = '';
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
      // Only include password if user entered one
      if (!payload.employee.password) {
        delete payload.employee.password;
        delete payload.employee.password_confirmation;
      }
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
  const activityResponse = await EmployeeAPI.activity(employee.id);
  activityDetails.value = activityResponse.data;
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
  if (action === 'activate') activateEmployee(employee);
  if (action === 'deactivate') deactivateEmployee(employee);
  if (action === 'activity') openDetails(employee);
  if (action === 'archive') archiveEmployee(employee);
  if (action === 'delete') deleteEmployee(employee);
};

onMounted(() => {
  fetchEmployees();
  store.dispatch('teams/get');
  store.dispatch('inboxes/get');
});
</script>

<template>
  <SettingsLayout
    class="min-h-full gap-6 bg-gradient-to-br from-n-solid-1 via-n-blue-1 to-n-solid-1 p-5 text-n-slate-12"
    :is-loading="isFetching"
    :loading-message="$t('EMPLOYEE_MGMT.LOADING')"
    :no-records-found="!employees.length"
    :no-records-message="$t('EMPLOYEE_MGMT.EMPTY_STATE')"
  >
    <template #header>
      <div
        class="flex w-full flex-col-reverse gap-4 lg:flex-row lg:items-start lg:justify-between"
      >
        <div class="flex shrink-0 flex-wrap items-center gap-3">
          <button
            type="button"
            class="inline-flex h-12 min-w-40 items-center justify-center gap-2 rounded-lg border border-solid border-n-blue-9 bg-n-blue-9 px-5 text-sm font-semibold !text-white shadow-lg shadow-n-blue-9/30 transition-colors hover:border-n-blue-10 hover:bg-n-blue-10"
            @click="openCreateModal"
          >
            {{ $t('EMPLOYEE_MGMT.ADD') }}
            <span class="i-lucide-plus h-5 w-5" />
          </button>
          <button
            type="button"
            class="inline-flex h-12 items-center justify-center gap-3 rounded-lg border border-solid border-n-blue-9/35 bg-n-solid-2/70 px-5 text-sm font-semibold text-n-slate-12 shadow-sm shadow-n-blue-12/10 transition-colors hover:border-n-blue-8 hover:bg-n-slate-3/70"
            @click="fetchEmployees"
          >
            {{ $t('EMPLOYEE_MGMT.MONITORING.REFRESH') }}
            <span
              class="h-5 w-5"
              :class="
                isFetching
                  ? 'i-lucide-loader-circle animate-spin'
                  : 'i-lucide-refresh-cw'
              "
            />
          </button>
        </div>
        <div
          class="flex min-w-0 items-start justify-end gap-5 text-end lg:ms-auto"
        >
          <div class="min-w-0">
            <div class="mb-3 flex justify-end">
              <span
                class="inline-flex items-center gap-2 rounded-lg border border-solid border-n-teal-7/40 bg-n-teal-3/20 px-4 py-2 text-xs font-semibold text-n-teal-11 shadow-sm shadow-n-teal-9/10"
                :title="lastUpdatedLabel"
              >
                {{ $t('EMPLOYEE_MGMT.MONITORING.LIVE') }}
                <span
                  class="relative h-2.5 w-2.5 rounded-full bg-n-teal-9 after:absolute after:inset-0 after:rounded-full after:bg-n-teal-9 after:opacity-75 after:animate-ping"
                />
              </span>
            </div>
            <h1 class="mb-2 text-3xl font-bold tracking-tight text-n-slate-12">
              {{ $t('EMPLOYEE_MGMT.HEADER') }}
            </h1>
            <p class="mb-0 text-sm text-n-slate-10">
              {{ $t('EMPLOYEE_MGMT.DESCRIPTION') }}
            </p>
          </div>
          <span
            class="hidden h-16 w-16 shrink-0 items-center justify-center rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/70 text-3xl text-n-blue-11 shadow-lg shadow-n-blue-12/10 sm:flex"
          >
            <span class="i-lucide-user-round" />
          </span>
        </div>
      </div>
    </template>

    <template #preBody>
      <div class="mb-5 flex w-full flex-col gap-5" :dir="isRTL ? 'rtl' : 'ltr'">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <button
            v-for="card in summaryCards"
            :key="card.key"
            type="button"
            class="group relative flex min-h-28 overflow-hidden rounded-xl border border-solid p-4 transition-all duration-200 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-brand-7 ltr:text-left rtl:text-right"
            :class="summaryCardClass(card)"
            :title="card.subtitle"
            @click="applyCardFilter(card)"
          >
            <span
              class="absolute inset-0 bg-gradient-to-br from-n-blue-9/10 via-transparent to-transparent opacity-60"
            />
            <div
              class="relative flex min-h-full w-full items-start justify-between gap-5 rtl:flex-row-reverse"
            >
              <div
                class="flex min-w-0 flex-1 flex-col ltr:items-start ltr:text-left rtl:items-end rtl:text-right"
              >
                <span class="block text-base font-semibold text-n-slate-12">
                  {{ card.label }}
                </span>
                <span
                  class="mt-2 block text-4xl font-bold leading-none tracking-tight text-n-slate-12"
                  :class="summaryValueClass(card)"
                >
                  {{ card.value }}
                </span>
                <span
                  v-if="activeFilterCard === card.key"
                  class="mt-4 rounded-full bg-n-brand-3 px-2.5 py-1 text-[10px] font-semibold uppercase text-n-brand-11"
                >
                  {{ $t('EMPLOYEE_MGMT.SUMMARY.ACTIVE_FILTER') }}
                </span>
              </div>
              <div class="flex shrink-0 flex-col items-center gap-3">
                <span
                  class="relative flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-full text-2xl ring-1"
                  :class="[
                    summaryIconClass(card),
                    summaryIconMotionClass(card),
                  ]"
                >
                  <span
                    class="absolute inset-0 opacity-20"
                    :class="toneFillClass(card.tone)"
                  />
                  <span class="relative" :class="card.icon" />
                </span>
                <span
                  class="h-2.5 w-2.5 rounded-full"
                  :class="summaryLiveDotClass(card)"
                />
              </div>
            </div>
          </button>
        </div>

        <div
          class="relative overflow-hidden rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/45 p-5 shadow-xl shadow-n-blue-12/10"
        >
          <span
            class="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-n-blue-8/60 to-transparent"
          />
          <div
            class="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-[minmax(20rem,1.35fr)_repeat(5,minmax(9rem,1fr))_auto]"
          >
            <div
              class="flex h-12 min-w-0 items-center gap-3 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/55 px-4 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
            >
              <span class="i-lucide-search h-5 w-5 shrink-0 text-n-slate-10" />
              <input
                v-model="filters.q"
                class="reset-base no-margin !mb-0 h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                type="search"
                :placeholder="$t('EMPLOYEE_MGMT.FILTERS.SEARCH')"
              />
            </div>
            <select
              v-model="filters.role"
              class="no-margin !mb-0 !h-12 min-w-0 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/55 text-sm text-n-slate-12"
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
              class="no-margin !mb-0 !h-12 min-w-0 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/55 text-sm text-n-slate-12"
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
              class="no-margin !mb-0 !h-12 min-w-0 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/55 text-sm text-n-slate-12"
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
              class="no-margin !mb-0 !h-12 min-w-0 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/55 text-sm text-n-slate-12"
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
              class="no-margin !mb-0 !h-12 min-w-0 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/55 text-sm text-n-slate-12"
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
              class="inline-flex h-12 items-center justify-center gap-2 rounded-lg border border-solid border-n-blue-9/35 bg-n-solid-1/55 px-4 text-sm font-semibold text-n-slate-12 transition-colors hover:border-n-blue-8 hover:bg-n-slate-3/70"
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
            class="mt-4 grid grid-cols-1 gap-3 rounded-xl border border-solid border-n-blue-9/25 bg-n-solid-1/45 p-4 md:grid-cols-2 xl:grid-cols-[repeat(4,minmax(10rem,1fr))_auto_auto_auto]"
          >
            <select
              v-model="filters.last_login"
              class="h-10 min-w-0 rounded-lg border-n-blue-9/30 bg-n-solid-2/70"
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
              class="h-10 min-w-0 rounded-lg border-n-blue-9/30 bg-n-solid-2/70"
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
              class="h-10 min-w-0 rounded-lg border-n-blue-9/30 bg-n-solid-2/70"
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
              class="h-10 min-w-0 rounded-lg border-n-blue-9/30 bg-n-solid-2/70"
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
              class="flex h-10 items-center gap-2 rounded-lg border border-solid border-n-blue-9/30 px-3 text-sm text-n-slate-11"
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
              class="flex h-10 items-center gap-2 rounded-lg border border-solid border-n-blue-9/30 px-3 text-sm text-n-slate-11"
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
              class="inline-flex items-center gap-2 rounded-full border border-solid border-n-blue-9/35 bg-n-solid-1/70 px-3 py-1 text-xs font-medium text-n-slate-11 hover:border-n-blue-8 hover:bg-n-slate-3/60"
              @click="clearFilter(chip.key)"
            >
              {{ chip.label }}
              <span class="i-lucide-x text-sm" />
            </button>
          </div>
        </div>
      </div>

      <div
        v-if="selectedIds.length"
        class="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/55 p-3 shadow-lg shadow-n-blue-12/10"
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
        class="relative z-10 w-full overflow-hidden rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/45 shadow-xl shadow-n-blue-12/10"
        :dir="isRTL ? 'rtl' : 'ltr'"
      >
        <div class="w-full overflow-x-auto">
          <table class="w-full min-w-[1100px] table-fixed text-sm">
            <colgroup>
              <col class="w-[40px]" />
              <col class="w-[260px]" />
              <col class="w-[96px]" />
              <col class="w-[110px]" />
              <col class="w-[110px]" />
              <col class="w-[240px]" />
              <col class="w-[80px]" />
              <col class="w-[90px]" />
            </colgroup>
            <thead
              class="sticky top-0 z-10 border-b border-solid border-n-blue-9/30 bg-n-solid-1/85 text-[11px] font-semibold uppercase tracking-wider text-n-slate-10 backdrop-blur ltr:text-left rtl:text-right"
            >
              <tr>
                <th class="w-10 px-3 py-3">
                  <input
                    type="checkbox"
                    :checked="allSelected"
                    class="cursor-pointer accent-n-teal-9"
                    @change="toggleSelectAll"
                  />
                </th>
                <th class="px-3 py-3">
                  <button
                    type="button"
                    class="inline-flex items-center gap-1 rounded-md px-2 py-1 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12"
                    @click="toggleSort('employee')"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.EMPLOYEE') }}
                    <span class="text-sm" :class="sortIcon('employee')" />
                  </button>
                </th>
                <th class="px-3 py-3 text-center">
                  <button
                    type="button"
                    class="inline-flex items-center justify-center gap-1 rounded-md px-2 py-1 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12"
                    @click="toggleSort('status')"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.STATUS') }}
                    <span class="text-sm" :class="sortIcon('status')" />
                  </button>
                </th>
                <th class="px-3 py-3 text-center">
                  <button
                    type="button"
                    class="inline-flex items-center justify-center gap-1 rounded-md px-2 py-1 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12"
                    @click="toggleSort('presence')"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.PRESENCE') }}
                    <span class="text-sm" :class="sortIcon('presence')" />
                  </button>
                </th>
                <th class="px-3 py-3 text-center">
                  <button
                    type="button"
                    class="inline-flex items-center justify-center gap-1 rounded-md px-2 py-1 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12"
                    @click="toggleSort('work_status')"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.WORK_STATUS') }}
                    <span class="text-sm" :class="sortIcon('work_status')" />
                  </button>
                </th>
                <th class="px-3 py-3">
                  <button
                    type="button"
                    class="inline-flex items-center gap-1 rounded-md px-2 py-1 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12"
                    @click="toggleSort('activity')"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.ACTIVITY') }}
                    <span class="text-sm" :class="sortIcon('activity')" />
                  </button>
                </th>
                <th class="px-3 py-3 text-center">
                  <button
                    type="button"
                    class="inline-flex items-center justify-center gap-1 rounded-md px-2 py-1 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12"
                    @click="toggleSort('replies_today')"
                  >
                    {{ $t('EMPLOYEE_MGMT.TABLE.TODAY') }}
                    <span class="text-sm" :class="sortIcon('replies_today')" />
                  </button>
                </th>
                <th class="px-2 py-3 text-center">
                  {{ $t('EMPLOYEE_MGMT.TABLE.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-n-blue-9/20 text-n-slate-12">
              <template
                v-for="employee in filteredEmployees"
                :key="employee.id"
              >
                <tr
                  class="align-middle transition-all duration-150"
                  :class="
                    presenceStatus(employee) === 'online'
                      ? 'border-y border-solid border-n-teal-7/40 bg-n-teal-4/35 shadow-[inset_4px_0_0_0_var(--teal-8)] hover:bg-n-teal-4/50'
                      : 'hover:bg-n-slate-3/20'
                  "
                >
                  <td class="px-3 py-3">
                    <input
                      v-model="selectedIds"
                      type="checkbox"
                      :value="employee.id"
                      class="cursor-pointer accent-n-teal-9"
                    />
                  </td>
                  <!-- Agent Name -->
                  <td class="px-3 py-3">
                    <div class="flex min-w-0 items-center gap-2.5">
                      <div
                        class="relative flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-xs font-bold text-n-slate-12 ring-2"
                        :class="
                          presenceStatus(employee) === 'online'
                            ? 'bg-gradient-to-br from-n-teal-4 to-n-blue-3 ring-n-teal-8/50'
                            : 'bg-gradient-to-br from-n-slate-3 to-n-slate-4 ring-n-slate-2'
                        "
                      >
                        {{ employeeInitials(employee) }}
                        <span
                          class="absolute -bottom-px h-3 w-3 rounded-full border-2 border-solid border-n-solid-1 ltr:-right-px rtl:-left-px"
                          :class="[
                            presenceDotClass(employee),
                            presencePulseClass(employee),
                          ]"
                        />
                      </div>
                      <div class="min-w-0">
                        <span
                          class="block truncate text-sm font-semibold leading-tight text-n-slate-12"
                        >
                          {{ employee.name }}
                        </span>
                        <span
                          class="mt-0.5 flex min-w-0 flex-wrap items-center gap-1"
                        >
                          <span
                            class="inline-flex shrink-0 items-center rounded border border-solid px-1.5 py-px text-[10px] font-semibold uppercase tracking-wide"
                            :class="roleBadgeClass(employee.role)"
                          >
                            {{ roleLabel(employee.role) }}
                          </span>
                          <span
                            v-if="employee.email"
                            class="min-w-0 max-w-[12rem] truncate text-[11px] font-medium text-n-slate-10"
                            :title="employee.email"
                          >
                            {{ employee.email }}
                          </span>
                          <span
                            v-for="team in employeeTeams(employee)"
                            :key="team.id"
                            class="rounded border border-solid border-n-blue-9/25 bg-n-solid-1/55 px-1.5 py-px text-[10px] font-medium text-n-slate-9"
                          >
                            {{ team.name }}
                          </span>
                        </span>
                      </div>
                    </div>
                  </td>
                  <!-- Status -->
                  <td class="px-3 py-3 text-center">
                    <span
                      class="inline-flex items-center justify-center px-2 py-0.5 text-[11px] font-semibold border border-solid rounded-full"
                      :class="statusBadgeClass(employee)"
                    >
                      {{ statusLabel(employee) }}
                    </span>
                  </td>
                  <!-- Presence -->
                  <td class="px-3 py-3 text-center">
                    <span
                      class="inline-flex items-center gap-1.5 text-xs font-medium text-n-slate-11"
                      :title="presenceTooltip(employee)"
                    >
                      <span
                        class="relative h-3 w-3 rounded-full"
                        :class="[
                          presenceDotClass(employee),
                          presencePulseClass(employee),
                        ]"
                      />
                      {{ presenceLabel(employee) }}
                    </span>
                  </td>
                  <!-- Work Status -->
                  <td class="px-3 py-3 text-center">
                    <span
                      class="inline-flex items-center justify-center px-2 py-0.5 text-[11px] font-semibold"
                      :class="workStatusBadgeClass(employee)"
                      :title="workStatusTooltip(employee)"
                    >
                      {{ workStatusLabel(employee) }}
                    </span>
                  </td>
                  <!-- Activity -->
                  <td class="px-3 py-3">
                    <div class="space-y-1 text-[11px] leading-relaxed">
                      <div class="flex items-center gap-1.5">
                        <span class="shrink-0 text-n-slate-9">{{
                          $t('EMPLOYEE_MGMT.TABLE.LAST_REPLY')
                        }}</span>
                        <span class="truncate font-medium text-n-slate-12">{{
                          formatSince(metric(employee).last_reply_at)
                        }}</span>
                      </div>
                      <div class="flex items-center gap-1.5">
                        <span class="shrink-0 text-n-slate-9">{{
                          $t('EMPLOYEE_MGMT.TABLE.LAST_ACTIVITY')
                        }}</span>
                        <span class="truncate font-medium text-n-slate-12">{{
                          formatSince(metric(employee).last_activity_at)
                        }}</span>
                      </div>
                      <div class="flex items-center gap-1.5">
                        <span class="shrink-0 text-n-slate-9">{{
                          $t('EMPLOYEE_MGMT.TABLE.IDLE_DURATION')
                        }}</span>
                        <span class="truncate font-medium text-n-slate-12">
                          {{ formatDuration(metric(employee).idle_duration) }}
                        </span>
                      </div>
                    </div>
                  </td>
                  <!-- Today -->
                  <td class="px-3 py-3 text-center">
                    <span
                      class="inline-flex h-7 min-w-7 items-center justify-center rounded-full px-2 text-xs font-bold"
                      :class="
                        metric(employee).replies_count_today > 0
                          ? 'bg-n-teal-3 text-n-teal-11'
                          : 'bg-n-slate-3 text-n-slate-10'
                      "
                    >
                      {{ metric(employee).replies_count_today || 0 }}
                    </span>
                  </td>
                  <!-- Actions -->
                  <td class="relative px-2 py-3 text-center">
                    <div class="flex justify-center gap-1">
                      <button
                        type="button"
                        class="flex h-8 w-8 items-center justify-center rounded-md border border-solid border-n-blue-9/25 bg-n-solid-1/40 text-n-slate-11 transition-colors hover:border-n-blue-8 hover:bg-n-slate-3/70 hover:text-n-slate-12 focus:outline-none"
                        @click.stop="toggleDropdown(employee.id)"
                      >
                        <span class="text-lg i-lucide-more-vertical" />
                      </button>
                    </div>

                    <div
                      v-if="openDropdownId === employee.id"
                      class="absolute top-full z-20 mt-1 w-48 origin-top-right overflow-hidden rounded-lg border border-solid border-n-blue-9/35 bg-n-solid-1 py-1 shadow-xl shadow-n-blue-12/20 focus:outline-none ltr:right-4 rtl:left-4"
                    >
                      <button
                        class="flex w-full items-center px-4 py-2 text-sm text-n-slate-11 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12 ltr:text-left rtl:text-right"
                        @click="handleEmployeeAction(employee, 'edit')"
                      >
                        <span
                          class="text-lg i-lucide-pencil ltr:mr-2 rtl:ml-2"
                        />
                        {{ $t('EMPLOYEE_MGMT.ACTIONS.EDIT') }}
                      </button>
                      <button
                        class="flex w-full items-center px-4 py-2 text-sm text-n-slate-11 transition-colors hover:bg-n-slate-3/70 hover:text-n-slate-12 ltr:text-left rtl:text-right"
                        @click="handleEmployeeAction(employee, 'activity')"
                      >
                        <span
                          class="text-lg i-lucide-activity ltr:mr-2 rtl:ml-2"
                        />
                        {{ $t('EMPLOYEE_MGMT.ACTIONS.ACTIVITY') }}
                      </button>
                      <div class="my-1 h-px w-full bg-n-blue-9/25" />
                      <button
                        class="flex w-full items-center px-4 py-2 text-sm font-medium transition-colors ltr:text-left rtl:text-right"
                        :class="
                          employee.active
                            ? 'text-n-ruby-11 hover:bg-n-ruby-3/30 hover:text-n-ruby-12'
                            : 'text-n-teal-11 hover:bg-n-teal-3/30 hover:text-n-teal-12'
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
                        class="flex w-full items-center px-4 py-2 text-sm font-medium text-n-ruby-11 transition-colors hover:bg-n-ruby-3/30 hover:text-n-ruby-12 ltr:text-left rtl:text-right"
                        @click="handleEmployeeAction(employee, 'archive')"
                      >
                        <span
                          class="text-lg i-lucide-archive ltr:mr-2 rtl:ml-2"
                        />
                        {{ $t('EMPLOYEE_MGMT.ACTIONS.ARCHIVE') }}
                      </button>
                      <button
                        class="flex w-full items-center px-4 py-2 text-sm font-medium text-n-ruby-11 transition-colors hover:bg-n-ruby-3/30 hover:text-n-ruby-12 ltr:text-left rtl:text-right"
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
              </template>
            </tbody>
          </table>
        </div>
        <div
          v-if="tableEmpty"
          class="flex flex-col items-center gap-3 border-t border-solid border-n-blue-9/25 px-6 py-10 text-center"
        >
          <span
            class="i-lucide-search-x rounded-full bg-n-slate-3/60 p-3 text-2xl text-n-slate-10"
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

  <Teleport to="body">
    <div
      v-if="showFormModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-n-black/80 p-3 backdrop-blur-md sm:p-5"
      @click.self="showFormModal = false"
    >
      <div
        class="flex h-[calc(100vh-1.5rem)] w-full max-w-[74rem] flex-col overflow-hidden rounded-2xl border border-solid border-n-blue-8/50 bg-gradient-to-br from-n-solid-1 via-n-blue-2 to-n-solid-1 shadow-2xl shadow-n-blue-12/40 sm:h-[calc(100vh-2.5rem)]"
      >
        <div
          class="flex shrink-0 items-start justify-between gap-4 px-5 pb-4 pt-6 sm:px-8"
        >
          <div class="flex min-w-0 flex-col text-start">
            <span
              class="mb-4 inline-flex w-fit items-center gap-2 rounded-lg border border-solid border-n-brand-7 bg-gradient-to-r from-n-brand-3 to-n-slate-3 px-3 py-1.5 text-xs font-semibold uppercase text-n-brand-11 shadow-sm shadow-n-brand-5/20"
            >
              <span class="i-lucide-shield-check text-base" />
              {{ $t('EMPLOYEE_MGMT.FORM.DRAWER_BADGE') }}
            </span>
            <h2 class="mb-2 text-4xl font-semibold text-n-slate-12">
              {{
                isEditing
                  ? $t('EMPLOYEE_MGMT.FORM.EDIT_TITLE')
                  : $t('EMPLOYEE_MGMT.FORM.ADD_TITLE')
              }}
            </h2>
            <p class="mb-0 text-base text-n-slate-11">
              {{ $t('EMPLOYEE_MGMT.FORM.DESCRIPTION') }}
            </p>
          </div>
          <button
            type="button"
            class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/50 text-n-slate-11 transition-colors hover:border-n-blue-8/60 hover:bg-n-slate-3 hover:text-n-slate-12"
            :title="$t('EMPLOYEE_MGMT.CANCEL')"
            @click="showFormModal = false"
          >
            <span class="i-lucide-x text-lg" />
          </button>
        </div>

        <form
          class="flex min-h-0 flex-1 flex-col"
          @submit.prevent="saveEmployee"
        >
          <div
            class="grid min-h-0 flex-1 grid-cols-1 gap-5 overflow-y-auto px-5 pb-5 pt-2 sm:px-8 xl:grid-cols-[minmax(0,0.9fr)_minmax(24rem,1.1fr)] xl:items-start"
          >
            <section
              class="grid grid-cols-1 gap-5 rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/40 p-5 shadow-sm shadow-n-blue-12/10 md:grid-cols-2 xl:col-start-1 xl:row-start-1"
            >
              <div
                class="flex items-start gap-3 border-b border-solid border-n-blue-9/20 pb-4 text-start md:col-span-2"
              >
                <span
                  class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-8/40 bg-gradient-to-br from-n-brand-4 to-n-solid-3 text-n-blue-12"
                >
                  <span class="i-lucide-user-round text-xl" />
                </span>
                <div class="min-w-0">
                  <h3 class="mb-1 text-base font-semibold text-n-slate-12">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.IDENTITY') }}
                  </h3>
                  <p class="mb-0 text-sm text-n-slate-10">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTION_DESCRIPTIONS.IDENTITY') }}
                  </p>
                </div>
              </div>
              <label class="flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.NAME') }}
                  <span class="text-n-ruby-9">{{
                    $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                  }}</span>
                </span>
                <div
                  class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
                >
                  <span
                    class="i-lucide-user h-4 w-4 shrink-0 text-n-slate-10"
                  />
                  <input
                    ref="firstFieldRef"
                    v-model="form.name"
                    required
                    type="text"
                    class="reset-base h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                    :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.NAME')"
                  />
                </div>
                <span
                  v-if="!form.name.trim()"
                  class="mt-1 text-xs text-n-ruby-11"
                >
                  {{ $t('EMPLOYEE_MGMT.VALIDATION.NAME_REQUIRED') }}
                </span>
              </label>
              <label class="flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.PHONE') }}
                </span>
                <div
                  class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
                >
                  <span
                    class="i-lucide-phone h-4 w-4 shrink-0 text-n-slate-10"
                  />
                  <input
                    v-model="form.phone_number"
                    type="text"
                    class="reset-base h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                    :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.PHONE')"
                  />
                </div>
              </label>
              <label class="flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.EMAIL') }}
                  <span class="text-n-ruby-9">{{
                    $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                  }}</span>
                </span>
                <div
                  class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
                >
                  <span
                    class="i-lucide-mail h-4 w-4 shrink-0 text-n-slate-10"
                  />
                  <input
                    v-model="form.email"
                    required
                    type="email"
                    class="reset-base h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                    :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.EMAIL')"
                  />
                </div>
                <span
                  v-if="!(form.email || '').trim()"
                  class="mt-1 text-xs text-n-ruby-11"
                >
                  {{ $t('EMPLOYEE_MGMT.VALIDATION.EMAIL_REQUIRED') }}
                </span>
              </label>
              <label class="flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.USERNAME') }}
                </span>
                <div
                  class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
                >
                  <span
                    class="i-lucide-at-sign h-4 w-4 shrink-0 text-n-slate-10"
                  />
                  <input
                    v-model="form.username"
                    type="text"
                    class="reset-base h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                    :placeholder="
                      $t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.USERNAME')
                    "
                  />
                </div>
              </label>
            </section>

            <section
              class="grid grid-cols-1 gap-5 rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/40 p-5 shadow-sm shadow-n-blue-12/10 md:grid-cols-2 xl:col-start-2 xl:row-span-3 xl:row-start-1"
            >
              <div
                class="flex items-start gap-3 border-b border-solid border-n-blue-9/20 pb-4 text-start md:col-span-2"
              >
                <span
                  class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-8/40 bg-gradient-to-br from-n-brand-4 to-n-solid-3 text-n-blue-12"
                >
                  <span class="i-lucide-shield-check text-xl" />
                </span>
                <div class="min-w-0">
                  <h3 class="mb-1 text-base font-semibold text-n-slate-12">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.ACCESS') }}
                  </h3>
                  <p class="mb-0 text-sm text-n-slate-10">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTION_DESCRIPTIONS.ACCESS') }}
                  </p>
                </div>
              </div>
              <div class="flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.ROLE') }}
                  <span class="text-n-ruby-9">{{
                    $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                  }}</span>
                </span>
                <div class="relative">
                  <button
                    type="button"
                    class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 text-start text-sm text-n-slate-12 transition-colors hover:border-n-blue-8 focus:border-n-brand-7 focus:outline-none focus:ring-1 focus:ring-n-brand-7/30"
                    @click="showRoleDropdown = !showRoleDropdown"
                  >
                    <span
                      class="i-lucide-user h-4 w-4 shrink-0 text-n-slate-10"
                    />
                    <span class="min-w-0 flex-1 truncate">
                      {{ roleLabel(form.role) }}
                    </span>
                    <span
                      class="i-lucide-chevron-down h-4 w-4 shrink-0 text-n-slate-10 transition-transform"
                      :class="showRoleDropdown ? 'rotate-180' : ''"
                    />
                  </button>
                  <div
                    v-if="showRoleDropdown"
                    class="absolute inset-x-0 top-full z-40 mt-2 overflow-hidden rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1 py-1 shadow-xl shadow-n-blue-12/20"
                  >
                    <button
                      v-for="option in roleOptions"
                      :key="option.value"
                      type="button"
                      class="flex w-full items-center gap-3 px-3 py-2 text-start text-sm transition-colors"
                      :class="
                        form.role === option.value
                          ? 'bg-n-brand-3 text-n-brand-12'
                          : 'text-n-slate-11 hover:bg-n-slate-3 hover:text-n-slate-12'
                      "
                      @click="
                        form.role = option.value;
                        showRoleDropdown = false;
                      "
                    >
                      <span
                        class="h-4 w-4 shrink-0"
                        :class="
                          form.role === option.value
                            ? 'i-lucide-circle-check text-n-brand-11'
                            : 'i-lucide-circle text-n-slate-10'
                        "
                      />
                      <span class="min-w-0 flex-1 truncate">
                        {{ option.label }}
                      </span>
                    </button>
                  </div>
                </div>
              </div>
              <label class="flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.JOB_TITLE') }}
                </span>
                <div
                  class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
                >
                  <span
                    class="i-lucide-briefcase-business h-4 w-4 shrink-0 text-n-slate-10"
                  />
                  <input
                    v-model="form.job_title"
                    type="text"
                    class="reset-base h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                    :placeholder="
                      $t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.JOB_TITLE')
                    "
                  />
                </div>
              </label>
              <div class="flex flex-col text-start md:col-span-2">
                <span class="mb-2 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.TEAMS') }}
                </span>
                <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
                  <label
                    v-for="team in teams"
                    :key="team.id"
                    class="m-0 flex min-h-12 cursor-pointer items-center gap-3 rounded-lg border border-solid px-3 py-2 transition-colors"
                    :class="
                      isTeamSelected(team.id)
                        ? 'border-n-brand-7 bg-n-brand-3 text-n-brand-12'
                        : 'border-n-blue-9/20 bg-n-solid-1/60 hover:border-n-blue-8/40 hover:bg-n-slate-2'
                    "
                  >
                    <input
                      type="checkbox"
                      class="h-4 w-4 rounded border-n-slate-4 text-n-brand-9 focus:ring-n-brand-5"
                      :checked="isTeamSelected(team.id)"
                      @change="toggleTeam(team.id)"
                    />
                    <span
                      class="i-lucide-users h-4 w-4 shrink-0 text-n-slate-10"
                    />
                    <span class="min-w-0 truncate text-sm font-medium">
                      {{ team.name }}
                    </span>
                  </label>
                </div>
              </div>

              <div class="flex flex-col gap-3 text-start md:col-span-2">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div class="flex flex-col">
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ $t('EMPLOYEE_MGMT.FORM.INBOXES') }}
                      <span class="text-n-ruby-9">{{
                        $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                      }}</span>
                    </span>
                    <span
                      class="text-xs"
                      :class="
                        selectedInboxCount
                          ? 'text-n-slate-10'
                          : 'text-n-ruby-11'
                      "
                    >
                      {{
                        selectedInboxCount
                          ? $t('EMPLOYEE_MGMT.FORM.INBOXES_SELECTED', {
                              count: selectedInboxCount,
                              total: inboxes.length,
                            })
                          : $t('EMPLOYEE_MGMT.VALIDATION.INBOX_REQUIRED')
                      }}
                    </span>
                  </div>
                  <div class="flex shrink-0 items-center gap-2">
                    <button
                      type="button"
                      class="inline-flex h-9 items-center gap-2 rounded-lg border border-solid px-3 text-xs font-semibold transition-colors"
                      :class="
                        allFilteredInboxesSelected
                          ? 'border-n-brand-7 bg-n-brand-3 text-n-brand-12'
                          : 'border-n-blue-9/30 bg-n-solid-1/60 text-n-slate-11 hover:border-n-brand-7 hover:text-n-brand-11'
                      "
                      @click="toggleFilteredInboxes"
                    >
                      <span
                        class="h-4 w-4"
                        :class="
                          allFilteredInboxesSelected
                            ? 'i-lucide-check-check'
                            : 'i-lucide-list-checks'
                        "
                      />
                      {{
                        allFilteredInboxesSelected
                          ? $t('EMPLOYEE_MGMT.FORM.CLEAR_ALL_INBOXES')
                          : $t('EMPLOYEE_MGMT.FORM.SELECT_ALL_INBOXES')
                      }}
                    </button>
                    <button
                      v-if="selectedInboxCount"
                      type="button"
                      class="rounded-md px-2 py-1 text-xs font-semibold text-n-slate-11 transition-colors hover:bg-n-slate-3 hover:text-n-slate-12"
                      @click="clearInboxSelection"
                    >
                      {{ $t('EMPLOYEE_MGMT.FORM.CLEAR_INBOXES') }}
                    </button>
                  </div>
                </div>

                <div
                  class="flex h-11 w-full items-center gap-3 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/60 px-3 transition-colors focus-within:border-n-brand-7 focus-within:ring-1 focus-within:ring-n-brand-7/30"
                >
                  <span
                    class="i-lucide-search h-4 w-4 shrink-0 text-n-slate-10"
                  />
                  <input
                    v-model="inboxSearchQuery"
                    type="text"
                    class="reset-base h-full min-w-0 flex-1 !border-0 !bg-transparent !p-0 text-sm text-n-slate-12 outline-none !ring-0 placeholder:text-n-slate-10 focus:!border-0 focus:!outline-none focus:!ring-0"
                    :placeholder="$t('EMPLOYEE_MGMT.FORM.SEARCH_INBOXES')"
                  />
                </div>

                <div
                  v-if="selectedInboxCount"
                  class="flex flex-wrap items-center gap-2 rounded-lg border border-solid border-n-blue-9/20 bg-n-solid-1/50 px-3 py-2"
                >
                  <span
                    v-for="inbox in selectedInboxPreview"
                    :key="`selected-${inbox.id}`"
                    class="inline-flex max-w-44 items-center gap-1 rounded-md border border-solid border-n-brand-5/60 bg-n-brand-3 px-2 py-1 text-xs font-medium text-n-brand-12"
                  >
                    <span class="min-w-0 truncate" :title="inbox.name">
                      {{ inbox.name }}
                    </span>
                  </span>
                  <span
                    v-if="hiddenSelectedInboxCount"
                    class="inline-flex items-center rounded-md bg-n-slate-3 px-2 py-1 text-xs font-medium text-n-slate-11"
                  >
                    {{
                      $t('EMPLOYEE_MGMT.FORM.MORE_INBOXES', {
                        count: hiddenSelectedInboxCount,
                      })
                    }}
                  </span>
                </div>

                <div
                  class="overflow-hidden rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/50"
                >
                  <div
                    class="grid grid-cols-[2rem_2.75rem_minmax(0,1fr)_6rem] items-center gap-3 border-b border-solid border-n-blue-9/20 bg-n-solid-3/40 px-3 py-2 text-xs font-semibold uppercase text-n-slate-10"
                  >
                    <input
                      type="checkbox"
                      class="h-4 w-4 rounded border-n-slate-4 text-n-brand-9 focus:ring-n-brand-5"
                      :checked="allFilteredInboxesSelected"
                      @change="toggleFilteredInboxes"
                    />
                    <span />
                    <span>{{ $t('EMPLOYEE_MGMT.FORM.INBOX_COLUMN') }}</span>
                    <span class="text-end">
                      {{ $t('EMPLOYEE_MGMT.FORM.CHANNEL_COLUMN') }}
                    </span>
                  </div>
                  <div class="max-h-[27rem] overflow-y-auto bg-n-solid-1/20">
                    <div
                      v-if="inboxesUiFlags.isFetching"
                      class="flex flex-col gap-1"
                    >
                      <div
                        v-for="index in 6"
                        :key="index"
                        class="h-12 animate-pulse rounded-md bg-n-slate-3"
                      />
                    </div>
                    <div
                      v-else-if="!inboxes.length"
                      class="rounded-lg border border-dashed border-n-weak px-4 py-8 text-center text-sm text-n-slate-10"
                    >
                      {{ $t('EMPLOYEE_MGMT.FORM.NO_INBOXES') }}
                    </div>
                    <div
                      v-else-if="!filteredInboxes.length"
                      class="rounded-lg border border-dashed border-n-weak px-4 py-8 text-center text-sm text-n-slate-10"
                    >
                      {{ $t('EMPLOYEE_MGMT.FORM.NO_INBOX_RESULTS') }}
                    </div>
                    <div v-else class="divide-y divide-n-blue-9/20">
                      <label
                        v-for="inbox in filteredInboxes"
                        :key="inbox.id"
                        class="m-0 grid min-h-14 cursor-pointer grid-cols-[2rem_2.75rem_minmax(0,1fr)_6rem] items-center gap-3 px-3 py-2 transition-colors"
                        :class="
                          isInboxSelected(inbox.id)
                            ? 'bg-n-brand-3/60 text-n-brand-12'
                            : 'hover:bg-n-slate-2/60'
                        "
                      >
                        <input
                          type="checkbox"
                          class="h-4 w-4 rounded border-n-slate-4 text-n-brand-9 focus:ring-n-brand-5"
                          :checked="isInboxSelected(inbox.id)"
                          @change="toggleInbox(inbox.id)"
                        />
                        <span
                          class="flex h-8 w-8 items-center justify-center rounded-lg"
                          :class="inboxIconToneClass(inbox)"
                        >
                          <span
                            class="text-base"
                            :class="
                              getInboxIconByType(
                                inbox.channel_type,
                                inbox.medium,
                                'line'
                              )
                            "
                          />
                        </span>
                        <span class="flex min-w-0 flex-col">
                          <span
                            class="truncate text-sm font-medium"
                            :title="inbox.name"
                          >
                            {{ inbox.name }}
                          </span>
                          <span
                            v-if="inboxMeta(inbox)"
                            class="truncate text-xs text-n-slate-10"
                            :title="inboxMeta(inbox)"
                          >
                            {{ inboxMeta(inbox) }}
                          </span>
                        </span>
                        <span
                          class="inline-flex justify-self-end rounded-md border border-solid px-2 py-1 text-xs font-medium"
                          :class="inboxChannelBadgeClass(inbox)"
                        >
                          {{ inboxChannelLabel(inbox) }}
                        </span>
                      </label>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            <section
              class="grid grid-cols-1 gap-5 rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/40 p-5 shadow-sm shadow-n-blue-12/10 md:grid-cols-2 xl:col-start-1 xl:row-start-2"
            >
              <div
                class="flex items-start gap-3 border-b border-solid border-n-blue-9/20 pb-4 text-start md:col-span-2"
              >
                <span
                  class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-8/40 bg-gradient-to-br from-n-brand-4 to-n-solid-3 text-n-blue-12"
                >
                  <span class="i-lucide-lock-keyhole text-xl" />
                </span>
                <div class="min-w-0">
                  <h3 class="mb-1 text-base font-semibold text-n-slate-12">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.PASSWORD') }}
                  </h3>
                  <p class="mb-0 text-sm text-n-slate-10">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTION_DESCRIPTIONS.PASSWORD') }}
                  </p>
                </div>
              </div>
              <label class="relative flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD') }}
                  <span v-if="!isEditing" class="text-n-ruby-9">{{
                    $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                  }}</span>
                  <span
                    v-if="isEditing"
                    class="text-xs font-normal text-n-slate-10"
                  >
                    {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD_OPTIONAL') }}
                  </span>
                </span>
                <div class="relative w-full">
                  <input
                    v-model="form.password"
                    :required="!isEditing"
                    :type="showNewPassword ? 'text' : 'password'"
                    class="h-11 w-full rounded-lg border-n-blue-9/40 bg-n-solid-1/60 !py-0 tracking-[0.35em] focus:border-n-brand-7 ltr:!pr-11 rtl:!pl-11"
                  />
                  <button
                    type="button"
                    class="absolute inset-y-0 flex h-11 w-11 items-center justify-center text-n-slate-10 transition-colors hover:text-n-slate-12 ltr:right-0 rtl:left-0"
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
              <label class="relative flex flex-col text-start">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.PASSWORD_CONFIRMATION') }}
                  <span v-if="!isEditing" class="text-n-ruby-9">{{
                    $t('EMPLOYEE_MGMT.REQUIRED_MARK')
                  }}</span>
                </span>
                <div class="relative w-full">
                  <input
                    v-model="form.password_confirmation"
                    :required="!isEditing"
                    :type="showNewPasswordConfirmation ? 'text' : 'password'"
                    class="h-11 w-full rounded-lg border-n-blue-9/40 bg-n-solid-1/60 !py-0 tracking-[0.35em] focus:border-n-brand-7 ltr:!pr-11 rtl:!pl-11"
                  />
                  <button
                    type="button"
                    class="absolute inset-y-0 flex h-11 w-11 items-center justify-center text-n-slate-10 transition-colors hover:text-n-slate-12 ltr:right-0 rtl:left-0"
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
              <div class="flex flex-col gap-3 text-start md:col-span-2">
                <div class="flex items-center gap-3">
                  <div class="flex min-w-0 flex-1 items-center gap-2">
                    <span
                      v-for="index in 4"
                      :key="index"
                      class="h-1.5 flex-1 rounded-full"
                      :class="
                        passwordScore >= index
                          ? passwordStrengthBarClass
                          : 'bg-n-slate-4'
                      "
                    />
                  </div>
                  <span
                    class="inline-flex shrink-0 items-center rounded-md border border-solid px-2 py-1 text-xs font-semibold"
                    :class="passwordStrengthClass"
                  >
                    {{ passwordStrengthLabel }}
                  </span>
                </div>
                <span class="text-xs text-n-slate-11">
                  {{ $t('EMPLOYEE_MGMT.PASSWORD.REQUIREMENTS') }}
                </span>
              </div>
            </section>

            <section
              class="grid grid-cols-1 gap-5 rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/40 p-5 shadow-sm shadow-n-blue-12/10 md:grid-cols-2 xl:col-start-1 xl:row-start-3"
            >
              <div
                class="flex items-start gap-3 border-b border-solid border-n-blue-9/20 pb-4 text-start md:col-span-2"
              >
                <span
                  class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-8/40 bg-gradient-to-br from-n-brand-4 to-n-solid-3 text-n-blue-12"
                >
                  <span class="i-lucide-clipboard-check text-xl" />
                </span>
                <div class="min-w-0">
                  <h3 class="mb-1 text-base font-semibold text-n-slate-12">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTIONS.STATUS') }}
                  </h3>
                  <p class="mb-0 text-sm text-n-slate-10">
                    {{ $t('EMPLOYEE_MGMT.FORM.SECTION_DESCRIPTIONS.STATUS') }}
                  </p>
                </div>
              </div>
              <label
                class="m-0 flex cursor-pointer items-center justify-between gap-4 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/50 px-4 py-3 text-start md:col-span-2"
              >
                <div class="min-w-0">
                  <p class="mb-1 font-medium text-n-slate-12">
                    {{ $t('EMPLOYEE_MGMT.FORM.ACTIVE') }}
                  </p>
                  <p class="mb-0 text-xs text-n-slate-10">
                    {{ $t('EMPLOYEE_MGMT.FORM.ACTIVE_DESCRIPTION') }}
                  </p>
                </div>
                <input
                  v-model="form.active"
                  type="checkbox"
                  class="h-6 w-6 shrink-0 cursor-pointer rounded border-n-slate-6 bg-n-solid-3 text-n-brand-9 focus:ring-n-brand-5"
                />
              </label>
              <label
                v-if="!form.active"
                class="flex flex-col text-start md:col-span-2"
              >
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.DEACTIVATION_REASON') }}
                </span>
                <textarea
                  v-model="form.deactivation_reason"
                  rows="2"
                  class="resize-none rounded-lg border-n-blue-9/40 bg-n-solid-1/60 placeholder:text-n-slate-10 focus:border-n-brand-7"
                />
              </label>
              <label class="flex flex-col text-start md:col-span-2">
                <span class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ $t('EMPLOYEE_MGMT.FORM.NOTES') }}
                </span>
                <div class="relative">
                  <textarea
                    v-model="form.employee_notes"
                    rows="3"
                    :placeholder="$t('EMPLOYEE_MGMT.FORM.PLACEHOLDERS.NOTES')"
                    class="w-full resize-none rounded-lg border-n-blue-9/40 bg-n-solid-1/60 placeholder:text-n-slate-10 focus:border-n-brand-7"
                  />
                </div>
                <span class="mt-2 text-xs text-n-slate-10">
                  {{ $t('EMPLOYEE_MGMT.FORM.NOTES_HELP') }}
                </span>
              </label>
            </section>
          </div>

          <div
            class="flex shrink-0 flex-col gap-3 border-t border-solid border-n-blue-9/20 bg-n-solid-1/55 px-5 py-4 sm:px-8"
          >
            <div
              class="flex flex-col gap-4 rounded-xl border border-solid border-n-blue-9/20 bg-n-solid-2/40 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
            >
              <div
                class="flex min-h-9 items-center gap-3 text-start text-sm text-n-slate-10"
              >
                <span
                  v-if="saveDisabledReason"
                  class="i-lucide-triangle-alert h-6 w-6 shrink-0 text-n-ruby-10"
                />
                <span v-if="saveDisabledReason">
                  {{ $t('EMPLOYEE_MGMT.FORM.FIX_FIELDS') }}
                </span>
              </div>
              <div class="flex justify-end gap-3">
                <button
                  type="button"
                  class="h-12 min-w-32 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/70 px-5 text-sm font-semibold text-n-slate-12 transition-colors hover:bg-n-slate-3"
                  @click="showFormModal = false"
                >
                  {{ $t('EMPLOYEE_MGMT.CANCEL') }}
                </button>
                <button
                  type="submit"
                  :disabled="!canSaveEmployee"
                  class="inline-flex h-12 min-w-40 items-center justify-center gap-2 rounded-lg border border-solid border-n-brand-7 bg-n-brand-9 px-5 text-sm font-semibold text-white shadow-lg shadow-n-brand-9/25 transition-colors hover:bg-n-brand-10 disabled:cursor-not-allowed disabled:border-n-slate-7 disabled:bg-n-slate-4 disabled:text-n-slate-10 disabled:shadow-none"
                >
                  <span
                    class="h-4 w-4"
                    :class="
                      isSaving
                        ? 'i-lucide-loader-circle animate-spin'
                        : 'i-lucide-circle-check'
                    "
                  />
                  {{ $t('EMPLOYEE_MGMT.FORM.SAVE_AGENT') }}
                </button>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </Teleport>

  <woot-modal
    v-model:show="showDetailsModal"
    size="medium !w-[88rem] !max-w-[calc(100vw-2rem)]"
    :on-close="() => (showDetailsModal = false)"
  >
    <div
      class="flex max-h-[92vh] w-full flex-col overflow-hidden bg-gradient-to-br from-n-solid-1 via-n-blue-1 to-n-solid-1 ltr:text-left rtl:text-right"
      :dir="isRTL ? 'rtl' : 'ltr'"
    >
      <div
        class="shrink-0 border-b border-solid border-n-blue-9/25 bg-gradient-to-br from-n-solid-2/90 via-n-blue-2/40 to-n-solid-1 px-8 py-7 ltr:pr-14 rtl:pl-14"
      >
        <div
          class="grid min-w-0 grid-cols-1 gap-6 lg:grid-cols-[auto_minmax(0,1fr)] lg:items-center"
        >
          <div
            class="flex min-w-0 shrink-0 flex-wrap items-center gap-3 lg:order-1"
          >
            <span
              class="inline-flex min-w-0 items-center gap-2 rounded-lg border border-solid border-n-blue-9/40 bg-n-solid-1/80 px-4 py-2 text-sm font-semibold text-n-slate-12 shadow-sm shadow-n-blue-12/10"
              :title="presenceTooltip(currentEmployee)"
            >
              <span
                class="relative h-2.5 w-2.5 rounded-full"
                :class="[
                  presenceDotClass(currentEmployee),
                  presencePulseClass(currentEmployee),
                ]"
              />
              {{
                currentEmployee
                  ? availabilityLabel(currentEmployee)
                  : $t('EMPLOYEE_MGMT.EMPTY')
              }}
            </span>
            <span
              class="inline-flex min-w-0 items-center rounded-lg border border-solid px-4 py-2 text-sm font-semibold shadow-sm shadow-n-blue-12/10"
              :class="statusBadgeClass(currentEmployee || {})"
            >
              {{
                currentEmployee
                  ? statusLabel(currentEmployee)
                  : $t('EMPLOYEE_MGMT.EMPTY')
              }}
            </span>
          </div>
          <div
            class="flex min-w-0 items-center gap-5 lg:order-2 lg:justify-end"
          >
            <div class="min-w-0">
              <div
                class="mb-3 inline-flex items-center gap-2 rounded-lg border border-solid border-n-blue-9/30 bg-n-solid-1/60 px-3 py-1.5 text-xs font-semibold text-n-slate-10"
              >
                <span
                  class="i-lucide-clipboard-list text-base text-n-blue-11"
                />
                {{ $t('EMPLOYEE_MGMT.DETAILS.DAILY_TITLE') }}
              </div>
              <h2
                class="mb-1 max-w-3xl break-words text-4xl font-semibold leading-tight text-n-slate-12"
              >
                {{ currentEmployee?.name }}
              </h2>
              <span class="block truncate text-base text-n-slate-10">
                {{ currentEmployee?.email || $t('EMPLOYEE_MGMT.EMPTY') }}
              </span>
            </div>
            <div
              class="relative flex h-20 w-20 shrink-0 items-center justify-center rounded-full border border-solid border-n-blue-9/40 bg-gradient-to-br from-n-slate-3 to-n-blue-3 text-xl font-bold text-n-slate-12 shadow-xl shadow-n-blue-12/20"
            >
              {{
                currentEmployee
                  ? employeeInitials(currentEmployee)
                  : $t('EMPLOYEE_MGMT.EMPTY')
              }}
              <span
                class="absolute bottom-2 h-3.5 w-3.5 rounded-full border-2 border-solid border-n-solid-1 ltr:right-2 rtl:left-2"
                :class="[
                  presenceDotClass(currentEmployee),
                  presencePulseClass(currentEmployee),
                ]"
              />
            </div>
          </div>
        </div>
      </div>

      <section
        v-if="activityDetails"
        class="flex flex-1 flex-col gap-5 overflow-y-auto overflow-x-hidden bg-n-surface-1/70 px-6 py-6"
      >
        <section
          class="rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/60 p-6 shadow-lg shadow-n-blue-12/10"
        >
          <div class="mb-5 flex items-start justify-between gap-4">
            <div class="min-w-0">
              <h3 class="mb-1 text-base font-semibold text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.DETAILS.BASIC_SUMMARY') }}
              </h3>
              <p class="mb-0 text-sm text-n-slate-10">
                {{ $t('EMPLOYEE_MGMT.DETAILS.BASIC_SUMMARY_HINT') }}
              </p>
            </div>
            <span
              class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-9/40 bg-n-blue-3/30 text-2xl text-n-blue-11"
            >
              <span class="i-lucide-users-round" />
            </span>
          </div>
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-5">
            <div
              v-for="item in employeeProfileItems"
              :key="item.key"
              class="flex min-w-0 items-center gap-3 rounded-lg border border-solid border-n-blue-9/25 bg-n-solid-1/60 p-3"
            >
              <span
                class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-9/30 bg-n-blue-3/20 text-lg text-n-blue-11"
                :class="item.icon"
              />
              <div class="min-w-0">
                <div class="mb-1 truncate text-xs text-n-slate-10">
                  {{ item.label }}
                </div>
                <span
                  class="block truncate text-sm font-semibold text-n-slate-12"
                >
                  {{ item.value }}
                </span>
              </div>
            </div>
          </div>
        </section>

        <section
          class="rounded-xl border border-solid border-n-blue-9/30 bg-n-solid-2/60 p-6 shadow-lg shadow-n-blue-12/10"
        >
          <div class="mb-5 flex items-start justify-between gap-4">
            <div class="min-w-0">
              <h3 class="mb-1 text-base font-semibold text-n-slate-12">
                {{ $t('EMPLOYEE_MGMT.DETAILS.TODAY_REPORT') }}
              </h3>
              <p class="mb-0 text-sm text-n-slate-10">
                {{ $t('EMPLOYEE_MGMT.DETAILS.TODAY_REPORT_HINT') }}
              </p>
            </div>
            <span
              class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border border-solid border-n-blue-9/40 bg-n-blue-3/30 text-2xl text-n-blue-11"
            >
              <span class="i-lucide-chart-no-axes-combined" />
            </span>
          </div>

          <div
            v-if="hasDailyPerformanceData"
            class="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3"
          >
            <div
              v-for="card in dailyPerformanceCards"
              :key="card.key"
              class="relative min-h-32 min-w-0 overflow-hidden rounded-xl border border-solid p-4 shadow-sm shadow-n-blue-12/10"
              :class="performanceCardClass(card)"
            >
              <span
                class="absolute inset-0 bg-gradient-to-br from-white/5 via-transparent to-transparent opacity-70"
              />
              <span
                class="absolute top-0 h-full w-1 opacity-80 ltr:left-0 rtl:right-0"
                :class="accentBarClass(card)"
              />
              <div
                class="relative flex h-full items-start justify-between gap-3"
              >
                <div class="min-w-0 self-end">
                  <span class="block truncate text-sm font-semibold">
                    {{ card.label }}
                  </span>
                  <span
                    class="mt-3 block truncate text-3xl font-bold leading-tight text-n-slate-12"
                  >
                    {{ card.value }}
                  </span>
                </div>
                <span
                  class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border border-solid border-current/20 bg-n-solid-1/50 text-2xl"
                  :class="card.icon"
                />
              </div>
            </div>
          </div>

          <div
            v-else
            class="rounded-xl border border-dashed border-n-blue-9/30 bg-n-solid-1/45 px-5 py-8 text-center text-sm font-medium text-n-slate-10"
          >
            {{ $t('EMPLOYEE_MGMT.DETAILS.NO_TODAY_DATA') }}
          </div>
        </section>
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
