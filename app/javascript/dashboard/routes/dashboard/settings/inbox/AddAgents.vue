<template>
  <div class="wizard-body columns content-box small-9">
    <loading-state v-if="showLoader" :message="emptyStateMessage">
    </loading-state>
    <form v-if="!showLoader" class="row" @submit.prevent="addAgents()">
      <div class="medium-12 columns">
        <page-header
          :header-title="$t('INBOX_MGMT.ADD.AGENTS.TITLE')"
          :header-content="$t('INBOX_MGMT.ADD.AGENTS.DESC')"
        />
      </div>
      <div class="medium-7 columns">
        <div class="medium-12 columns">
          <label :class="{ error: $v.selectedAgents.$error }">
            Agents
            <multiselect
              v-model="selectedAgents"
              :options="agentList"
              track-by="id"
              label="name"
              :multiple="true"
              :close-on-select="false"
              :clear-on-select="false"
              :hide-selected="true"
              placeholder="Pick some"
              @select="$v.selectedAgents.$touch"
            >
            </multiselect>
            <span v-if="$v.selectedAgents.$error" class="message">
              Add atleast one agent to your new Inbox
            </span>
          </label>
        </div>
        <div class="medium-12 columns text-right">
          <input type="submit" value="Create Inbox" class="button" />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';

import ChannelApi from '../../../../api/channels';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader';
import LoadingState from '../../../../components/widgets/LoadingState';

export default {
  components: {
    PageHeader,
    LoadingState,
  },

  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },

  data() {
    return {
      emptyStateMessage: this.$t('INBOX_MGMT.AGENTS.ADD_AGENTS'),
      showLoader: false,
      selectedAgents: [],
    };
  },

  computed: {
    ...mapGetters({
      agentList: 'getAgents',
    }),
  },

  mounted() {
    this.$store.dispatch('fetchAgents');
  },

  methods: {
    addAgents() {
      this.isCreating = true;
      const inboxId = this.$route.params.inbox_id;
      ChannelApi.addAgentsToChannel(inboxId, this.selectedAgents.map(x => x.id))
        .then(() => {
          this.isCreating = false;
          router.replace({
            name: 'settings_inbox_finish',
            params: {
              page: 'new',
              inbox_id: this.$route.params.inbox_id,
              website_token: this.$route.params.website_token,
            },
          });
        })
        .catch(error => {
          bus.$emit('newToastMessage', error.message);
          this.isCreating = false;
        });
    },
  },
};
</script>
