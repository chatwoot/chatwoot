<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

const store = useStore();
const getters = useStoreGetters();
const router = useRouter();
const { t } = useI18n();
const { currentUserId } = useAccount();
const { isAdmin } = useAdmin();

const leaves = computed(() => getters['leaves/getLeaves'].value || []);
const uiFlags = computed(() => getters['leaves/getUIFlags'].value || {});

const activeTab = ref('all');
const loading = ref({});
const showDeletePopup = ref(false);
const selectedLeave = ref(null);

// Simplified filtered leaves without search
const filteredLeaves = computed(() => {
  if (activeTab.value === 'all') {
    return leaves.value;
  }
  return leaves.value.filter(leave => leave.status === activeTab.value);
});

const tabs = computed(() => [
  {
    key: 'all',
    label: 'All Leaves',
    count: leaves.value.length,
  },
  {
    key: 'approved',
    label: 'Approved Leaves',
    count: leaves.value.filter(leave => leave.status === 'approved').length,
  },
  {
    key: 'pending',
    label: 'Pending Leaves',
    count: leaves.value.filter(leave => leave.status === 'pending').length,
  },
  {
    key: 'rejected',
    label: 'Rejected Leaves',
    count: leaves.value.filter(leave => leave.status === 'rejected').length,
  },
]);

// Helper functions for card display
const getStatusColor = status => {
  switch (status) {
    case 'approved':
      return 'bg-green-100 text-green-800 border-green-200';
    case 'rejected':
      return 'bg-red-100 text-red-800 border-red-200';
    case 'pending':
      return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200';
  }
};

const getCompactStatusColor = status => {
  switch (status) {
    case 'approved':
      return 'bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20';
    case 'rejected':
      return 'bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20';
    case 'pending':
      return 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20';
    default:
      return 'bg-gray-50 text-gray-700 ring-1 ring-inset ring-gray-600/20';
  }
};

const getCompactLeaveTypeColor = type => {
  switch (type) {
    case 'vacation':
      return 'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20';
    case 'sick':
      return 'bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20';
    case 'personal':
      return 'bg-purple-50 text-purple-700 ring-1 ring-inset ring-purple-600/20';
    case 'maternity':
    case 'paternity':
      return 'bg-pink-50 text-pink-700 ring-1 ring-inset ring-pink-600/20';
    default:
      return 'bg-gray-50 text-gray-700 ring-1 ring-inset ring-gray-600/20';
  }
};

