<script setup>
import { ref, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Auth from '../../../../api/auth';
import wootConstants from 'dashboard/constants/globals';
import WeeklyAvailabilitySection from '../components/WeeklyAvailabilitySection.vue';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    default: '',
  },
  phoneNumber: {
    type: String,
    default: '',
  },
  type: {
    type: String,
    default: '',
  },
  availability: {
    type: String,
    default: '',
  },
  provider: {
    type: String,
    default: '',
  },
  customRoleId: {
    type: Number,
    default: null,
  },
  responsibleId: {
    type: Number,
    default: null,
  },
  agent: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const childRef = ref(null);

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

const store = useStore();
const { t } = useI18n();

const agentName = ref(props.name);
const agentPhoneNumber = ref('');
const activeDialCode = ref('');
const agentAvailability = ref(props.availability);
const selectedRoleId = ref(props.customRoleId || props.type);
const agentCredentials = ref({ email: props.email });
const selectedResponsibleId = ref(props.responsibleId);

const isPhoneNumberNotValid = computed(() => {
  if (agentPhoneNumber.value !== '') {
    return (
      !isPhoneNumberValid(agentPhoneNumber.value, activeDialCode.value) ||
      (agentPhoneNumber.value !== '' ? activeDialCode.value === '' : false)
    );
  }
  return false;
});

const setPhoneCode = code => {
  activeDialCode.value = code;
};

// Initialize phone number from props
if (props.phoneNumber) {
  const parsed = parsePhoneNumber(props.phoneNumber);
  if (parsed && parsed.countryCallingCode) {
    // Set dial code
    activeDialCode.value = `+${parsed.countryCallingCode}`;
    // Extract number without country code for the input
    agentPhoneNumber.value = props.phoneNumber.replace(
      `+${parsed.countryCallingCode}`,
      ''
    );
  } else {
    // If not parseable, use the raw value
    agentPhoneNumber.value = props.phoneNumber;
  }
}

const parsedPhoneNumber = computed(() => {
  return parsePhoneNumber(agentPhoneNumber.value || '');
});

const setPhoneNumber = computed(() => {
  if (parsedPhoneNumber.value && parsedPhoneNumber.value.countryCallingCode) {
    return agentPhoneNumber.value;
  }
  if (agentPhoneNumber.value === '' && activeDialCode.value !== '') {
    return '';
  }
  return activeDialCode.value
    ? `${activeDialCode.value}${agentPhoneNumber.value}`
    : '';
});

// Initialize phone number from props
if (props.phoneNumber) {
  const parsed = parsePhoneNumber(props.phoneNumber);
  if (parsed && parsed.countryCallingCode) {
    // Set dial code
    activeDialCode.value = `+${parsed.countryCallingCode}`;
    // Extract number without country code for the input
    agentPhoneNumber.value = props.phoneNumber.replace(
      `+${parsed.countryCallingCode}`,
      ''
    );
  } else {
    // If not parseable, use the raw value
    agentPhoneNumber.value = props.phoneNumber;
  }
}

const rules = {
  agentName: { required, minLength: minLength(1) },
  selectedRoleId: { required },
  agentAvailability: { required },
};

const v$ = useVuelidate(rules, {
  agentName,
  selectedRoleId,
  agentAvailability,
});

const pageTitle = computed(
  () => `${t('AGENT_MGMT.EDIT.TITLE')} - ${props.name}`
);

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');
const agents = useMapGetter('agents/getAgents');

const responsibleOptions = computed(() => {
  return agents.value
    .filter(agent => agent.id !== props.id)
    .map(agent => ({
      value: agent.current_account_user_id,
      label: agent.name,
    }));
});

const roles = computed(() => {
  const defaultRoles = [
    {
      id: 'administrator',
      name: 'administrator',
      label: t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
    },
    {
      id: 'agent',
      name: 'agent',
      label: t('AGENT_MGMT.AGENT_TYPES.AGENT'),
    },
  ];

  const customRoles = getCustomRoles.value.map(role => ({
    id: role.id,
    name: `custom_${role.id}`,
    label: role.name,
  }));

  return [...defaultRoles, ...customRoles];
});

const selectedRole = computed(() =>
  roles.value.find(
    role =>
      role.id === selectedRoleId.value || role.name === selectedRoleId.value
  )
);

const statusList = computed(() => {
  return [
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
  ];
});

