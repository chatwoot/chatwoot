<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      header-title="Create/link linear issue"
      header-content="Quickly create/link a linear issue from this conversation"
    />

    <div class="flex flex-col h-auto overflow-auto">
      <div class="flex flex-col px-8 pb-4" @submit.prevent="onSubmit">
        <woot-input
          v-model="title"
          label="Title"
          class="w-full"
          placeholder="Enter title"
          type="text"
          @blur="$v.title.$touch"
        />
        <label>
          Description
          <textarea
            v-model="description"
            rows="6"
            type="text"
            placeholder="Enter description"
            @blur="$v.description.$touch"
          />
        </label>

        <label>
          Team
          <select v-model="teamId" @change="onChangeTeam($event)">
            <option v-for="item in teams" :key="item.name" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>
        <label>
          Assignee
          <select v-model="assigneeId">
            <option v-for="item in assignees" :key="item.id" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>

        <label>
          Priority
          <select v-model="priority">
            <option v-for="item in priorities" :key="item.id" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>

        <label>
          Label
          <select v-model="labelId">
            <option v-for="item in labels" :key="item.id" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>

        <label>
          Status
          <select v-model="stateId">
            <option v-for="item in statuses" :key="item.id" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>

        <div class="flex items-center justify-end w-full gap-2 mt-8">
          <woot-button
            class="px-4 rounded-xl button clear outline-woot-200/50 outline"
            @click.prevent="onClose"
          >
            {{ $t('SLA.FORM.CANCEL') }}
          </woot-button>
          <woot-button
            :is-disabled="isSubmitDisabled"
            class="px-4 rounded-xl"
            :is-loading="isCreating"
            @click.prevent="createIssue"
          >
            Create
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { LinearClient } from '@linear/sdk';

// const chatwootAPIKey = '';
const localAPIKey = '';
const linearClient = new LinearClient({
  apiKey: localAPIKey,
});
// const BASE_URL = 'https:app.chatwoot.com';
const BASE_URL = 'http://localhost:3000';

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
      stateId: '',
      labelId: '',
      priority: 0,
      teams: [],
      assignees: [],
      labels: [],
      statuses: [],
      searchTerm: '',
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
    this.getAssignees();
    this.getLabels();
    this.getWorkflowStates();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onChangeTeam(event) {
      this.teamId = event.target.value;
      this.getLabels();
      this.getWorkflowStates();
      this.getAssignees();
    },
    async getTeams() {
      const teams = await linearClient.teams();
      this.teams = teams.nodes;
    },
    async getAssignees() {
      const assignees = await linearClient.users();
      this.assignees = assignees.nodes;
    },
    async getLabels() {
      const labels = await linearClient.issueLabels({
        teamId: this.teamId,
      });
      this.labels = labels.nodes;
    },
    async getWorkflowStates() {
      const states = await linearClient.workflowStates();
      this.statuses = states.nodes;
    },
    async createIssue() {
      this.isCreating = true;
      const response = await linearClient.createIssue({
        teamId: this.teamId,
        title: this.title,
        description: this.description,
        assigneeId: this.assigneeId,
        priority: this.priority,
        labelIds: this.labelId ? [this.labelId] : [],
      });
      const stringifyResponse = JSON.stringify(response);
      const {
        _issue: { id: issueId },
      } = JSON.parse(stringifyResponse);
      this.attachmentLinkURL(issueId);
      this.showAlert('Linear issue created successfully');
    },
    async attachmentLinkURL(issueId) {
      const url =
        BASE_URL +
        frontendURL(
          conversationUrl({
            accountId: this.accountId,
            id: this.conversationId,
          })
        );
      await linearClient.attachmentLinkURL(issueId, url);
      this.isCreating = false;
      this.onClose();
    },

    openSearch() {
      this.showSearchBox = true;
    },
  },
};
</script>
