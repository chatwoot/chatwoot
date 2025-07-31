<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
// Badge component doesn't exist - will use inline styling instead
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ApprovalModal from './components/ApprovalModal.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const { isAdmin } = useAdmin();
const { currentUserId } = useAccount();

const leaveId = computed(() => route.params.id);
const leave = computed(() => getters['leaves/getLeave'].value(leaveId.value));

const loading = ref(true);
const showApprovalModal = ref(false);
const approvalAction = ref('');

onMounted(async () => {
  try {
    await store.dispatch('leaves/show', leaveId.value);
  } catch (error) {
    useAlert('Failed to load leave details');
    router.push({ name: 'assignment_leaves_list' });
  } finally {
    loading.value = false;
  }
});

// Removed getStatusBadgeVariant as we're using inline classes now

const goBack = () => {
  router.push({ name: 'assignment_leaves_list' });
};

const openApprovalModal = action => {
  approvalAction.value = action;
  showApprovalModal.value = true;
};

const closeApprovalModal = () => {
  approvalAction.value = '';
  showApprovalModal.value = false;
};

const handleApproval = async notes => {
  try {
    if (approvalAction.value === 'approve') {
      await store.dispatch('leaves/approve', {
        id: leaveId.value,
        comments: notes,
      });
      useAlert('Leave request approved successfully');
    } else {
      await store.dispatch('leaves/reject', {
        id: leaveId.value,
        reason: notes,
      });
      useAlert('Leave request rejected successfully');
    }
    closeApprovalModal();
  } catch (error) {
    const message =
      approvalAction.value === 'approve'
        ? 'Failed to approve leave request'
        : 'Failed to reject leave request';
    useAlert(`${message}: ${error.message || 'Unknown error'}`);
  }
};

const canApproveReject = computed(() => {
  return isAdmin.value && leave.value?.status === 'pending';
});

const canDelete = computed(() => {
  return (
    leave.value?.status === 'pending' &&
    (isAdmin.value || leave.value?.agent_id === currentUserId.value)
  );
});

const deleteLeave = async () => {
  if (
    !window.confirm(
      'Are you sure you want to delete this leave request? This action cannot be undone.'
    )
  )
    return;

  try {
    await store.dispatch('leaves/delete', leaveId.value);
    useAlert('Leave request deleted successfully');
    router.push({ name: 'assignment_leaves_list' });
  } catch (error) {
    useAlert(
      `Failed to delete leave request: ${error.message || 'Unknown error'}`
    );
  }
};
</script>

<template>
  <div>
    <BaseSettingsHeader
      title="Leave Details"
      description="View complete information about this leave request."
      back-button-label="Back to Leaves"
      @back="goBack"
    />

    <div v-if="loading" class="flex items-center justify-center h-64">
      <Spinner size="large" />
    </div>

    <div v-else-if="leave" class="max-w-4xl p-8">
      <div class="bg-white rounded-lg shadow-sm border border-slate-200">
        <!-- Header -->
        <div class="p-6 border-b border-slate-200">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <img
                :src="leave.agent?.avatar_url"
                :alt="leave.agent?.name"
                class="w-12 h-12 rounded-full"
              />
              <div>
                <h2 class="text-xl font-semibold">{{ leave.agent?.name }}</h2>
                <p class="text-sm text-slate-600">{{ leave.agent?.email }}</p>
              </div>
            </div>
            <span
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize"
              :class="[
                leave.status === 'approved'
                  ? 'bg-green-100 text-green-800'
                  : leave.status === 'rejected'
                    ? 'bg-red-100 text-red-800'
                    : leave.status === 'cancelled'
                      ? 'bg-slate-100 text-slate-800'
                      : 'bg-yellow-100 text-yellow-800',
              ]"
            >
              {{ leave.status }}
            </span>
          </div>
        </div>

        <!-- Content -->
        <div class="p-6 space-y-6">
          <!-- Leave Type -->
          <div>
            <h3 class="text-sm font-medium text-slate-500 mb-1">Leave Type</h3>
            <p class="text-lg font-medium capitalize">
              {{ leave.leave_type }}
            </p>
          </div>

          <!-- Dates -->
          <div>
            <h3 class="text-sm font-medium text-slate-500 mb-1">Dates</h3>
            <p class="text-lg">
              {{ new Date(leave.start_date).toLocaleDateString() }} -
              {{ new Date(leave.end_date).toLocaleDateString() }}
            </p>
            <p class="text-sm text-slate-600 mt-1">
              {{
                leave.total_days ||
                Math.ceil(
                  (new Date(leave.end_date) - new Date(leave.start_date)) /
                    (1000 * 60 * 60 * 24)
                ) + 1
              }}
              days
              <span v-if="leave.is_half_day">
                ({{ leave.half_day_period }})
              </span>
            </p>
          </div>

          <!-- Reason -->
          <div>
            <h3 class="text-sm font-medium text-slate-500 mb-1">Reason</h3>
            <p class="text-base whitespace-pre-wrap">{{ leave.reason }}</p>
          </div>

          <!-- Request Info -->
          <div class="grid grid-cols-2 gap-6">
            <div>
              <h3 class="text-sm font-medium text-slate-500 mb-1">
                Requested On
              </h3>
              <p class="text-base">
                {{ new Date(leave.created_at).toLocaleDateString() }}
              </p>
            </div>

            <div v-if="leave.status !== 'pending'">
              <h3 class="text-sm font-medium text-slate-500 mb-1">
                {{
                  leave.status === 'approved' ? 'Approved By' : 'Rejected By'
                }}
              </h3>
              <p class="text-base">
                {{ leave.approved_by?.name || 'System' }}
                <span class="text-sm text-slate-600">
                  ({{ new Date(leave.updated_at).toLocaleDateString() }})
                </span>
              </p>
            </div>
          </div>

          <!-- Removed approver notes section - field doesn't exist in API -->
        </div>

        <!-- Actions -->
        <div class="p-6 border-t border-slate-200">
          <div class="flex justify-between">
            <Button
              v-if="canDelete"
              variant="danger"
              color-scheme="secondary"
              icon="delete"
              @click="deleteLeave"
            >
              Delete
            </Button>

            <div v-if="canApproveReject" class="flex gap-3 ml-auto">
              <Button
                variant="clear"
                color-scheme="secondary"
                @click="openApprovalModal('reject')"
              >
                Reject
              </Button>
              <Button variant="primary" @click="openApprovalModal('approve')">
                Approve
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <ApprovalModal
      v-model:show="showApprovalModal"
      :action="approvalAction"
      :leave="leave"
      @confirm="handleApproval"
      @cancel="closeApprovalModal"
    />
  </div>
</template>
