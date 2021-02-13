<template>
  <div class="conv-header">
    <div class="user" :class="{ hide: isContactPanelOpen }">
      <Thumbnail
        :src="currentContact.thumbnail"
        size="40px"
        :badge="chatMetadata.channel"
        :username="currentContact.name"
        :status="currentContact.availability_status"
      />
      <div class="user--profile__meta">
        <h3 v-if="!isContactPanelOpen" class="user--name text-truncate">
          {{ currentContact.name }}
        </h3>
        <button
          class="user--profile__button clear button small"
          @click="$emit('contact-panel-toggle')"
        >
          {{
            `${$t('CONVERSATION.HEADER.OPEN')} ${$t(
              'CONVERSATION.HEADER.DETAILS'
            )}`
          }}
        </button>
      </div>
    </div>
    <div
      class="header-actions-wrap"
      :class="{ 'has-open-sidebar': isContactPanelOpen }"
    >
      <div class="multiselect-box ion-headphone">
        <multiselect
          v-model="currentChat.meta.assignee"
          :allow-empty="true"
          deselect-label=""
          :options="asignneList"
          :placeholder="$t('CONVERSATION.ASSIGNMENT.SELECT_AGENT')"
          group-values="targets"
          group-label="targetType"
          select-label=""
          label="name"
          selected-label
          track-by="id"
          @select="setAssignee"
          @remove="removeAgent"
        >
          <span slot="noResult">{{ $t('AGENT_MGMT.SEARCH.NO_RESULTS') }}</span>
        </multiselect>
      </div>
      <more-actions :conversation-id="currentChat.id" />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import MoreActions from './MoreActions';
import Thumbnail from '../Thumbnail';

const TYPE_TEAM = 'team';
const TYPE_AGENT = 'agent';

export default {
  components: {
    MoreActions,
    Thumbnail,
  },

  props: {
    chat: {
      type: Object,
      default: () => {},
    },
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      currentChatAssignee: null,
    };
  },

  computed: {
    ...mapGetters({
      agents: 'agents/getVerifiedAgents',
      teams: 'teams/getTeams',
      currentChat: 'getSelectedChat',
    }),

    chatMetadata() {
      return this.chat.meta;
    },

    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.chat.meta.sender.id
      );
    },

    agentList() {
      return [
        {
          confirmed: true,
          name: 'None',
          id: 0,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...this.agents,
      ];
    },
    asignneList() {
      const agents = this.agents.map(agent => ({
        ...agent,
        assigneeType: TYPE_AGENT,
      }));
      const teams = this.teams.map(team => ({
        ...team,
        assigneeType: TYPE_TEAM,
      }));
      return [
        {
          targetType: 'Agents',
          targets: agents,
        },
        {
          targetType: 'Teams',
          targets: teams,
        },
      ];
    },
  },

  methods: {
    setAssignee(item) {
      const { assigneeType } = item;
      const assigneeKey = assigneeType === TYPE_AGENT ? 'agentId' : 'teamId';

      this.$store
        .dispatch('setAssignee', {
          conversationId: this.currentChat.id,
          [assigneeKey]: item.id,
        })
        .then(() => {
          bus.$emit('newToastMessage', this.$t('CONVERSATION.CHANGE_AGENT'));
        });
    },

    removeAgent() {},
  },
};
</script>

<style lang="scss" scoped>
.text-truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
