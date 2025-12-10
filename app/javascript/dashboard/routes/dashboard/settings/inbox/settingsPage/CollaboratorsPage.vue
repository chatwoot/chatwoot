<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { minValue } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const { t } = useI18n();
const { isEnterprise } = useConfig();
const { isCloudFeatureEnabled } = useAccount();

const selectedAgents = ref([]);
const isAgentListUpdating = ref(false);
const enableAutoAssignment = ref(false);
const maxAssignmentLimit = ref(null);
const assignmentType = ref('individual');

const agentList = computed(() => store.getters['agents/getAgents']);

const isWhatsAppGroupsEnabled = computed(() =>
  isCloudFeatureEnabled('whatsapp_groups')
);

const assignmentTypeOptions = computed(() => {
  const options = [
    {
      value: 'individual',
      label: t('INBOX_MGMT.ASSIGNMENT_TYPE.INDIVIDUAL'),
    },
  ];

  if (isWhatsAppGroupsEnabled.value) {
    options.push({
      value: 'group',
      label: t('INBOX_MGMT.ASSIGNMENT_TYPE.GROUP'),
    });
  }

  return options;
});

const validationRules = {
  selectedAgents: {
    isEmpty() {
      return !!selectedAgents.value.length;
    },
  },
  maxAssignmentLimit: {
    minValue: minValue(1),
  },
};

const v$ = useVuelidate(validationRules, {
  selectedAgents,
  maxAssignmentLimit,
});

const maxAssignmentLimitErrors = computed(() => {
  if (v$.value.maxAssignmentLimit.$error) {
    return t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_RANGE_ERROR');
  }
  return '';
});

const setDefaults = () => {
  enableAutoAssignment.value = props.inbox.enable_auto_assignment;
  maxAssignmentLimit.value =
    props.inbox?.auto_assignment_config?.max_assignment_limit || null;

  const configuredType =
    props.inbox?.auto_assignment_config?.assignment_type || 'individual';

  // Reset to 'individual' if 'group' is configured but feature is disabled
  if (configuredType === 'group' && !isWhatsAppGroupsEnabled.value) {
    assignmentType.value = 'individual';
  } else {
    assignmentType.value = configuredType;
  }

  fetchAttachedAgents();
};

const fetchAttachedAgents = async () => {
  try {
    const response = await store.dispatch('inboxMembers/get', {
      inboxId: props.inbox.id,
    });
    const {
      data: { payload: inboxMembers },
    } = response;
    selectedAgents.value = inboxMembers;
  } catch (error) {
    //  Handle error
  }
};

const handleEnableAutoAssignment = () => {
  updateInbox();
};

const updateAgents = async () => {
  const agentList = selectedAgents.value.map(el => el.id);
  isAgentListUpdating.value = true;
  try {
    await store.dispatch('inboxMembers/create', {
      inboxId: props.inbox.id,
      agentList,
    });
    useAlert(t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
  isAgentListUpdating.value = false;
};

const updateInbox = async () => {
  try {
    const payload = {
      id: props.inbox.id,
      formData: false,
      enable_auto_assignment: enableAutoAssignment.value,
      auto_assignment_config: {
        max_assignment_limit: maxAssignmentLimit.value,
        assignment_type: assignmentType.value,
      },
    };
    await store.dispatch('inboxes/updateInbox', payload);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  }
};

watch(() => props.inbox, setDefaults);

onMounted(() => {
  setDefaults();
});
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
    >
      <multiselect
        v-model="selectedAgents"
        :options="agentList"
        track-by="id"
        label="name"
        multiple
        :close-on-select="false"
        :clear-on-select="false"
        hide-selected
        placeholder="Pick some"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
        @select="v$.selectedAgents.$touch"
      />

      <NextButton
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :is-loading="isAgentListUpdating"
        @click="updateAgents"
      />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT_SUB_TEXT')"
    >
      <div class="flex flex-col gap-4">
        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.ASSIGNMENT_TYPE.LABEL') }}
          </label>
          <select
            v-model="assignmentType"
            class="w-full px-3 py-2 text-sm border rounded-xl border-n-weak focus:outline-none focus:ring-2 focus:ring-n-brand"
            @change="updateInbox"
          >
            <option
              v-for="option in assignmentTypeOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
          <p class="mt-1 text-sm text-n-slate-11">
            {{ $t('INBOX_MGMT.ASSIGNMENT_TYPE.SUB_TEXT') }}
          </p>
        </div>

        <label class="w-3/4 settings-item">
          <div class="flex items-center gap-2">
            <input
              id="enableAutoAssignment"
              v-model="enableAutoAssignment"
              type="checkbox"
              @change="handleEnableAutoAssignment"
            />
            <label for="enableAutoAssignment">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT') }}
            </label>
          </div>

          <p class="pb-1 text-sm not-italic text-n-slate-11">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
          </p>
        </label>
      </div>

      <div v-if="enableAutoAssignment && isEnterprise" class="py-3">
        <woot-input
          v-model="maxAssignmentLimit"
          type="number"
          :class="{ error: v$.maxAssignmentLimit.$error }"
          :error="maxAssignmentLimitErrors"
          :label="$t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT')"
          @blur="v$.maxAssignmentLimit.$touch"
        />

        <p class="pb-1 text-sm not-italic text-n-slate-11">
          {{ $t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_SUB_TEXT') }}
        </p>

        <NextButton
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :disabled="v$.maxAssignmentLimit.$invalid"
          @click="updateInbox"
        />
      </div>
    </SettingsSection>
  </div>
</template>
