<script setup>
import { computed, onMounted, ref, h } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Table from 'dashboard/components/table/Table.vue';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';
import Modal from 'dashboard/components/Modal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import inboxesAPI from 'dashboard/api/inboxes';

const store = useStore();
const getters = useStoreGetters();
const router = useRouter();
const { t } = useI18n();

const policies = computed(
  () => getters['assignmentPolicies/getPoliciesByPriority'].value
);
const uiFlags = computed(() => getters['assignmentPolicies/getUIFlags'].value);

const loading = ref({});
const showDeletePopup = ref(false);
const showAssignInboxModal = ref(false);
const selectedPolicy = ref(null);
const selectedInboxId = ref(null);
const inboxes = computed(() => getters['inboxes/getInboxes'].value);

// Filter out already assigned inboxes
const availableInboxes = computed(() => {
  if (!selectedPolicy.value) return inboxes.value;

  const assignedInboxIds = selectedPolicy.value.inboxes?.map(i => i.id) || [];
  return inboxes.value.filter(inbox => !assignedInboxIds.includes(inbox.id));
});

// Column helper for TanStack Table
const columnHelper = createColumnHelper();
const columns = [
  columnHelper.accessor('name', {
    header: 'Policy Name',
    cell: info =>
      h('div', { class: 'font-medium text-slate-900' }, info.getValue()),
    size: 250,
  }),
  columnHelper.accessor('description', {
    header: 'Description',
    cell: info =>
      h('div', { class: 'text-sm text-slate-600' }, info.getValue() || '-'),
    size: 350,
  }),
  columnHelper.accessor('assignment_order', {
    header: 'Assignment Order',
    cell: info =>
      h(
        'div',
        { class: 'font-medium text-slate-900' },
        info.getValue() === 'round_robin' ? 'Round Robin' : 'Balanced'
      ),
    size: 150,
  }),
  columnHelper.accessor('conversation_priority', {
    header: 'Conversation Priority',
    cell: info =>
      h(
        'div',
        { class: 'text-sm text-slate-600' },
        info.getValue() === 'earliest_created'
          ? 'Earliest Created'
          : 'Longest Waiting'
      ),
    size: 150,
  }),
  columnHelper.accessor('enabled', {
    header: 'Status',
    cell: info =>
      h('div', { class: 'flex items-center gap-2' }, [
        h('div', {
          class: `w-2 h-2 rounded-full ${
            info.getValue() ? 'bg-green-500' : 'bg-slate-400'
          }`,
        }),
        h(
          'span',
          { class: 'text-sm' },
          info.getValue() ? 'Active' : 'Inactive'
        ),
      ]),
    size: 120,
  }),
  columnHelper.accessor(row => row.inboxes || [], {
    id: 'inboxes',
    header: 'Assigned Inboxes',
    cell: info => {
      const inboxes = info.getValue();
      const policyId = info.row.original.id;

      if (!inboxes || inboxes.length === 0) {
        return h(
          'span',
          { class: 'text-sm text-slate-500' },
          'No inboxes assigned'
        );
      }

      return h(
        'div',
        { class: 'flex flex-wrap gap-1' },
        inboxes.map(inbox =>
          h(
            'div',
            {
              class:
                'inline-flex items-center gap-1 px-2 py-1 text-xs bg-woot-50 text-woot-700 rounded-full border border-woot-200 hover:bg-woot-100 transition-colors group',
            },
            [
              h('span', inbox.name),
              h(
                'button',
                {
                  class:
                    'ml-1 -mr-1 p-0.5 rounded-full hover:bg-woot-200 transition-colors',
                  onClick: e => {
                    e.stopPropagation();
                    unassignInbox(policyId, inbox.id, inbox.name);
                  },
                  title: `Remove ${inbox.name}`,
                },
                h(
                  'svg',
                  {
                    class: 'w-3 h-3',
                    fill: 'currentColor',
                    viewBox: '0 0 20 20',
                  },
                  h('path', {
                    'fill-rule': 'evenodd',
                    d: 'M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z',
                    'clip-rule': 'evenodd',
                  })
                )
              ),
            ]
          )
        )
      );
    },
    size: 250,
  }),
  columnHelper.display({
    id: 'actions',
    header: 'Actions',
    cell: info =>
      h('div', { class: 'flex items-center gap-2' }, [
        h(
          Button,
          {
            variant: 'ghost',
            size: 'sm',
            icon: 'edit',
            onClick: () => editPolicy(info.row.original),
          },
          () => 'Edit'
        ),
        h(
          Button,
          {
            variant: 'ghost',
            size: 'sm',
            icon: 'mail-inbox-all',
            onClick: () => openAssignInboxModal(info.row.original),
            title: 'Assign policy to inbox',
          },
          () => 'Assign'
        ),
        h(
          Button,
          {
            variant: 'ghost',
            color: 'ruby',
            size: 'sm',
            icon: 'delete',
            isLoading: loading.value[info.row.original.id],
            onClick: () => openDeletePopup(info.row.original),
          },
          () => 'Delete'
        ),
      ]),
    size: 200,
  }),
];

onMounted(() => {
  store.dispatch('assignmentPolicies/get');
  store.dispatch('inboxes/get');
});

const navigateToNew = () => {
  router.push({ name: 'assignment_policies_new' });
};

const editPolicy = policy => {
  router.push({
    name: 'assignment_policies_edit',
    params: { id: policy.id },
  });
};

