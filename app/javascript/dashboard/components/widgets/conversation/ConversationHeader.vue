<template>
  <div v-on-clickaway="onCloseDropdown" class="conv-header">
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
      <div class="dropdown-wrap">
        <button
          :v-model="currentChat.meta.assignee"
          class="button-input"
          @click="toggleDropdown"
        >
          <Thumbnail
            v-if="
              currentChat.meta.assignee &&
                currentChat.meta.assignee.name &&
                currentChat.meta.assignee &&
                currentChat.meta.assignee.id
            "
            :src="
              currentChat.meta.assignee && currentChat.meta.assignee.thumbnail
            "
            size="24px"
            :badge="chatMetadata.channel"
            :username="
              currentChat.meta.assignee && currentChat.meta.assignee.name
            "
          />
          <div v-if="!currentChat.meta.assignee" class="ion-headphone"></div>
          <div class="name-icon-wrap">
            <div class="name-wrap">
              <div v-if="!currentChat.meta.assignee" class="name select-agent">
                {{ 'Select Agent' }}
              </div>
              <div v-else class="name">
                {{
                  currentChat.meta.assignee && currentChat.meta.assignee.name
                }}
              </div>
            </div>
            <i v-if="showSearchDropdown" class="icon ion-chevron-up" />
            <i v-else class="icon ion-chevron-down" />
          </div>
        </button>
        <div
          :class="{ 'dropdown-pane--open': showSearchDropdown }"
          class="dropdown-pane"
        >
          <select-menu
            v-if="showSearchDropdown"
            :options="agentList"
            :value="currentChat.meta.assignee"
            @click="onClick"
          />
        </div>
      </div>
      <more-actions :conversation-id="currentChat.id" />
    </div>
  </div>
</template>
<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import SelectMenu from 'shared/components/ui/DropdownWithSearch';
import MoreActions from './MoreActions';
import Thumbnail from '../Thumbnail';

export default {
  components: {
    MoreActions,
    Thumbnail,
    SelectMenu,
  },

  mixins: [clickaway],

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
      getAgents: 'inboxMembers/getMembersByInbox',
      uiFlags: 'inboxMembers/getUIFlags',
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

    toggleDropdown() {
      this.showSearchDropdown = !this.showSearchDropdown;
    },

    onCloseDropdown() {
      this.showSearchDropdown = false;
    },

    onClick(selectedItem) {
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

  .dropdown-wrap {
    display: flex;
    position: relative;
    margin-right: var(--space-one);

    .button-input {
      display: flex;
      cursor: pointer;
      border: 1px solid lightgray;
      border-radius: var(--border-radius-normal);
      width: 21rem;
      justify-content: flex-end;
      background: white;
      font-size: var(--font-size-small);
      padding: 0.6rem;
    }

    .ion-headphone {
      padding: 0.5rem;
    }

    .name-icon-wrap {
      display: flex;
      justify-content: flex-start;
      padding: var(--space-smaller) var(--space-small);
      width: 17rem;

      .name-wrap {
        width: 14rem;
        padding: 0 var(--space-smaller);
        text-align: start;
        line-height: var(--space-normal);

        .select-agent {
          color: var(--b-600);
        }

        .name {
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
      }
    }

    .icon {
      display: flex;
      justify-content: space-between;
      padding: 0.1rem;
    }

    .dropdown-pane {
      top: 4rem;
      right: 0;
      max-width: 19rem;

      &::v-deep {
        .dropdown-menu__item .button {
          width: 18.6rem;
          text-overflow: ellipsis;
          overflow: hidden;
          white-space: nowrap;
          padding: var(--space-smaller) var(--space-small);
        }

        .name-icon-wrap {
          width: 16rem;
        }

        .name {
          width: 12rem;
        }
      }
    }
  }
}
</style>
