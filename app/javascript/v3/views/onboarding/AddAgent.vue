<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';

import OnboardingBaseModal from './BaseModal.vue';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const agentName = ref('');
const agentEmail = ref('');
const selectedRoleId = ref('agent');

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

const addAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const payload = {
      name: agentName.value,
      email: agentEmail.value,
    };

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
    }
    await store.dispatch('agents/create', payload);
    useAlert(t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
    await store.dispatch('accounts/update', {
      onboarding_step: 'setup-inbox',
    });

    router.push({ name: 'onboarding_setup_inbox' });
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

// Function to handle "Skip" button click
const skipToNextStep = async () => {
  await store.dispatch('accounts/update', {
    onboarding_step: 'setup-inbox',
  });
  router.push({ name: 'onboarding_setup_inbox' });
};
</script>

<template>
  <OnboardingBaseModal
    :title="$t('AGENT_MGMT.ADD.TITLE')"
    :subtitle="$t('AGENT_MGMT.ADD.DESC')"
  >
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
          <select
            v-model="selectedRoleId"
            class="w-full p-2 border rounded dark:bg-slate-900 text-black-200"
            @change="v$.selectedRoleId.$touch"
          >
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

      <div class="flex flex-row justify-start w-full gap-2 px-0 py-2">
        <woot-submit-button
          :disabled="v$.$invalid || uiFlags.isCreating"
          :button-text="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
          :loading="uiFlags.isCreating"
        />
        <button type="button" class="button clear" @click="skipToNextStep">
          {{ $t('AGENT_MGMT.ADD.FORM.SKIP') }}
        </button>
      </div>
    </form>
  </OnboardingBaseModal>
</template>

<style scoped>
select {
  background-color: #fff;
  color: #ccc;
  border-color: #ccc;
  border-width: 0.001rem;
  border-style: solid;
  border-radius: 0.25rem;
  padding: 0.5rem;
  width: 100%;
}

/* Dark mode styles */
body.dark-mode select {
  background-color: #333;
  color: #fff;
  border-color: #555; /* Darker gray border */
}
select:focus {
  outline: none;
  border-color: #007ee5;
}
.error select {
  border-color: #f56565;
}
.message {
  display: block;
  margin-top: 0.25rem;
}
</style>
