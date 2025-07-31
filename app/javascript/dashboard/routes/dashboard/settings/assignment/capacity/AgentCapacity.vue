<script setup>
import { computed, onMounted, ref, h } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useConfig } from 'dashboard/composables/useConfig';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import BasePaywallModal from '../../components/BasePaywallModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Table from 'dashboard/components/table/Table.vue';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

const store = useStore();
const getters = useStoreGetters();
const router = useRouter();
const { t } = useI18n();
const { isEnterprise } = useConfig();

const policies = computed(
  () => getters['agentCapacity/getCapacityPolicies'].value
);
// Removed agentCapacities as agents tab is removed
const uiFlags = computed(() => getters['agentCapacity/getUIFlags'].value);
// Removed agents computed property as agents tab is removed

// Removed activeTab and tabs since we only have policies now
const loading = ref({});
const showDeletePopup = ref(false);
const showPaywallModal = ref(false);
const selectedPolicy = ref(null);

// Column helpers for TanStack Table
const policyColumnHelper = createColumnHelper();
const policyColumns = [
  policyColumnHelper.accessor('name', {
    header: 'Policy Name',
    cell: info =>
      h(
        'div',
        { class: 'font-medium text-slate-900' },
        info.getValue() || 'Untitled Policy'
      ),
    size: 250,
  }),
  policyColumnHelper.accessor('description', {
    header: 'Description',
    cell: info =>
      h('div', { class: 'text-sm text-slate-600' }, info.getValue() || '-'),
    size: 350,
  }),
  policyColumnHelper.accessor('inbox_limits', {
    header: 'Inbox Limits',
    cell: info => {
      const inboxLimits = info.getValue() || [];
      const count = Array.isArray(inboxLimits) ? inboxLimits.length : 0;
      return h('span', { class: 'font-medium' }, count);
    },
    size: 150,
  }),
  policyColumnHelper.accessor('user_count', {
    header: 'Assigned Agents',
    cell: info =>
      h(
        'span',
        {
          class:
            'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800',
        },
        `${info.getValue() || 0} ${info.getValue() === 1 ? 'Agent' : 'Agents'}`
      ),
    size: 150,
  }),
  policyColumnHelper.accessor('actions', {
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
            color: 'ruby',
            size: 'sm',
            icon: 'delete',
            isLoading: loading.value[info.row.original.id],
            onClick: () => openDeletePopup(info.row.original),
          },
          () => 'Delete'
        ),
      ]),
    size: 100,
  }),
];

// Removed agent columns as agents tab is removed

const fetchData = async () => {
  // Only fetch policies since agents tab is removed
  await store.dispatch('agentCapacity/get');
};

onMounted(() => {
  fetchData();
});

const navigateToNew = () => {
  router.push({ name: 'assignment_capacity_new' });
};

const editPolicy = policy => {
  router.push({
    name: 'assignment_capacity_edit',
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

const confirmDelete = async () => {
  if (!selectedPolicy.value) return;

  try {
    loading.value[selectedPolicy.value.id] = true;
    await store.dispatch('agentCapacity/delete', selectedPolicy.value.id);
    useAlert('Capacity policy deleted successfully');
    closeDeletePopup();
  } catch (error) {
    useAlert('Failed to delete capacity policy');
  } finally {
    loading.value[selectedPolicy.value.id] = false;
  }
};

// Removed utilization helper functions as agents tab is removed

// Table instances
const policyTable = computed(() =>
  useVueTable({
    data: policies.value,
    columns: policyColumns,
    getCoreRowModel: getCoreRowModel(),
  })
);

// Removed agentTable as agents tab is removed
</script>

<template>
  <div>
    <BaseSettingsHeader
      title="Agent Capacity Management"
      description="Set conversation limits and manage agent workload policies"
      back-button-label="Back to Assignment"
      @back="$router.push({ name: 'assignment_index' })"
    >
      <template #actions>
        <Button variant="primary" icon="add" @click="navigateToNew">
          {{ $t('ASSIGNMENT_SETTINGS.CAPACITY.NEW_BUTTON') }}
        </Button>
      </template>
    </BaseSettingsHeader>

    <div class="p-8">
      <!-- Removed tab switching UI since we only have policies now -->

      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center h-64"
      >
        <Spinner :size="48" />
      </div>

      <!-- Policies -->
      <div v-else>
        <EmptyState
          v-if="!policies.length"
          title="No Capacity Policies"
          message="Create capacity policies to manage agent workload and conversation limits"
        >
          <Button
            variant="primary"
            size="medium"
            icon="add"
            @click="navigateToNew"
          >
            Create Capacity Policy
          </Button>
        </EmptyState>

        <Table v-else :table="policyTable" />
      </div>

      <!-- Agents Tab removed as requested -->
    </div>

    <ConfirmationModal
      v-model:show="showDeletePopup"
      title="Delete Capacity Policy"
      :description="`Are you sure you want to delete the capacity policy '${selectedPolicy?.name}'? This action cannot be undone.`"
      confirm-label="Delete"
      cancel-label="Cancel"
      @confirm="confirmDelete"
      @cancel="closeDeletePopup"
    />

    <!-- Removed BasePaywallModal for Enterprise accounts -->
  </div>
</template>
