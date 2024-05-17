<template>
  <div @submit.prevent="onSubmit">
    <woot-input
      v-model="state.title"
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
        v-model="state.description"
        :style="{ ...inputStyles, padding: '8px 12px' }"
        rows="3"
        type="text"
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
        v-model="state.teamId"
        :style="inputStyles"
        @change="onChangeTeam($event)"
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
      <select v-model="state.assigneeId" :style="inputStyles">
        <option v-for="item in assignees" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.LABEL.LABEL') }}
      <select v-model="state.labelId" :style="inputStyles">
        <option v-for="item in labels" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PRIORITY.LABEL') }}
      <select v-model="state.priority" :style="inputStyles">
        <option v-for="item in priorities" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PROJECT.LABEL') }}
      <select v-model="state.projectId" :style="inputStyles">
        <option v-for="item in projects" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.STATUS.LABEL') }}
      <select v-model="state.stateId" :style="inputStyles">
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
import LinearAPI from 'dashboard/api/integrations/linear';
import { reactive, computed, onMounted, ref } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert } from 'dashboard/composables';
import validations from './validations';

const props = defineProps({
  accountId: {
    type: [Number, String],
    required: true,
  },
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const teams = ref([]);
const assignees = ref([]);
const projects = ref([]);
const labels = ref([]);
const statuses = ref([]);

const priorities = [
  {
    id: 0,
    name: 'No priority',
  },
  {
    id: 1,
    name: 'Urgent',
  },
  {
    id: 2,
    name: 'High',
  },
  {
    id: 3,
    name: 'Normal',
  },
  {
    id: 4,
    name: 'Low',
  },
];

const isCreating = ref(false);

const inputStyles = {
  borderRadius: '12px',
  fontSize: '14px',
};
const emit = defineEmits(['close']);

const state = reactive({
  title: '',
  description: '',
  teamId: '',
  assigneeId: '',
  labelId: '',
  stateId: '',
  priority: '',
  projectId: '',
});

const v$ = useVuelidate(validations, state);

const isSubmitDisabled = computed(() => {
  return v$.value.title.$invalid || isCreating.value;
});

const nameError = computed(() => {
  return v$.value.title.$error
    ? t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.REQUIRED_ERROR')
    : '';
});

const teamError = computed(() => {
  return v$.value.teamId.$error
    ? t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.REQUIRED_ERROR')
    : '';
});

const onClose = () => {
  emit('close');
};
const getTeams = async () => {
  try {
    const response = await LinearAPI.getTeams();
    teams.value = response.data;
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ERROR'));
  }
};

const getTeamEntities = async () => {
  try {
    const response = await LinearAPI.getTeamEntities(state.teamId);
    assignees.value = response.data.users;
    labels.value = response.data.labels;
    statuses.value = response.data.states;
    projects.value = response.data.projects;
  } catch (error) {
    useAlert(
      t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ENTITIES_ERROR')
    );
  }
};

const onChangeTeam = event => {
  state.teamId = event.target.value;
  state.assigneeId = '';
  state.stateId = '';
  state.labelId = '';
  getTeamEntities();
};

const createIssue = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }
  const payload = {
    team_id: state.teamId,
    title: state.title,
  };
  if (state.description) {
    payload.description = state.description;
  }
  if (state.assigneeId) {
    payload.assignee_id = state.assigneeId;
  }
  if (state.projectId) {
    payload.project_id = state.projectId;
  }
  if (state.stateId) {
    payload.state_id = state.stateId;
  }
  if (state.priority) {
    payload.priority = state.priority;
  }
  if (state.labelId) {
    payload.label_ids = [state.labelId];
  }
  try {
    isCreating.value = true;
    const response = await LinearAPI.createIssue(payload);
    const { id: issueId } = response.data;
    await LinearAPI.link_issue(props.conversationId, issueId);
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_SUCCESS'));
    onClose();
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_ERROR'));
  } finally {
    isCreating.value = false;
  }
};

onMounted(() => {
  getTeams();
});
</script>
