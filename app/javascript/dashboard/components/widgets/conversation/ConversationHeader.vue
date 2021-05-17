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
        <button
          class="user--profile__button clear button small"
          @click="$emit('contact-panel-toggle')"
        >
          {{
            `${
              isContactPanelOpen
                ? $t('CONVERSATION.HEADER.CLOSE')
                : $t('CONVERSATION.HEADER.OPEN')
            } ${$t('CONVERSATION.HEADER.DETAILS')}`
          }}
        </button>
      </div>
    </div>
    <div
      class="header-actions-wrap"
      :class="{ 'has-open-sidebar': isContactPanelOpen }"
    >
      <div class="multiselect-box multiselect-wrap--small">
        <i class="icon ion-headphone" />
        <multiselect
          v-model="currentChat.meta.assignee"
          :loading="uiFlags.isFetching"
          :allow-empty="true"
          deselect-label=""
          :options="agentList"
          :placeholder="$t('CONVERSATION.ASSIGNMENT.SELECT_AGENT')"
          select-label=""
          label="name"
          selected-label
          track-by="id"
          @select="assignAgent"
          @remove="removeAgent"
        >
          <template slot="option" slot-scope="props">
            <div class="option__desc">
              <availability-status-badge
                :status="props.option.availability_status"
              />
              <span class="option__title">{{ props.option.name }}</span>
            </div>
          </template>
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
import AvailabilityStatusBadge from '../conversation/AvailabilityStatusBadge';

export default {
  components: {
    MoreActions,
    Thumbnail,
    AvailabilityStatusBadge,
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
      return [
        {
          confirmed: true,
          name: 'None',
          id: 0,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...agents,
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

.conv-header {
  flex: 0 0 var(--space-jumbo);
}

.option__desc {
  display: flex;
  align-items: center;
}

.option__desc {
  &::v-deep .status-badge {
    margin-right: var(--space-small);
    min-width: 0;
    flex-shrink: 0;
  }
}
</style>
