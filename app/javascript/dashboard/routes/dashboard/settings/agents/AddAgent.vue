<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import WeeklyAvailabilitySection from '../components/WeeklyAvailabilitySection.vue';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const agentName = ref('');
const agentEmail = ref('');
const agentPhoneNumber = ref('');
const activeDialCode = ref('');
const selectedRoleId = ref('agent');
const responsibleId = ref(null);
const locationId = ref(null);

const parsedPhoneNumber = computed(() => {
  return parsePhoneNumber(agentPhoneNumber.value || '');
});

const isPhoneNumberNotValid = computed(() => {
  if (agentPhoneNumber.value !== '') {
    return (
      !isPhoneNumberValid(agentPhoneNumber.value, activeDialCode.value) ||
      (agentPhoneNumber.value !== '' ? activeDialCode.value === '' : false)
    );
  }
  return false;
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

const setPhoneCode = code => {
  if (agentPhoneNumber.value !== '' && parsedPhoneNumber.value) {
    const dialCode = parsedPhoneNumber.value.countryCallingCode;
    if (dialCode === code) {
      return;
    }
    activeDialCode.value = `+${dialCode}`;
    const newPhoneNumber = agentPhoneNumber.value.replace(
      `+${dialCode}`,
      `${code}`
    );
    agentPhoneNumber.value = newPhoneNumber;
  } else {
    activeDialCode.value = code;
  }
};

const rules = {
  agentName: { required },
  agentEmail: { required, email },
  selectedRoleId: { required },
};

const v$ = useVuelidate(rules, {
  agentName,
  agentEmail,
  selectedRoleId,
});

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');
const agents = useMapGetter('agents/getAgents');
const locations = useMapGetter('locations/getLocations');

const responsibleOptions = computed(() => {
  return agents.value.map(agent => ({
    value: agent.current_account_user_id,
    label: agent.name,
  }));
});

const locationOptions = computed(() => {
  return locations.value.map(location => ({
    value: location.id,
    label: location.name,
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
      id: 'supervisor',
      name: 'supervisor',
      label: t('AGENT_MGMT.AGENT_TYPES.SUPERVISOR'),
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

const childRef = ref(null);

const addAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid || isPhoneNumberNotValid.value) return;

  try {
    const availability = childRef.value.updateWeeklyAvailability();

    const payload = {
      name: agentName.value,
      email: agentEmail.value,
      phone_number: setPhoneNumber.value,
      ...availability,
    };

    if (responsibleId.value) {
      payload.responsible_id = responsibleId.value;
    }

    if (locationId.value) {
      payload.location_id = locationId.value;
    }

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
    }

    await store.dispatch('agents/create', payload);
    useAlert(t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    const {
      response: {
        data: {
          error: errorResponse = '',
          attributes: attributes = [],
          message: attrError = '',
        } = {},
      } = {},
    } = error;

    let errorMessage = '';
    if (error?.response?.status === 422 && !attributes.includes('base')) {
      errorMessage = t('AGENT_MGMT.ADD.API.EXIST_MESSAGE');
    } else {
      errorMessage = t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
    }
    useAlert(errorResponse || attrError || errorMessage);
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('AGENT_MGMT.ADD.TITLE')"
      :header-content="$t('AGENT_MGMT.ADD.DESC')"
    />
    <form class="flex flex-col items-start w-full" @submit.prevent="addAgent">
      <div class="w-full">
        <label :class="{ error: v$.agentName.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.NAME.LABEL') }}
          <input
            v-model="agentName"
            type="text"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
            @input="v$.agentName.$touch"
          />
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.selectedRoleId.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
          <select v-model="selectedRoleId" @change="v$.selectedRoleId.$touch">
            <option v-for="role in roles" :key="role.id" :value="role.id">
              {{ role.label }}
            </option>
          </select>
          <span v-if="v$.selectedRoleId.$error" class="message">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.agentEmail.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.LABEL') }}
          <input
            v-model="agentEmail"
            type="email"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.EMAIL.PLACEHOLDER')"
            @input="v$.agentEmail.$touch"
          />
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
        <label>
          {{ $t('AGENT_MGMT.ADD.FORM.RESPONSIBLE.LABEL') }}
          <ComboBox
            v-model="responsibleId"
            :options="responsibleOptions"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.RESPONSIBLE.PLACEHOLDER')"
            :search-placeholder="
              $t('AGENT_MGMT.ADD.FORM.RESPONSIBLE.SEARCH_PLACEHOLDER')
            "
            :empty-state="$t('AGENT_MGMT.ADD.FORM.RESPONSIBLE.EMPTY_STATE')"
            class="[&_button]:!bg-n-alpha-black2"
          />
        </label>
      </div>

      <div class="w-full">
        <label>
          {{ $t('AGENT_MGMT.ADD.FORM.LOCATION.LABEL') }}
          <ComboBox
            v-model="locationId"
            :options="locationOptions"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.LOCATION.PLACEHOLDER')"
            :search-placeholder="
              $t('AGENT_MGMT.ADD.FORM.LOCATION.SEARCH_PLACEHOLDER')
            "
            :empty-state="$t('AGENT_MGMT.ADD.FORM.LOCATION.EMPTY_STATE')"
            class="[&_button]:!bg-n-alpha-black2"
          />
        </label>
      </div>

      <div>
        <WeeklyAvailabilitySection ref="childRef" :user="agent" />
      </div>

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <Button
          faded
          slate
          type="reset"
          :label="$t('AGENT_MGMT.ADD.CANCEL_BUTTON_TEXT')"
          @click.prevent="emit('close')"
        />
        <Button
          type="submit"
          :label="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
          :disabled="v$.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
        />
      </div>
    </form>
  </div>
</template>
