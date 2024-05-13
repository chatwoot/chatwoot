<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.TITLE')"
      :header-content="
        $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.DESCRIPTION')
      "
    />

    <div class="flex flex-col h-auto overflow-auto">
      <div class="flex flex-col px-8 pb-4">
        <woot-tabs
          class="ltr:[&>ul]:pl-0 rtl:[&>ul]:pr-0"
          :index="selectedTabIndex"
          @change="onClickTabChange"
        >
          <woot-tabs-item
            v-for="tab in tabs"
            :key="tab.key"
            :name="tab.name"
            :show-badge="false"
          />
        </woot-tabs>
      </div>
      <div v-if="selectedTabIndex === 0" class="flex flex-col px-8 pb-4">
        <create-issue
          :account-id="accountId"
          :conversation-id="conversationId"
        />
      </div>

      <div v-if="selectedTabIndex === 1" class="flex flex-col px-8 pb-4">
        <link-issue
          :conversation-id="conversationId"
          @agents-filter-selection="handleAgentsFilterSelection"
        />
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import LinearAPI from 'dashboard/api/integrations/linear';
import LinkIssue from './LinkIssue';
import CreateIssue from './CreateIssue';

import validations from './validations';

export default {
  components: {
    LinkIssue,
    CreateIssue,
  },
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
    tabs() {
      return [
        {
          key: 0,
          name: this.$t('INTEGRATION_SETTINGS.LINEAR.CREATE'),
        },
        {
          key: 1,
          name: this.$t('INTEGRATION_SETTINGS.LINEAR.LINK'),
        },
      ];
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
