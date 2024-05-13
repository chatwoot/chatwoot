<template>
  <div @submit.prevent="onSubmit">
    <woot-input
      v-model="title"
      :class="{ error: $v.title.$error }"
      class="w-full"
      :styles="inputStyles"
      :label="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.LABEL')"
      :placeholder="
        $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.PLACEHOLDER')
      "
      :error="
        $v.title.$error
          ? $t(
              'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TITLE.REQUIRED_ERROR'
            )
          : ''
      "
      @input="$v.title.$touch"
    />
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.DESCRIPTION.LABEL') }}
      <textarea
        v-model="description"
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
    <label :class="{ error: $v.teamId.$error }">
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.LABEL') }}
      <select
        v-model="teamId"
        :styles="inputStyles"
        @change="onChangeTeam($event)"
      >
        <option v-for="item in teams" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
      <span v-if="$v.teamId.$error" class="message">
        {{
          $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.REQUIRED_ERROR')
        }}
      </span>
    </label>
    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.ASSIGNEE.LABEL') }}
      <select v-model="assigneeId" :styles="inputStyles">
        <option v-for="item in assignees" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.LABEL.LABEL') }}
      <select v-model="labelId" :styles="inputStyles">
        <option v-for="item in labels" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PRIORITY.LABEL') }}
      <select v-model="priority" :styles="inputStyles">
        <option v-for="item in priorities" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.PROJECT.LABEL') }}
      <select v-model="projectId" :styles="inputStyles">
        <option v-for="item in projects" :key="item.name" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </label>

    <label>
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.STATUS.LABEL') }}
      <select v-model="stateId" :styles="inputStyles">
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

<script>
import alertMixin from 'shared/mixins/alertMixin';
import LinearAPI from 'dashboard/api/integrations/linear';

import validations from './validations';

export default {
  mixins: [alertMixin],
  props: {
    accountId: {
      type: [Number, String],
      required: true,
    },
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      title: '',
      description: '',
      teamId: '',
      assigneeId: '',
      projectId: '',
      stateId: '',
      labelId: '',
      priority: 0,
      teams: [],
      assignees: [],
      projects: [],
      labels: [],
      statuses: [],
      selectedTabIndex: 0,
      priorities: [
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
      ],
      isCreating: false,
      searchResults: [
        {
          id: 1,
          title: 'Test',
        },
      ],
      inputStyles: {
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
      },
    };
  },
  validations,
  computed: {
    isSubmitDisabled() {
      return this.$v.title.$invalid || this.isCreating;
    },
  },
  mounted() {
    this.getTeams();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onClickTabChange(index) {
      this.selectedTabIndex = index;
    },
    onChangeTeam(event) {
      this.teamId = event.target.value;
      this.assigneeId = '';
      this.stateId = '';
      this.labelId = '';
      this.getTeamEntities();
    },
    async getTeams() {
      try {
        const response = await LinearAPI.getTeams();
        this.teams = response.data;
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ERROR')
        );
      } finally {
        this.isLoading = false;
      }
    },
    async getTeamEntities() {
      try {
        const response = await LinearAPI.getTeamEntities(this.teamId);
        const { users, labels, projects, states } = response.data;
        this.assignees = users;
        this.labels = labels;
        this.statuses = states;
        this.projects = projects;
      } catch (error) {
        this.showAlert(
          this.$t(
            'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ENTITIES_ERROR'
          )
        );
      } finally {
        this.isLoading = false;
      }
    },
    async createIssue() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      const payload = {
        team_id: this.teamId,
        title: this.title,
      };
      if (this.description) {
        payload.description = this.description;
      }
      if (this.assigneeId) {
        payload.assignee_id = this.assigneeId;
      }
      if (this.projectId) {
        payload.project_id = this.projectId;
      }
      if (this.stateId) {
        payload.state_id = this.stateId;
      }
      if (this.priority) {
        payload.priority = this.priority;
      }
      if (this.labelId) {
        payload.label_ids = [this.labelId];
      }
      try {
        this.isCreating = true;
        const response = await LinearAPI.createIssue(payload);
        const { id: issueId } = response.data;
        await LinearAPI.link_issue(this.conversationId, issueId);
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_SUCCESS')
        );
        this.onClose();
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_ERROR')
        );
      } finally {
        this.isCreating = false;
      }
    },
    handleAgentsFilterSelection() {},
  },
};
</script>