const getLeaveTypeColor = type => {
  switch (type) {
    case 'vacation':
      return 'bg-blue-100 text-blue-800';
    case 'sick':
      return 'bg-red-100 text-red-800';
    case 'personal':
      return 'bg-purple-100 text-purple-800';
    case 'maternity':
    case 'paternity':
      return 'bg-pink-100 text-pink-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};

const formatDateRange = (startDate, endDate) => {
  const start = new Date(startDate).toLocaleDateString();
  const end = new Date(endDate).toLocaleDateString();
  return start === end ? start : `${start} - ${end}`;
};

const formatCompactDateRange = (startDate, endDate) => {
  const options = { month: 'short', day: 'numeric' };
  const start = new Date(startDate);
  const end = new Date(endDate);
  const startStr = start.toLocaleDateString('en-US', options);
  const endStr = end.toLocaleDateString('en-US', options);

  // If same date
  if (startStr === endStr) {
    return startStr;
  }

  // If different years, show year for both
  if (start.getFullYear() !== end.getFullYear()) {
    return `${startStr}, ${start.getFullYear()} - ${endStr}, ${end.getFullYear()}`;
  }

  return `${startStr} - ${endStr}`;
};

const getDaysCount = (startDate, endDate) => {
  const start = new Date(startDate);
  const end = new Date(endDate);
  const diffTime = Math.abs(end - start);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  return diffDays;
};

const fetchLeaves = async () => {
  // Fetch all leaves without status filter to show all data
  await store.dispatch('leaves/get', {});
};

onMounted(() => {
  fetchLeaves();
});

const navigateToNew = () => {
  router.push({ name: 'assignment_leaves_new' });
};

const viewLeave = leave => {
  router.push({
    name: 'assignment_leaves_details',
    params: { id: leave.id },
  });
};

const openDeletePopup = leave => {
  selectedLeave.value = leave;
  showDeletePopup.value = true;
};

const closeDeletePopup = () => {
  selectedLeave.value = null;
  showDeletePopup.value = false;
};

const confirmDelete = async () => {
  if (!selectedLeave.value) return;

  try {
    loading.value[selectedLeave.value.id] = true;
    await store.dispatch('leaves/delete', selectedLeave.value.id);
    useAlert('Leave request deleted successfully');
    closeDeletePopup();
    await fetchLeaves(); // Refresh the list
  } catch (error) {
    useAlert('Failed to delete leave request');
  } finally {
    loading.value[selectedLeave.value.id] = false;
  }
};

// Helper function to get agent name or fallback
const getAgentName = leave => {
  return (
    leave.user?.name ||
    leave.agent?.name ||
    `Agent ${leave.user_id || leave.agent_id || 'Unknown'}`
  );
};

const getAgentEmail = leave => {
  return leave.user?.email || leave.agent?.email || '';
};

const getAgentAvatar = leave => {
  return (
    leave.user?.avatar_url ||
    leave.agent?.avatar_url ||
    '/assets/images/chatwoot_logo.svg'
  );
};

const canManageLeave = leave => {
  return isAdmin.value || leave.agent_id === currentUserId.value;
};

const approveLeave = async leave => {
  if (!window.confirm('Are you sure you want to approve this leave request?'))
    return;

  try {
    loading.value[leave.id] = true;
    await store.dispatch('leaves/approve', {
      id: leave.id,
      comments: 'Approved via dashboard',
    });
    useAlert('Leave request approved successfully');
    await fetchLeaves();
  } catch (error) {
    useAlert(
      `Failed to approve leave request: ${error.message || 'Unknown error'}`
    );
  } finally {
    loading.value[leave.id] = false;
  }
};

const rejectLeave = async leave => {
  if (!window.confirm('Are you sure you want to reject this leave request?'))
    return;

  try {
    loading.value[leave.id] = true;
    await store.dispatch('leaves/reject', {
      id: leave.id,
      reason: 'Rejected via dashboard',
    });
    useAlert('Leave request rejected successfully');
    await fetchLeaves();
  } catch (error) {
    useAlert(
      `Failed to reject leave request: ${error.message || 'Unknown error'}`
    );
  } finally {
    loading.value[leave.id] = false;
  }
};
</script>

<template>
  <div>
    <!-- Header -->
    <BaseSettingsHeader
      title="Leave Management"
      description="View and manage leave requests for agents. Approved leaves will exclude agents from automatic assignments."
      back-button-label="Back to Assignment"
      @back="$router.push({ name: 'assignment_index' })"
    >
      <template #actions>
        <Button variant="primary" icon="add" @click="navigateToNew">
          Request Leave
        </Button>
      </template>
    </BaseSettingsHeader>

    <div class="p-8 space-y-6">
      <!-- Tab Navigation -->
      <div class="bg-white rounded-lg shadow-sm border border-slate-200">
        <div class="flex border-b border-slate-200">
          <button
            v-for="tab in tabs"
            :key="tab.key"
            class="flex-1 px-6 py-4 text-sm font-medium text-center transition-all duration-200 relative"
            :class="[
              activeTab === tab.key
                ? 'text-blue-600 bg-white'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50',
            ]"
            @click="activeTab = tab.key"
          >
            <span class="flex items-center justify-center gap-2">
              {{ tab.label }}
              <span
                v-if="tab.count > 0"
                class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                :class="
                  activeTab === tab.key
                    ? 'bg-blue-100 text-blue-800'
                    : 'bg-slate-100 text-slate-700'
                "
              >
                {{ tab.count }}
              </span>
            </span>
            <div
              v-if="activeTab === tab.key"
              class="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"
            />
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center h-64"
      >
        <Spinner :size="48" />
      </div>

      <!-- Empty State -->
      <EmptyState
        v-else-if="!filteredLeaves.length"
        title="No Leave Requests"
        message="No leave requests found. Create a new leave request to get started."
      >
        <Button variant="solid" size="medium" icon="add" @click="navigateToNew">
          Request Leave
        </Button>
      </EmptyState>

      <!-- Leave Cards - Compact Modern Design -->
      <div v-else class="space-y-4">
        <div
          v-for="leave in filteredLeaves"
          :key="leave.id"
          class="bg-white rounded-lg shadow-sm border border-slate-200 hover:shadow-md hover:border-slate-300 transition-all duration-200 cursor-pointer group"
          @click="viewLeave(leave)"
        >
          <div class="p-4">
            <div class="flex items-start gap-4">
              <!-- Avatar -->
              <img
                :src="getAgentAvatar(leave)"
                :alt="getAgentName(leave)"
                class="w-10 h-10 rounded-full ring-2 ring-white shadow-sm flex-shrink-0"
              />

              <!-- Main Content -->
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-4 mb-2">
                  <div class="flex-1">
                    <!-- First Row: Name, Date Range, Days -->
                    <div class="flex items-center gap-2 flex-wrap mb-1">
                      <h3 class="font-semibold text-slate-900">
                        {{ getAgentName(leave) }}
                      </h3>
                      <span class="text-slate-300">•</span>
                      <span class="text-sm text-slate-700">
                        {{
                          formatCompactDateRange(
                            leave.start_date,
                            leave.end_date
                          )
                        }}
                      </span>
                      <span
                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-700"
                      >
                        {{ getDaysCount(leave.start_date, leave.end_date) }}
                        {{
                          getDaysCount(leave.start_date, leave.end_date) === 1
                            ? 'day'
                            : 'days'
                        }}
                      </span>
                    </div>

                    <!-- Second Row: Reason -->
                    <p class="text-sm text-slate-600 line-clamp-1">
                      {{ leave.reason || 'No reason provided' }}
                    </p>
                  </div>

                  <!-- Badges -->
                  <div class="flex items-center gap-2 flex-shrink-0">
                    <span
                      class="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium capitalize"
                      :class="getCompactLeaveTypeColor(leave.leave_type)"
                    >
                      {{ leave.leave_type }}
                    </span>
                    <span
                      class="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium capitalize"
                      :class="getCompactStatusColor(leave.status)"
                    >
                      {{ leave.status }}
                    </span>
                  </div>
                </div>

                <!-- Bottom Row: Meta Info and Actions -->
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3 text-xs text-slate-500">
                    <span>
                      Requested
                      {{
                        new Date(
                          leave.created_at || leave.start_date
                        ).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                        })
                      }}
                    </span>
                    <span v-if="leave.approved_by?.name">
                      <span class="text-slate-300">•</span>
                      {{
                        leave.status === 'approved' ? 'Approved' : 'Rejected'
                      }}
                      by {{ leave.approved_by.name }}
                    </span>
                  </div>

                  <!-- Quick Actions (visible on hover) -->
                  <div
                    class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <template v-if="leave.status === 'pending' && isAdmin">
                      <Button
                        variant="ghost"
                        size="sm"
                        icon="check"
                        color="teal"
                        @click.stop="approveLeave(leave)"
                      />
                      <Button
                        variant="ghost"
                        size="sm"
                        icon="x"
                        color="ruby"
                        @click.stop="rejectLeave(leave)"
                      />
                    </template>

                    <Button
                      v-if="canManageLeave(leave) && leave.status === 'pending'"
                      variant="ghost"
                      size="sm"
                      icon="trash"
                      color="ruby"
                      @click.stop="openDeletePopup(leave)"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <ConfirmationModal
      v-model:show="showDeletePopup"
      title="Delete Leave Request"
      description="Are you sure you want to delete this leave request? This action cannot be undone."
      confirm-label="Delete"
      cancel-label="Cancel"
      @confirm="confirmDelete"
      @cancel="closeDeletePopup"
    />
  </div>
</template>
