<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';

import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AddAssignmentModal from './AddAssignmentModal.vue';

const store = useStore();
const { t } = useI18n();

const loading = ref({});
const assignments = ref([]);
const isFetching = ref(false);
const showDeleteConfirmationPopup = ref(false);
const showAddModal = ref(false);
const selectedAssignment = ref({});

const fetchAssignments = async () => {
  isFetching.value = true;
  try {
    const response = await store.dispatch('userAssignments/get');
    assignments.value = response.data || [];
  } catch (error) {
    useAlert(t('USER_ASSIGNMENTS.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const openDeletePopup = assignment => {
  showDeleteConfirmationPopup.value = true;
  selectedAssignment.value = assignment;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteAssignment = async id => {
  try {
    await store.dispatch('userAssignments/delete', id);
    useAlert(t('USER_ASSIGNMENTS.DELETE_SUCCESS'));
    await fetchAssignments();
  } catch (error) {
    useAlert(t('USER_ASSIGNMENTS.DELETE_ERROR'));
  } finally {
    loading.value[selectedAssignment.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedAssignment.value.id] = true;
  closeDeletePopup();
  deleteAssignment(selectedAssignment.value.id);
};

const deleteMessage = computed(() => {
  return ` ${selectedAssignment.value.user?.name} from ${selectedAssignment.value.template?.friendly_name}?`;
});

const tableHeaders = computed(() => {
  return [
    t('USER_ASSIGNMENTS.TABLE_HEADER.USER'),
    t('USER_ASSIGNMENTS.TABLE_HEADER.EMAIL'),
    t('USER_ASSIGNMENTS.TABLE_HEADER.TEMPLATE'),
    t('USER_ASSIGNMENTS.TABLE_HEADER.DESCRIPTION'),
    t('USER_ASSIGNMENTS.TABLE_HEADER.STATUS'),
  ];
});

onBeforeMount(() => {
  fetchAssignments();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isFetching"
    :loading-message="$t('USER_ASSIGNMENTS.LOADING')"
    :no-records-found="!assignments.length"
    :no-records-message="$t('USER_ASSIGNMENTS.NO_ASSIGNMENTS')"
  >
    <template #header>
      <div class="flex items-center justify-between mb-4">
        <p class="text-n-slate-11 mb-0">
          {{ $t('USER_ASSIGNMENTS.DESCRIPTION') }}
        </p>
        <Button
          icon="i-lucide-circle-plus"
          :label="$t('USER_ASSIGNMENTS.ADD_BUTTON')"
          @click="showAddModal = true"
        />
      </div>
    </template>
    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-weak">
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
          <tr v-for="assignment in assignments" :key="assignment.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span class="mb-1 font-medium break-words text-n-slate-12">
                {{ assignment.user.name }}
              </span>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">{{ assignment.user.email }}</td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              {{ assignment.template.friendly_name }}
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              {{ assignment.template.description }}
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span v-if="assignment.active" class="text-green-600 font-medium">
                {{ $t('USER_ASSIGNMENTS.ACTIVE') }}
              </span>
              <span v-else class="text-gray-500">
                {{ $t('USER_ASSIGNMENTS.INACTIVE') }}
              </span>
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-tooltip.top="$t('USER_ASSIGNMENTS.DELETE')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[assignment.id]"
                  @click="openDeletePopup(assignment)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('USER_ASSIGNMENTS.DELETE_CONFIRM_TITLE')"
      :message="$t('USER_ASSIGNMENTS.DELETE_CONFIRM_MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('USER_ASSIGNMENTS.DELETE_CONFIRM_YES')"
      :reject-text="$t('USER_ASSIGNMENTS.DELETE_CONFIRM_NO')"
    />

    <AddAssignmentModal
      :show="showAddModal"
      @close="showAddModal = false"
      @create="fetchAssignments"
    />
  </SettingsLayout>
</template>
