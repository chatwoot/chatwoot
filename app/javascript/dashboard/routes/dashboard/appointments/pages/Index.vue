<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { format } from 'date-fns';
import AppointmentsListLayout from '../components/AppointmentsListLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AppointmentModal from '../components/AppointmentModal.vue';

const store = useStore();
const { t } = useI18n();

const appointments = computed(() => store.getters['appointments/getAppointments']);
const uiFlags = computed(() => store.getters['appointments/getUIFlags']);
const meta = computed(() => store.getters['appointments/getMeta']);

const isLoading = computed(() => uiFlags.value.isFetching);
const hasAppointments = computed(() => appointments.value.length > 0);
const currentPage = computed(() => meta.value?.currentPage || 1);
const totalItems = computed(() => meta.value?.count || 0);
const itemsPerPage = 15;

const showModal = ref(false);
const selectedAppointment = ref(null);
const showDeleteConfirmation = ref(false);
const appointmentToDelete = ref(null);

const statusClasses = {
  scheduled: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400',
  in_progress: 'bg-amber-100 text-amber-800 dark:bg-amber-900/20 dark:text-amber-400',
  completed: 'bg-teal-100 text-teal-800 dark:bg-teal-900/20 dark:text-teal-400',
  cancelled: 'bg-slate-100 text-slate-800 dark:bg-slate-900/20 dark:text-slate-400',
  no_show: 'bg-ruby-100 text-ruby-800 dark:bg-ruby-900/20 dark:text-ruby-400',
};

const typeIcons = {
  physical_visit: 'i-lucide-map-pin',
  digital_meeting: 'i-lucide-video',
  phone_call: 'i-lucide-phone',
};

const formatDateTime = dateString => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return format(date, 'MMM d, yyyy h:mm a');
};

const getLocationText = appointment => {
  if (appointment.appointment_type === 'physical_visit') {
    return appointment.location || t('APPOINTMENTS.NO_LOCATION');
  }
  if (appointment.appointment_type === 'digital_meeting') {
    return appointment.meeting_url || t('APPOINTMENTS.NO_MEETING_URL');
  }
  if (appointment.appointment_type === 'phone_call') {
    return appointment.phone_number || t('APPOINTMENTS.NO_PHONE_NUMBER');
  }
  return '';
};

const openAddModal = async () => {
  // Cargar datos necesarios para el modal
  await Promise.all([
    store.dispatch('contacts/get'),
    store.dispatch('agents/get'),
  ]);
  selectedAppointment.value = null;
  showModal.value = true;
};

const editAppointment = async appointment => {
  // Cargar datos necesarios para el modal
  await Promise.all([
    store.dispatch('contacts/get'),
    store.dispatch('agents/get'),
  ]);
  selectedAppointment.value = appointment;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  selectedAppointment.value = null;
  // Recargar la lista después de cerrar el modal
  store.dispatch('appointments/get', { page: currentPage.value });
};

const openDeleteConfirmation = appointment => {
  appointmentToDelete.value = appointment;
  showDeleteConfirmation.value = true;
};

const confirmDelete = async () => {
  try {
    await store.dispatch('appointments/delete', appointmentToDelete.value.id);
    await store.dispatch('appointments/get', { page: currentPage.value });
    useAlert(t('APPOINTMENTS.DELETE.SUCCESS'));
    showDeleteConfirmation.value = false;
    appointmentToDelete.value = null;
  } catch (error) {
    useAlert(t('APPOINTMENTS.DELETE.ERROR'));
  }
};

const updateCurrentPage = async page => {
  await store.dispatch('appointments/get', { page });
};

onMounted(() => {
  store.dispatch('appointments/get');
});
</script>

