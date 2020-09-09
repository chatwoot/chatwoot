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
          :options="agentList"
          label="available_name"
          :allow-empty="true"
          deselect-label="Remove"
          placeholder="Select Agent"
          selected-label
          select-label="Assign"
          track-by="id"
          @select="assignAgent"
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
          available_name: 'None',
          id: 0,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...this.agents,
      ];
    },
  },

  methods: {
    assignAgent(agent) {
      this.$store
        .dispatch('assignAgent', {
          conversationId: this.currentChat.id,
          agentId: agent.id,
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
