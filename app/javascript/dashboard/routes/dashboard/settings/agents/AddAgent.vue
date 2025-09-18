<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['close']);

const store = useStore();
const router = useRouter();
const route = useRoute();
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

    // Check if we're in onboarding mode (invite team route)
    if (route.name === 'settings_inboxes_invite_team') {
      // Navigate to next step in onboarding flow
      router.push({
        name: 'settings_inboxes_add_agents',
        params: { inbox_id: route.params.inbox_id },
      });
    } else {
      // Normal modal usage - emit close event
      emit('close');
    }
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

const skipInvitations = () => {
  // Skip to next step in onboarding flow
  router.push({
    name: 'settings_inboxes_add_agents',
    params: { inbox_id: route.params.inbox_id },
  });
};
</script>

<template>
  <div
    class="flex flex-col h-auto overflow-auto"
    :class="{ 'p-6': route.name === 'settings_inboxes_invite_team' }"
  >
    <!-- Onboarding mode header -->
    <div v-if="route.name === 'settings_inboxes_invite_team'" class="mb-6">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-white mb-2">
        {{ $t('INBOX_MGMT.CREATE_FLOW.INVITE_TEAM.TITLE') }}
      </h2>
      <p class="text-slate-600 dark:text-slate-400">
        {{ $t('INBOX_MGMT.CREATE_FLOW.INVITE_TEAM.BODY') }}
      </p>
    </div>

    <!-- Modal mode header -->
    <woot-modal-header
      v-else
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

      <!-- Onboarding mode buttons -->
      <div
        v-if="route.name === 'settings_inboxes_invite_team'"
        class="flex flex-row justify-between w-full gap-2 mt-8 pt-6 border-t border-slate-200 dark:border-slate-700"
      >
        <Button faded slate label="Skip for now" @click="skipInvitations" />
        <Button
          type="submit"
          :label="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
          :disabled="v$.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
        />
      </div>

      <!-- Modal mode buttons -->
      <div v-else class="flex flex-row justify-end w-full gap-2 px-0 py-2">
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

    <!-- Help text for onboarding mode -->
    <div
      v-if="route.name === 'settings_inboxes_invite_team'"
      class="mt-4 text-sm text-slate-500 dark:text-slate-400"
    >
      <p>
        {{ $t('AGENT_MGMT.ADD.INVITATION_DESC') }}
      </p>
    </div>
  </div>
</template>
