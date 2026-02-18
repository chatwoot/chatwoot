<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  appointment: { type: Object, default: null },
  onClose: { type: Function, required: true },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const isEditMode = computed(() => !!props.appointment);
const isSubmitting = ref(false);

// Helper para convertir UTC a datetime-local format (zona horaria local)
const toLocalDatetimeString = utcDateString => {
  if (!utcDateString) return '';
  const date = new Date(utcDateString);
  // Obtener componentes de fecha en zona horaria local
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${year}-${month}-${day}T${hours}:${minutes}`;
};

// Cargar datos necesarios
const contacts = computed(() => {
  const contactsList = getters['contacts/getContacts'].value || [];
  const asArray = Array.isArray(contactsList) ? contactsList : Object.values(contactsList);
  // Filtrar valores undefined/null
  return asArray.filter(c => c && c.id);
});
const agents = computed(() => getters['agents/getAgents'].value || []);
const currentAccountId = computed(() => getters.getCurrentAccountId.value);
const currentAccount = computed(() => {
  const account = getters['accounts/getAccount'].value;
  if (typeof account === 'function') {
    return account(currentAccountId.value) || {};
  }
  return account || {};
});

// Obtener el primer tipo de cita habilitado como valor por defecto
const getDefaultAppointmentType = () => {
  const enabledTypes = currentAccount.value.settings?.enabled_appointment_types || [
    'physical_visit',
    'digital_meeting',
    'phone_call',
  ];
  return enabledTypes[0] || 'phone_call';
};

const formData = ref({
  contact_id: props.appointment?.contact_id || null,
  appointment_type: props.appointment?.appointment_type || getDefaultAppointmentType(),
  scheduled_at: toLocalDatetimeString(props.appointment?.scheduled_at),
  ended_at: toLocalDatetimeString(props.appointment?.ended_at),
  owner_id: props.appointment?.owner_id || null,
  description: props.appointment?.description || '',
  phone_number: props.appointment?.phone_number || '',
  meeting_url: props.appointment?.meeting_url || '',
  location: props.appointment?.location || '',
  status: props.appointment?.status || 'scheduled',
});

const contactOptions = computed(() =>
  contacts.value.map(contact => ({
    value: contact.id,
    label: contact.name || contact.email || contact.phone_number || 'Unknown',
  }))
);

const agentOptions = computed(() =>
  agents.value.map(agent => ({
    value: agent.id,
    label: agent.name,
  }))
);

// Obtener contacto seleccionado completo
const selectedContact = computed(() => {
  if (!formData.value.contact_id) return null;
  return contacts.value.find(c => c.id === formData.value.contact_id);
});

// Obtener dirección principal del account
const accountAddress = computed(() => {
  const addresses = currentAccount.value.account_addresses || [];
  if (addresses.length === 0) return '';

  // Buscar dirección principal o tomar la primera
  const mainAddress = addresses.find(addr => addr.is_main) || addresses[0];

  // Formatear dirección
  const parts = [
    mainAddress.street,
    mainAddress.city,
    mainAddress.state,
    mainAddress.country,
    mainAddress.zip_code
  ].filter(Boolean);

  return parts.join(', ');
});

// Tipos de citas disponibles según configuración de la cuenta
const allAppointmentTypes = [
  { value: 'phone_call', label: t('APPOINTMENTS.TYPE.PHONE_CALL') },
  { value: 'digital_meeting', label: t('APPOINTMENTS.TYPE.DIGITAL_MEETING') },
  { value: 'physical_visit', label: t('APPOINTMENTS.TYPE.PHYSICAL_VISIT') },
];

const appointmentTypeOptions = computed(() => {
  const enabledTypes = currentAccount.value.settings?.enabled_appointment_types || [
    'physical_visit',
    'digital_meeting',
    'phone_call',
  ];

  return allAppointmentTypes.filter(type => enabledTypes.includes(type.value));
});

const statusOptions = [
  { value: 'scheduled', label: t('APPOINTMENTS.STATUS.SCHEDULED') },
  { value: 'in_progress', label: t('APPOINTMENTS.STATUS.IN_PROGRESS') },
  { value: 'completed', label: t('APPOINTMENTS.STATUS.COMPLETED') },
  { value: 'cancelled', label: t('APPOINTMENTS.STATUS.CANCELLED') },
  { value: 'no_show', label: t('APPOINTMENTS.STATUS.NO_SHOW') },
];

// Validación de campos requeridos según tipo
const isValidForm = computed(() => {
  if (!formData.value.contact_id || !formData.value.scheduled_at || !formData.value.owner_id) {
    return false;
  }

  // Validar campos específicos por tipo
  if (formData.value.appointment_type === 'phone_call' && !formData.value.phone_number) {
    return false;
  }
  if (formData.value.appointment_type === 'digital_meeting' && !formData.value.meeting_url) {
    return false;
  }
  if (formData.value.appointment_type === 'physical_visit' && !formData.value.location) {
    return false;
  }

  return true;
});

// Autocompletar phone_number cuando se selecciona un contacto
watch(
  () => formData.value.contact_id,
  () => {
    if (formData.value.appointment_type === 'phone_call' && selectedContact.value?.phone_number) {
      formData.value.phone_number = selectedContact.value.phone_number;
    }
  }
);

// Autocompletar campos cuando cambia el tipo de cita
watch(
  () => formData.value.appointment_type,
  newType => {
    if (newType === 'phone_call') {
      // Limpiar otros campos
      formData.value.meeting_url = '';
      formData.value.location = '';
      // Autocompletar teléfono del contacto si existe
      if (selectedContact.value?.phone_number && !formData.value.phone_number) {
        formData.value.phone_number = selectedContact.value.phone_number;
      }
    } else if (newType === 'digital_meeting') {
      // Limpiar otros campos
      formData.value.phone_number = '';
      formData.value.location = '';
    } else if (newType === 'physical_visit') {
      // Limpiar otros campos
      formData.value.phone_number = '';
      formData.value.meeting_url = '';
      // Autocompletar ubicación del account si existe
      if (accountAddress.value && !formData.value.location) {
        formData.value.location = accountAddress.value;
      }
    }
  }
);

async function handleSubmit() {
  if (!isValidForm.value) {
    useAlert(t('APPOINTMENTS.MODAL.VALIDATION_ERROR'));
    return;
  }

  isSubmitting.value = true;
  try {
    const payload = {
      contact_id: formData.value.contact_id,
      appointment: {
        appointment_type: formData.value.appointment_type,
        scheduled_at: new Date(formData.value.scheduled_at).toISOString(),
        owner_id: formData.value.owner_id,
        description: formData.value.description,
        status: formData.value.status,
      },
    };

    // Añadir ended_at si existe
    if (formData.value.ended_at) {
      payload.appointment.ended_at = new Date(formData.value.ended_at).toISOString();
    }

    // Añadir campos específicos por tipo
    if (formData.value.appointment_type === 'phone_call') {
      payload.appointment.phone_number = formData.value.phone_number;
    } else if (formData.value.appointment_type === 'digital_meeting') {
      payload.appointment.meeting_url = formData.value.meeting_url;
    } else if (formData.value.appointment_type === 'physical_visit') {
      payload.appointment.location = formData.value.location;
    }

    if (isEditMode.value) {
      await store.dispatch('appointments/update', {
        id: props.appointment.id,
        ...payload.appointment,
      });
      useAlert(t('APPOINTMENTS.EDIT.SUCCESS'));
    } else {
      await store.dispatch('appointments/create', payload);
      useAlert(t('APPOINTMENTS.CREATE.SUCCESS'));
    }

    // Cerrar modal - el padre recargará la lista
    props.onClose();
  } catch (error) {
    const message = error.response?.data?.message || error.response?.data?.error;
    useAlert(
      message || (isEditMode.value ? t('APPOINTMENTS.EDIT.ERROR') : t('APPOINTMENTS.CREATE.ERROR'))
    );
  } finally {
    isSubmitting.value = false;
  }
}
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="
        isEditMode ? $t('APPOINTMENTS.MODAL.EDIT_TITLE') : $t('APPOINTMENTS.MODAL.CREATE_TITLE')
      "
    />

    <form class="w-full" @submit.prevent="handleSubmit">
      <div class="w-full flex flex-col gap-4 max-h-[60vh] overflow-y-auto">
        <!-- Contacto -->
        <div class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.CONTACT') }}
            <span class="text-red-500">*</span>
            <ComboBox
              v-model="formData.contact_id"
              :options="contactOptions"
              :placeholder="$t('APPOINTMENTS.MODAL.SELECT_CONTACT')"
            />
          </label>
        </div>

        <!-- Tipo de Cita -->
        <div class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.APPOINTMENT_TYPE') }}
            <span class="text-red-500">*</span>
            <select v-model="formData.appointment_type" :disabled="isEditMode">
              <option v-for="opt in appointmentTypeOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </label>
          <p v-if="isEditMode" class="text-xs text-n-slate-9 mt-1">
            {{ $t('APPOINTMENTS.MODAL.TYPE_LOCKED') }}
          </p>
        </div>

        <!-- Fecha y Hora Programada -->
        <div class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.SCHEDULED_AT') }}
            <span class="text-red-500">*</span>
            <input v-model="formData.scheduled_at" type="datetime-local" />
          </label>
        </div>

        <!-- Agente Responsable -->
        <div class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.OWNER') }}
            <span class="text-red-500">*</span>
            <ComboBox
              v-model="formData.owner_id"
              :options="agentOptions"
              :placeholder="$t('APPOINTMENTS.MODAL.SELECT_OWNER')"
            />
          </label>
        </div>

        <!-- Campos condicionales según tipo -->
        <div v-if="formData.appointment_type === 'phone_call'" class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.PHONE_NUMBER') }}
            <span class="text-red-500">*</span>
            <input
              v-model="formData.phone_number"
              type="tel"
              :placeholder="$t('APPOINTMENTS.MODAL.PHONE_PLACEHOLDER')"
            />
          </label>
          <p v-if="selectedContact?.phone_number" class="text-xs text-n-slate-9 mt-1">
            <Icon icon="i-lucide-info" class="w-3 h-3 inline mr-1" />
            {{ $t('APPOINTMENTS.MODAL.PHONE_FROM_CONTACT') }}
          </p>
        </div>

        <div v-if="formData.appointment_type === 'digital_meeting'" class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.MEETING_URL') }}
            <span class="text-red-500">*</span>
            <input
              v-model="formData.meeting_url"
              type="url"
              :placeholder="$t('APPOINTMENTS.MODAL.MEETING_URL_PLACEHOLDER')"
            />
          </label>
        </div>

        <div v-if="formData.appointment_type === 'physical_visit'" class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.LOCATION') }}
            <span class="text-red-500">*</span>
            <input
              v-model="formData.location"
              type="text"
              :placeholder="$t('APPOINTMENTS.MODAL.LOCATION_PLACEHOLDER')"
            />
          </label>
          <p v-if="accountAddress" class="text-xs text-n-slate-9 mt-1">
            <Icon icon="i-lucide-info" class="w-3 h-3 inline mr-1" />
            {{ $t('APPOINTMENTS.MODAL.LOCATION_FROM_ACCOUNT') }}
          </p>
        </div>

        <!-- Descripción -->
        <div class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.DESCRIPTION') }}
            <textarea
              v-model="formData.description"
              rows="3"
              :placeholder="$t('APPOINTMENTS.MODAL.DESCRIPTION_PLACEHOLDER')"
            />
          </label>
        </div>

        <!-- Estado (solo en edición) -->
        <div v-if="isEditMode" class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.STATUS') }}
            <select v-model="formData.status">
              <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </label>
        </div>

        <!-- Fecha de Fin (opcional) -->
        <div v-if="isEditMode" class="w-full">
          <label>
            {{ $t('APPOINTMENTS.MODAL.ENDED_AT') }}
            <input v-model="formData.ended_at" type="datetime-local" />
          </label>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <Button
          faded
          slate
          type="button"
          :label="$t('APPOINTMENTS.MODAL.CANCEL')"
          @click="onClose"
        />
        <Button
          type="submit"
          :label="$t('APPOINTMENTS.MODAL.SAVE')"
          :disabled="!isValidForm || isSubmitting"
          :is-loading="isSubmitting"
        />
      </div>
    </form>
  </div>
</template>
