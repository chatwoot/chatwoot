<template>
  <div class="conv-header">
    <div class="user">
      <Thumbnail
        :src="currentContact.thumbnail"
        size="40px"
        :badge="chatMetadata.channel"
        :username="currentContact.name"
        :status="currentContact.availability_status"
      />
      <div class="user--profile__meta">
        <h3 class="user--name text-truncate">
          {{ currentContact.name }}
        </h3>
        <woot-button
          class="user--profile__button"
          size="small"
          variant="link"
          @click="$emit('contact-panel-toggle')"
        >
          {{
            `${
              isContactPanelOpen
                ? $t('CONVERSATION.HEADER.CLOSE')
                : $t('CONVERSATION.HEADER.OPEN')
            } ${$t('CONVERSATION.HEADER.DETAILS')}`
          }}
        </woot-button>
      </div>
    </div>
    <div
      class="header-actions-wrap"
      :class="{ 'has-open-sidebar': isContactPanelOpen }"
    >
      <agent-dropdown
        :assigned-agent="currentChat.meta.assignee"
        :agents-list="agentList"
        @click="onClickAssignAgent"
      />
      <more-actions :conversation-id="currentChat.id" />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import MoreActions from './MoreActions';
import Thumbnail from '../Thumbnail';
import AgentDropdown from 'shared/components/ui/AgentDropdown.vue';

export default {
  components: {
    MoreActions,
    Thumbnail,
    AgentDropdown,
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
      showSearchDropdown: false,
    };
  },

  computed: {
    ...mapGetters({
      getAgents: 'inboxAssignableAgents/getAssignableAgents',
      uiFlags: 'inboxAssignableAgents/getUIFlags',
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
      const { inbox_id: inboxId } = this.chat;
      const agents = this.getAgents(inboxId) || [];
      return [...agents];
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

    onClickAssignAgent(selectedItem) {
      if (
        this.currentChat.meta.assignee &&
        this.currentChat.meta.assignee.id === selectedItem.id
      ) {
        this.currentChat.meta.assignee = '';
      } else {
        this.currentChat.meta.assignee = selectedItem;
      }
      this.assignAgent(this.currentChat.meta.assignee);
    },
  },
};
</script>

<style lang="scss" scoped>
.conv-header {
  flex: 0 0 var(--space-jumbo);

  .text-truncate {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  ::v-deep.dropdown-wrap {
    width: 21rem;
    margin-bottom: 0;
  }
}
</style>
