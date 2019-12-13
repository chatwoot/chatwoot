<template>
  <div class="column content-box">
    <button
      class="button nice icon success button--fixed-right-top"
      @click="openAddPopup()"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ $t('AGENT_MGMT.HEADER_BTN_TXT') }}
    </button>
    <!-- Canned Response API Status -->

    <!-- List Agents -->
    <div class="row">
      <div class="small-8 columns">
        <woot-loading-state
          v-if="fetchStatus"
          :message="$t('AGENT_MGMT.LOADING')"
        />
        <p v-if="!fetchStatus && !agentList.length">
          {{ $t('AGENT_MGMT.LIST.404') }}
        </p>
        <table v-if="!fetchStatus && agentList.length" class="woot-table">
          <tbody>
            <tr v-for="(agent, index) in agentList" :key="agent.email">
              <!-- Gravtar Image -->

              <td>
                <thumbnail
                  :src="gravatarUrl(agent.email)"
                  class="columns"
                  :username="agent.name"
                  size="40px"
                />
              </td>
              <!-- Agent Name + Email -->
              <td>
                <span class="agent-name">{{ agent.name }}</span>
                <span>{{ agent.email }}</span>
              </td>
              <!-- Agent Role + Verification Status -->
              <td>
                <span class="agent-name">{{ agent.role }}</span>
                <span v-if="agent.confirmed">
                  {{ $t('AGENT_MGMT.LIST.VERIFIED') }}
                </span>
                <span v-if="!agent.confirmed">
                  {{ $t('AGENT_MGMT.LIST.VERIFICATION_PENDING') }}
                </span>
              </td>
              <!-- Actions -->
              <td>
                <div v-if="showActions(agent)" class="button-wrapper">
                  <div @click="openEditPopup(agent)">
                    <woot-submit-button
                      :button-text="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                      icon-class="ion-edit"
                      button-class="link hollow grey-btn"
                    />
                  </div>
                  <div @click="openDeletePopup(agent, index)">
                    <woot-submit-button
                      :button-text="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
                      :loading="loading[agent.id]"
                      icon-class="ion-close-circled"
                      button-class="link hollow grey-btn"
                    />
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="small-4 columns">
        <span v-html="$t('AGENT_MGMT.SIDEBAR_TXT')"></span>
      </div>
    </div>
    <!-- Add Agent -->
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-agent :on-close="hideAddPopup" />
    </woot-modal>

    <!-- Edit Agent -->
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-agent
        v-if="showEditPopup"
        :id="currentAgent.id"
        :name="currentAgent.name"
        :type="currentAgent.role"
        :email="currentAgent.email"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <!-- Delete Agent -->
    <delete-agent
      :show.sync="showDeletePopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('AGENT_MGMT.DELETE.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />

    <!-- Loader Status -->
  </div>
</template>
<script>
/* global bus */

import { mapGetters } from 'vuex';
import md5 from 'md5';
import Thumbnail from '../../../../components/widgets/Thumbnail';

import AddAgent from './AddAgent';
import EditAgent from './EditAgent';
import DeleteAgent from './DeleteAgent';

export default {
  components: {
    AddAgent,
    EditAgent,
    DeleteAgent,
    Thumbnail,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeletePopup: false,
      showEditPopup: false,
      agentAPI: {
        message: '',
      },
      currentAgent: {},
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'getAgents',
      fetchStatus: 'getAgentFetchStatus',
    }),
    deleteConfirmText() {
      return `${this.$t('AGENT_MGMT.DELETE.CONFIRM.YES')} ${
        this.currentAgent.name
      }`;
    },
    deleteRejectText() {
      return `${this.$t('AGENT_MGMT.DELETE.CONFIRM.NO')} ${
        this.currentAgent.name
      }`;
    },
    deleteMessage() {
      return `${this.$t('AGENT_MGMT.DELETE.CONFIRM.MESSAGE')} ${
        this.currentAgent.name
      } ?`;
    },
  },
  mounted() {
    this.$store.dispatch('fetchAgents');
  },
  methods: {
    showActions(agent) {
      if (agent.role === 'administrator') {
        const adminList = this.agentList.filter(
          item => item.role === 'administrator'
        );
        return adminList.length !== 1;
      }
      return true;
    },
    // List Functions
    // Gravatar URL
    gravatarUrl(email) {
      const hash = md5(email);
      return `${window.WootConstants.GRAVATAR_URL}${hash}?default=404`;
    },
    // Edit Function
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },

    // Edit Function
    openEditPopup(agent) {
      this.showEditPopup = true;
      this.currentAgent = agent;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },

    // Delete Function
    openDeletePopup(agent) {
      this.showDeletePopup = true;
      this.currentAgent = agent;
    },
    closeDeletePopup() {
      this.showDeletePopup = false;
    },
    confirmDeletion() {
      this.loading[this.currentAgent.id] = true;
      this.closeDeletePopup();
      this.deleteAgent(this.currentAgent.id);
    },
    deleteAgent(id) {
      this.$store
        .dispatch('deleteAgent', {
          id,
        })
        .then(() => {
          this.showAlert(this.$t('AGENT_MGMT.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          this.showAlert(this.$t('AGENT_MGMT.DELETE.API.ERROR_MESSAGE'));
        });
    },
    // Show SnackBar
    showAlert(message) {
      // Reset loading, current selected agent
      this.loading[this.currentAgent.id] = false;
      this.currentAgent = {};
      // Show message
      this.agentAPI.message = message;
      bus.$emit('newToastMessage', message);
    },
  },
};
</script>
