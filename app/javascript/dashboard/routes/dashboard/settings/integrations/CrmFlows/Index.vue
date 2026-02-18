<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import SettingsLayout from '../../SettingsLayout.vue';
import CrmFlowModal from './CrmFlowModal.vue';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const showModal = ref(false);
const selectedFlow = ref(null);
const showDeleteConfirmation = ref(false);
const flowToDelete = ref(null);

const flows = computed(() => getters['crmFlows/getCrmFlows'].value);
const uiFlags = computed(() => getters['crmFlows/getUIFlags'].value);

const TRIGGER_LABELS = {
  quote_request: 'CRM_FLOWS.TRIGGERS.QUOTE_REQUEST',
  advisor_transfer: 'CRM_FLOWS.TRIGGERS.ADVISOR_TRANSFER',
  appointment_scheduling: 'CRM_FLOWS.TRIGGERS.APPOINTMENT_SCHEDULING',
  lead_creation: 'CRM_FLOWS.TRIGGERS.LEAD_CREATION',
  customer_creation: 'CRM_FLOWS.TRIGGERS.CUSTOMER_CREATION',
  contact_type_changed: 'CRM_FLOWS.TRIGGERS.CONTACT_TYPE_CHANGED',
  ticket_created: 'CRM_FLOWS.TRIGGERS.TICKET_CREATED',
};

onMounted(() => {
  store.dispatch('crmFlows/get');
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('integrations/get');
});

function openCreate() {
  selectedFlow.value = null;
  showModal.value = true;
}
function openEdit(flow) {
  selectedFlow.value = flow;
  showModal.value = true;
}
function closeModal() {
  showModal.value = false;
  selectedFlow.value = null;
}

function openDelete(flow) {
  flowToDelete.value = flow;
  showDeleteConfirmation.value = true;
}

async function confirmDelete() {
  try {
    await store.dispatch('crmFlows/delete', flowToDelete.value.id);
    useAlert(t('CRM_FLOWS.DELETE.SUCCESS'));
  } catch {
    useAlert(t('CRM_FLOWS.DELETE.ERROR'));
  } finally {
    showDeleteConfirmation.value = false;
    flowToDelete.value = null;
  }
}

async function toggleActive(flow) {
  try {
    await store.dispatch('crmFlows/update', {
      id: flow.id,
      active: !flow.active,
    });
  } catch {
    useAlert(t('CRM_FLOWS.EDIT.ERROR'));
  }
}
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('CRM_FLOWS.LOADING')"
    :no-records-found="!flows.length"
    :no-records-message="$t('CRM_FLOWS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('CRM_FLOWS.HEADER')"
        :description="$t('CRM_FLOWS.DESCRIPTION')"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('CRM_FLOWS.CREATE.BUTTON')"
            @click="openCreate"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <table class="min-w-full divide-y divide-n-weak">
        <thead>
          <th
            v-for="col in ['NAME', 'TRIGGER', 'SCOPE', 'ACTIONS', 'STATUS']"
            :key="col"
            class="py-4 ltr:pr-4 rtl:pl-4 ltr:text-left rtl:text-right font-semibold text-n-slate-11"
          >
            {{ $t(`CRM_FLOWS.LIST.TABLE_HEADER.${col}`) }}
          </th>
          <th class="py-4 pr-4" />
        </thead>
        <tbody class="divide-y divide-n-weak text-n-slate-12">
          <tr
            v-for="flow in flows"
            :key="flow.id"
            class="hover:bg-n-slate-2 transition-colors"
          >
            <td class="py-3 pr-4 text-sm font-medium">{{ flow.name }}</td>
            <td class="py-3 pr-4 text-sm">
              {{
                flow.trigger_type
                  ? $t(TRIGGER_LABELS[flow.trigger_type] || flow.trigger_type)
                  : ''
              }}
            </td>
            <td class="py-3 pr-4 text-sm">
              {{
                flow.scope_type === 'global'
                  ? $t('CRM_FLOWS.LIST.GLOBAL')
                  : flow.inbox_name
              }}
            </td>
            <td class="py-3 pr-4 text-sm">
              {{
                $t('CRM_FLOWS.LIST.ACTIONS_COUNT', {
                  count: flow.actions_count,
                })
              }}
            </td>
            <td class="py-3 pr-4 text-sm">
              <span class="inline-flex items-center gap-1.5">
                <span
                  :class="flow.active ? 'bg-green-500' : 'bg-n-slate-4'"
                  class="inline-block w-2 h-2 rounded-full"
                />
                <span
                  :class="flow.active ? 'text-green-600' : 'text-n-slate-9'"
                >
                  {{
                    flow.active
                      ? $t('CRM_FLOWS.LIST.ACTIVE')
                      : $t('CRM_FLOWS.LIST.INACTIVE')
                  }}
                </span>
              </span>
            </td>
            <td class="py-3 pr-4 text-sm">
              <div class="flex items-center justify-end gap-1">
                <Button
                  faded
                  slate
                  xs
                  :label="
                    flow.active
                      ? $t('CRM_FLOWS.LIST.INACTIVE')
                      : $t('CRM_FLOWS.LIST.ACTIVE')
                  "
                  @click="toggleActive(flow)"
                />
                <Button
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="openEdit(flow)"
                />
                <Button
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  @click="openDelete(flow)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>
  </SettingsLayout>

  <!-- Modal crear/editar -->
  <woot-modal v-model:show="showModal" size="medium" :on-close="closeModal">
    <CrmFlowModal
      v-if="showModal"
      :flow="selectedFlow"
      :on-close="closeModal"
    />
  </woot-modal>

  <!-- Modal eliminar -->
  <woot-delete-modal
    v-model:show="showDeleteConfirmation"
    :on-close="() => (showDeleteConfirmation = false)"
    :on-confirm="confirmDelete"
    :title="$t('CRM_FLOWS.DELETE.CONFIRM_TITLE')"
    :message="$t('CRM_FLOWS.DELETE.CONFIRM_MESSAGE')"
    :confirm-text="$t('CRM_FLOWS.DELETE.YES')"
    :reject-text="$t('CRM_FLOWS.DELETE.NO')"
  />
</template>