<template>
  <AppointmentsListLayout
    :header-title="$t('APPOINTMENTS.HEADER.TITLE')"
    :header-description="$t('APPOINTMENTS.HEADER.DESCRIPTION')"
    :show-pagination-footer="hasAppointments && !isLoading"
    :current-page="currentPage"
    :total-items="totalItems"
    :items-per-page="itemsPerPage"
    :is-fetching-list="isLoading"
    @update:current-page="updateCurrentPage"
  >
    <template #header-actions>
      <Button
        icon="i-lucide-circle-plus"
        :label="$t('APPOINTMENTS.HEADER.NEW_APPOINTMENT')"
        @click="openAddModal"
      />
    </template>

    <!-- Loading state -->
    <div v-if="isLoading && !hasAppointments" class="flex justify-center py-20">
      <Spinner />
      <p class="ml-2 text-n-slate-11">
        {{ $t('APPOINTMENTS.LOADING') }}
      </p>
    </div>

    <!-- Empty state -->
    <div
      v-else-if="!hasAppointments"
      class="flex flex-col items-center justify-center py-20"
    >
      <div class="text-center">
        <Icon icon="i-lucide-calendar-x" class="w-16 h-16 mx-auto mb-4 text-n-slate-9" />
        <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
          {{ $t('APPOINTMENTS.EMPTY_STATE_TITLE') }}
        </h3>
        <p class="text-n-slate-11 mb-4">
          {{ $t('APPOINTMENTS.EMPTY_STATE_DESCRIPTION') }}
        </p>
        <Button
          icon="i-lucide-circle-plus"
          :label="$t('APPOINTMENTS.HEADER.NEW_APPOINTMENT')"
          @click="openAddModal"
        />
      </div>
    </div>

    <!-- Appointments table -->
    <div v-else class="bg-white dark:bg-n-slate-1 rounded-lg border border-n-weak">
      <table class="min-w-full divide-y divide-n-weak">
        <tbody class="divide-y divide-n-weak">
          <tr
            v-for="appointment in appointments"
            :key="appointment.id"
            class="hover:bg-n-slate-2 transition-colors"
          >
            <!-- Contact info -->
            <td class="py-4 px-4">
              <div class="flex flex-row items-center gap-3">
                <Avatar
                  :name="appointment.contact?.name || 'Unknown'"
                  :src="appointment.contact?.thumbnail"
                  :size="40"
                />
                <div class="min-w-0">
                  <div class="font-medium text-n-slate-12 truncate">
                    {{
                      appointment.contact?.name ||
                      $t('APPOINTMENTS.UNKNOWN_CONTACT')
                    }}
                  </div>
                  <div class="text-sm text-n-slate-11 truncate">
                    {{ appointment.contact?.email || '' }}
                  </div>
                </div>
              </div>
            </td>

            <!-- Date and time -->
            <td class="py-4 px-4">
              <div class="flex flex-col gap-1">
                <div class="font-medium text-n-slate-12">
                  {{ formatDateTime(appointment.scheduled_at) }}
                </div>
                <div v-if="appointment.ended_at" class="text-sm text-n-slate-11">
                  {{ $t('APPOINTMENTS.TABLE.END_TIME') }}:
                  {{ formatDateTime(appointment.ended_at) }}
                </div>
              </div>
            </td>

            <!-- Type and location -->
            <td class="py-4 px-4">
              <div class="flex flex-col gap-1">
                <div class="flex items-center gap-2">
                  <Icon
                    :icon="typeIcons[appointment.appointment_type]"
                    class="w-4 h-4 text-n-slate-11"
                  />
                  <span class="font-medium text-n-slate-12">
                    {{
                      $t(
                        `APPOINTMENTS.TYPE.${appointment.appointment_type.toUpperCase()}`
                      )
                    }}
                  </span>
                </div>
                <div class="text-sm text-n-slate-11 truncate max-w-[200px]">
                  {{ getLocationText(appointment) }}
                </div>
              </div>
            </td>

            <!-- Description (truncated) -->
            <td class="py-4 px-4">
              <div
                v-if="appointment.description"
                class="text-sm text-n-slate-11 truncate max-w-[200px]"
                :title="appointment.description"
              >
                {{ appointment.description }}
              </div>
              <div v-else class="text-sm text-n-slate-9 italic">
                {{ $t('APPOINTMENTS.NO_DESCRIPTION') }}
              </div>
            </td>

            <!-- Status -->
            <td class="py-4 px-4">
              <span
                :class="statusClasses[appointment.status]"
                class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium whitespace-nowrap"
              >
                {{
                  $t(`APPOINTMENTS.STATUS.${appointment.status.toUpperCase()}`)
                }}
              </span>
            </td>

            <!-- Actions -->
            <td class="py-4 px-4">
              <div class="flex justify-end gap-1">
                <Button
                  v-tooltip.top="$t('APPOINTMENTS.ACTIONS.EDIT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="editAppointment(appointment)"
                />
                <Button
                  v-tooltip.top="$t('APPOINTMENTS.ACTIONS.DELETE')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  @click="openDeleteConfirmation(appointment)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </AppointmentsListLayout>

  <!-- Modal crear/editar -->
  <woot-modal v-model:show="showModal" size="medium" :on-close="closeModal">
    <AppointmentModal
      v-if="showModal"
      :appointment="selectedAppointment"
      :on-close="closeModal"
    />
  </woot-modal>

  <!-- Modal eliminar -->
  <woot-delete-modal
    v-model:show="showDeleteConfirmation"
    :on-close="() => (showDeleteConfirmation = false)"
    :on-confirm="confirmDelete"
    :title="$t('APPOINTMENTS.DELETE.CONFIRM_TITLE')"
    :message="$t('APPOINTMENTS.DELETE.CONFIRM_MESSAGE')"
    :confirm-text="$t('APPOINTMENTS.DELETE.YES')"
    :reject-text="$t('APPOINTMENTS.DELETE.NO')"
  />
</template>
