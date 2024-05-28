<template>
  <div @submit.prevent="onSubmit">
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
    <label :class="{ error: v$.teamId.$error }">
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.LABEL') }}
      <select
        v-model="formState.teamId"
        :style="inputStyles"
        @change="onChangeTeam"
      >
        <option v-for="item in teams" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
      <span v-if="v$.teamId.$error" class="message">
        {{ teamError }}
      </span>
    </label>
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.ASSIGNEE.LABEL') }}
      <select v-model="formState.assigneeId" :style="inputStyles">
        <option v-for="item in assignees" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.LABEL.LABEL') }}
      <select v-model="formState.labelId" :style="inputStyles">
        <option v-for="item in labels" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PRIORITY.LABEL') }}
      <select v-model="formState.priority" :style="inputStyles">
        <option v-for="item in priorities" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PROJECT.LABEL') }}
      <select v-model="formState.projectId" :style="inputStyles">
        <option v-for="item in projects" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.STATUS.LABEL') }}
      <select v-model="formState.stateId" :style="inputStyles">
        <option v-for="item in statuses" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>
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

<script setup>
import { reactive, computed, onMounted, ref } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert } from 'dashboard/composables';
import LinearAPI from 'dashboard/api/integrations/linear';
import validations from './validations';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';

const props = defineProps({
  accountId: {
    type: [Number, String],
    required: true,
  },
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

const onChangeTeam = event => {
  formState.teamId = event.target.value;
  formState.assigneeId = '';
  formState.stateId = '';
  formState.labelId = '';
  getTeamEntities();
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