const availabilityStatuses = computed(() =>
  statusList.value.map((statusLabel, index) => ({
    label: statusLabel,
    value: AVAILABILITY_STATUS_KEYS[index],
    disabled: props.availability === AVAILABILITY_STATUS_KEYS[index],
  }))
);

const editAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid || isPhoneNumberNotValid.value) return;

  try {
    const availability = childRef.value.updateWeeklyAvailability();

    const payload = {
      id: props.id,
      name: agentName.value,
      phone_number: setPhoneNumber.value,
      availability: agentAvailability.value,
      ...availability,
    };

    if (selectedResponsibleId.value) {
      payload.responsible_id = selectedResponsibleId.value;
    }

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
      payload.custom_role_id = null;
    }

    await store.dispatch('agents/update', payload);
    useAlert(t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

const resetPassword = async () => {
  try {
    await Auth.resetPassword(agentCredentials.value);
    useAlert(t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.PASSWORD_RESET.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form class="w-full" @submit.prevent="editAgent">
      <div class="w-full">
        <label :class="{ error: v$.agentName.$error }">
          {{ $t('AGENT_MGMT.EDIT.FORM.NAME.LABEL') }}
          <input
            v-model="agentName"
            type="text"
            :placeholder="$t('AGENT_MGMT.EDIT.FORM.NAME.PLACEHOLDER')"
            @input="v$.agentName.$touch"
          />
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.selectedRoleId.$error }">
          {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.LABEL') }}
          <select v-model="selectedRoleId" @change="v$.selectedRoleId.$touch">
            <option v-for="role in roles" :key="role.id" :value="role.id">
              {{ role.label }}
            </option>
          </select>
          <span v-if="v$.selectedRoleId.$error" class="message">
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: isPhoneNumberNotValid }">
          {{ $t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.LABEL') }}
          <woot-phone-input
            v-model="agentPhoneNumber"
            :value="agentPhoneNumber"
            :error="isPhoneNumberNotValid"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.PLACEHOLDER')"
            @set-code="setPhoneCode"
          />
          <span v-if="isPhoneNumberNotValid" class="message">
            {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.agentAvailability.$error }">
          {{ $t('PROFILE_SETTINGS.FORM.AVAILABILITY.LABEL') }}
          <select
            v-model="agentAvailability"
            @change="v$.agentAvailability.$touch"
          >
            <option
              v-for="status in availabilityStatuses"
              :key="status.value"
              :value="status.value"
            >
              {{ status.label }}
            </option>
          </select>
          <span v-if="v$.agentAvailability.$error" class="message">
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_AVAILABILITY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full">
        <label>
          {{ $t('AGENT_MGMT.EDIT.FORM.RESPONSIBLE.LABEL') }}
          <ComboBox
            v-model="selectedResponsibleId"
            :options="responsibleOptions"
            :placeholder="$t('AGENT_MGMT.EDIT.FORM.RESPONSIBLE.PLACEHOLDER')"
            :search-placeholder="
              $t('AGENT_MGMT.EDIT.FORM.RESPONSIBLE.SEARCH_PLACEHOLDER')
            "
            :empty-state="$t('AGENT_MGMT.EDIT.FORM.RESPONSIBLE.EMPTY_STATE')"
            class="[&_button]:!bg-n-alpha-black2"
          />
        </label>
      </div>

      <div>
        <WeeklyAvailabilitySection ref="childRef" :user="agent" />
      </div>

      <div class="flex flex-row justify-start w-full gap-2 px-0 py-2">
        <div class="w-[50%] ltr:text-left rtl:text-right">
          <Button
            v-if="provider !== 'saml'"
            ghost
            type="button"
            icon="i-lucide-lock-keyhole"
            class="!px-2"
            :label="$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_RESET_BUTTON')"
            @click.prevent="resetPassword"
          />
        </div>
        <div class="w-[50%] flex justify-end items-center gap-2">
          <Button
            faded
            slate
            type="reset"
            :label="$t('AGENT_MGMT.EDIT.CANCEL_BUTTON_TEXT')"
            @click.prevent="emit('close')"
          />
          <Button
            type="submit"
            :label="$t('AGENT_MGMT.EDIT.FORM.SUBMIT')"
            :disabled="v$.$invalid || uiFlags.isUpdating"
            :is-loading="uiFlags.isUpdating"
          />
        </div>
      </div>
    </form>
  </div>
</template>