const openDeletePopup = policy => {
  selectedPolicy.value = policy;
  showDeletePopup.value = true;
};

const closeDeletePopup = () => {
  selectedPolicy.value = null;
  showDeletePopup.value = false;
};

const openAssignInboxModal = policy => {
  selectedPolicy.value = policy;
  selectedInboxId.value = null;
  showAssignInboxModal.value = true;
};

const closeAssignInboxModal = () => {
  selectedPolicy.value = null;
  selectedInboxId.value = null;
  showAssignInboxModal.value = false;
};

const confirmDelete = async () => {
  if (!selectedPolicy.value) return;

  try {
    loading.value[selectedPolicy.value.id] = true;
    await store.dispatch('assignmentPolicies/delete', selectedPolicy.value.id);
    useAlert('Assignment policy deleted successfully');
    closeDeletePopup();
  } catch (error) {
    useAlert('Failed to delete assignment policy');
  } finally {
    loading.value[selectedPolicy.value.id] = false;
  }
};

const assignPolicyToInbox = async () => {
  if (!selectedPolicy.value || !selectedInboxId.value) return;

  try {
    loading.value[selectedPolicy.value.id] = true;

    // Use the inboxes API service
    await inboxesAPI.assignPolicy(
      selectedInboxId.value,
      selectedPolicy.value.id
    );

    useAlert('Policy assigned to inbox successfully');
    // Refresh the policies to show the updated inbox assignments
    await store.dispatch('assignmentPolicies/get');
    closeAssignInboxModal();
  } catch (error) {
    console.error('Failed to assign policy:', error);
    useAlert(error.response?.data?.error || 'Failed to assign policy to inbox');
  } finally {
    loading.value[selectedPolicy.value.id] = false;
  }
};

const unassignInbox = async (policyId, inboxId, inboxName) => {
  try {
    loading.value[policyId] = true;

    // Call the API to remove the assignment
    await inboxesAPI.removePolicy(inboxId);

    useAlert(`Policy unassigned from ${inboxName}`);
    // Refresh the policies to show the updated inbox assignments
    await store.dispatch('assignmentPolicies/get');
  } catch (error) {
    console.error('Failed to unassign policy:', error);
    useAlert(
      error.response?.data?.error || 'Failed to unassign policy from inbox'
    );
  } finally {
    loading.value[policyId] = false;
  }
};

// Table instance
const table = computed(() =>
  useVueTable({
    data: policies.value,
    columns,
    getCoreRowModel: getCoreRowModel(),
  })
);
</script>

<template>
  <div>
    <BaseSettingsHeader
      title="Assignment Policies"
      description="Create and manage policies to automatically assign conversations to agents based on various criteria"
      back-button-label="Back to Assignment"
      @back="$router.push({ name: 'assignment_index' })"
    >
      <template #actions>
        <Button variant="solid" icon="add" @click="navigateToNew">
          New Policy
        </Button>
      </template>
    </BaseSettingsHeader>

    <div class="p-8">
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center h-64"
      >
        <Spinner :size="48" />
      </div>

      <EmptyState
        v-else-if="!policies.length"
        title="No Assignment Policies"
        message="Create your first assignment policy to automatically distribute conversations to your agents"
      >
        <Button variant="solid" icon="add" @click="navigateToNew">
          New Policy
        </Button>
      </EmptyState>

      <div v-else>
        <Table :table="table" />
      </div>
    </div>

    <ConfirmationModal
      v-model:show="showDeletePopup"
      title="Delete Assignment Policy"
      :message="`Are you sure you want to delete the policy '${selectedPolicy?.name}'? This action cannot be undone.`"
      confirm-text="Delete"
      cancel-text="Cancel"
      @confirm="confirmDelete"
      @cancel="closeDeletePopup"
    />

    <!-- Assign Inbox Modal -->
    <Modal
      v-model:show="showAssignInboxModal"
      :on-close="closeAssignInboxModal"
    >
      <div class="flex flex-col p-6 max-w-md">
        <h2 class="text-lg font-semibold mb-3">Assign Policy to Inbox</h2>

        <div class="mb-4">
          <div class="flex items-center gap-2 mb-3">
            <div
              class="px-3 py-1 bg-slate-100 rounded-full text-sm font-medium text-slate-700"
            >
              {{ selectedPolicy?.name }}
            </div>
            <span class="text-sm text-slate-500">→</span>
            <span class="text-sm text-slate-600">Select inbox</span>
          </div>

          <select
            v-model="selectedInboxId"
            class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-woot-500 focus:border-woot-500 text-sm"
          >
            <option value="">Choose an inbox...</option>
            <option
              v-for="inbox in availableInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>

          <p
            v-if="availableInboxes.length === 0"
            class="mt-2 text-xs text-slate-500"
          >
            All inboxes are already assigned to this policy
          </p>
        </div>

        <div class="flex justify-end gap-2">
          <Button variant="ghost" size="sm" @click="closeAssignInboxModal">
            Cancel
          </Button>
          <Button
            variant="solid"
            size="sm"
            :is-loading="loading[selectedPolicy?.id]"
            :disabled="!selectedInboxId || availableInboxes.length === 0"
            @click="assignPolicyToInbox"
          >
            Assign Inbox
          </Button>
        </div>
      </div>
    </Modal>
  </div>
</template>
