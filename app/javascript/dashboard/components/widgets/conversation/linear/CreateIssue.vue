<script setup>
import { reactive, computed, onMounted, ref } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import LinearAPI from 'dashboard/api/integrations/linear';
import validations from './validations';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';
import SearchableDropdown from './SearchableDropdown.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  title: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();

const teams = ref([]);
const assignees = ref([]);
const projects = ref([]);
const labels = ref([]);
const statuses = ref([]);

const priorities = [
  { id: 0, name: 'No priority' },
  { id: 1, name: 'Urgent' },
  { id: 2, name: 'High' },
  { id: 3, name: 'Normal' },
  { id: 4, name: 'Low' },
];

const statusDesiredOrder = [
  'Backlog',
  'Todo',
  'In Progress',
  'Done',
  'Canceled',
];

const isCreating = ref(false);
const inputStyles = { borderRadius: '12px', fontSize: '14px' };

const formState = reactive({
  title: '',
  description: '',
  teamId: '',
  assigneeId: '',
  labelId: '',
  stateId: '',
  priority: '',
  projectId: '',
});
const v$ = useVuelidate(validations, formState);

const isSubmitDisabled = computed(
  () => v$.value.title.$invalid || isCreating.value
);
const nameError = computed(() =>
  v$.value.title.$error
    ? t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.REQUIRED_ERROR')
    : ''
);
const teamError = computed(() =>
  v$.value.teamId.$error
    ? t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.REQUIRED_ERROR')
    : ''
);

const dropdowns = computed(() => {
  return [
    {
      type: 'teamId',
      label: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.LABEL',
      items: teams.value,
      placeholder: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.SEARCH',
      error: teamError.value,
    },
    {
      type: 'assigneeId',
      label: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.ASSIGNEE.LABEL',
      items: assignees.value,
      placeholder:
        'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.ASSIGNEE.SEARCH',
      error: '',
    },
    {
      type: 'labelId',
      label: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.LABEL.LABEL',
      items: labels.value,
      placeholder: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.LABEL.SEARCH',
      error: '',
    },
    {
      type: 'priority',
      label: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PRIORITY.LABEL',
      items: priorities,
      placeholder:
        'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PRIORITY.SEARCH',
      error: '',
    },
    {
      type: 'projectId',
      label: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PROJECT.LABEL',
      items: projects.value,
      placeholder:
        'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PROJECT.SEARCH',
      error: '',
    },
    {
      type: 'stateId',
      label: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.STATUS.LABEL',
      items: statuses.value,
      placeholder: 'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.STATUS.SEARCH',
      error: '',
    },
  ];
});

const onClose = () => emit('close');

const getTeams = async () => {
  try {
    const response = await LinearAPI.getTeams();
    teams.value = response.data;
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ERROR')
    );
    useAlert(errorMessage);
  }
};

const getTeamEntities = async () => {
  try {
    const response = await LinearAPI.getTeamEntities(formState.teamId);
    assignees.value = response.data.users;
    labels.value = response.data.labels;
    projects.value = response.data.projects;
    statuses.value = statusDesiredOrder
      .map(name => response.data.states.find(status => status.name === name))
      .filter(Boolean);
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ENTITIES_ERROR')
    );
    useAlert(errorMessage);
  }
};

const onChange = (item, type) => {
  formState[type] = item.id;
  if (type === 'teamId') {
    formState.assigneeId = '';
    formState.stateId = '';
    formState.labelId = '';
    formState.projectId = '';
    getTeamEntities();
  }
};

const createIssue = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const payload = {
    team_id: formState.teamId,
    title: formState.title,
    description: formState.description || undefined,
    assignee_id: formState.assigneeId || undefined,
    project_id: formState.projectId || undefined,
    state_id: formState.stateId || undefined,
    priority: formState.priority || undefined,
    label_ids: formState.labelId ? [formState.labelId] : undefined,
  };

  try {
    isCreating.value = true;
    const response = await LinearAPI.createIssue(payload);
    const { id: issueId } = response.data;
    await LinearAPI.link_issue(props.conversationId, issueId, props.title);
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_SUCCESS'));
    onClose();
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_ERROR')
    );
    useAlert(errorMessage);
  } finally {
    isCreating.value = false;
  }
};

onMounted(getTeams);
</script>

<template>
  <div>
    <woot-input
      v-model="formState.title"
      :class="{ error: v$.title.$error }"
      class="w-full"
      :styles="{ ...inputStyles, padding: '6px 12px' }"
      :label="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.LABEL')"
      :placeholder="
        $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.PLACEHOLDER')
      "
      :error="nameError"
      @input="v$.title.$touch"
    />
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.DESCRIPTION.LABEL') }}
      <textarea
        v-model="formState.description"
        :style="{ ...inputStyles, padding: '8px 12px' }"
        rows="3"
        class="text-sm"
        :placeholder="
          $t(
            'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.DESCRIPTION.PLACEHOLDER'
          )
        "
      />
    </label>
    <div class="flex flex-col gap-4">
      <SearchableDropdown
        v-for="dropdown in dropdowns"
        :key="dropdown.type"
        :type="dropdown.type"
        :value="formState[dropdown.type]"
        :label="$t(dropdown.label)"
        :items="dropdown.items"
        :placeholder="$t(dropdown.placeholder)"
        :error="dropdown.error"
        @change="onChange"
      />
    </div>
    <div class="flex items-center justify-end w-full gap-2 mt-8">
      <woot-button
        class="px-4 rounded-xl button clear outline-woot-200/50 outline"
        @click.prevent="onClose"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CANCEL') }}
      </woot-button>
      <woot-button
        :is-disabled="isSubmitDisabled"
        class="px-4 rounded-xl"
        :is-loading="isCreating"
        @click.prevent="createIssue"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE') }}
      </woot-button>
    </div>
  </div>
</template>
