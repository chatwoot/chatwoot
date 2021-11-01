<template>
  <div class="medium-3 bg-white contact--panel">
    <span class="close-button" @click="onPanelToggle">
      <i class="ion-chevron-right" />
    </span>
    <contact-info :contact="contact" :channel-type="channelType" />
    <div class="conversation--actions">
      <accordion-item
        :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS')"
        :is-open="isContactSidebarItemOpen('is_conv_actions_open')"
        @click="value => toggleSidebarUIState('is_conv_actions_open', value)"
      >
        <div>
          <div class="multiselect-wrap--small">
            <contact-details-item
              compact
              :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
            >
              <template v-slot:button>
                <woot-button
                  v-if="showSelfAssign"
                  icon="ion-arrow-right-c"
                  variant="link"
                  size="small"
                  @click="onSelfAssign"
                >
                  {{ $t('CONVERSATION_SIDEBAR.SELF_ASSIGN') }}
                </woot-button>
              </template>
            </contact-details-item>
            <multiselect-dropdown
              :options="agentsList"
              :selected-item="assignedAgent"
              :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
              :multiselector-placeholder="
                $t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')
              "
              :no-search-result="
                $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
              "
              :input-placeholder="
                $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
              "
              @click="onClickAssignAgent"
            />
          </div>
          <div class="multiselect-wrap--small">
            <contact-details-item
              compact
              :title="$t('CONVERSATION_SIDEBAR.TEAM_LABEL')"
            />
            <multiselect-dropdown
              :options="teamsList"
              :selected-item="assignedTeam"
              :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
              :multiselector-placeholder="
                $t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')
              "
              :no-search-result="
                $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')
              "
              :input-placeholder="
                $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
              "
              @click="onClickAssignTeam"
            />
          </div>
          <contact-details-item
            compact
            :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
          />
          <conversation-labels :conversation-id="conversationId" />
        </div>
      </accordion-item>
    </div>
    <accordion-item
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
      :is-open="isContactSidebarItemOpen('is_conv_details_open')"
      compact
      @click="value => toggleSidebarUIState('is_conv_details_open', value)"
    >
      <conversation-info
        :conversation-attributes="conversationAdditionalAttributes"
        :contact-attributes="contactAdditionalAttributes"
      >
      </conversation-info>
    </accordion-item>

    <accordion-item
      v-if="hasContactAttributes"
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
      :is-open="isContactSidebarItemOpen('is_contact_attributes_open')"
      @click="
        value => toggleSidebarUIState('is_contact_attributes_open', value)
      "
    >
      <contact-custom-attributes
        :custom-attributes="contact.custom_attributes"
      />
    </accordion-item>
    <accordion-item
      v-if="contact.id"
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.PREVIOUS_CONVERSATION')"
      :is-open="isContactSidebarItemOpen('is_previous_conv_open')"
      @click="value => toggleSidebarUIState('is_previous_conv_open', value)"
    >
      <contact-conversations
        :contact-id="contact.id"
        :conversation-id="conversationId"
      />
    </accordion-item>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import agentMixin from '../../../mixins/agentMixin';

import AccordionItem from 'dashboard/components/Accordion/AccordionItem';
import ContactConversations from './ContactConversations.vue';
import ContactCustomAttributes from './ContactCustomAttributes';
import ContactDetailsItem from './ContactDetailsItem.vue';
import ContactInfo from './contact/ContactInfo';
import ConversationInfo from './ConversationInfo';
import ConversationLabels from './labels/LabelBox.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactCustomAttributes,
    ContactDetailsItem,
    ContactInfo,
    ConversationInfo,
    ConversationLabels,
    MultiselectDropdown,
  },
  mixins: [alertMixin, agentMixin, uiSettingsMixin],
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    inboxId: {
      type: Number,
      default: undefined,
    },
    onToggle: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      teams: 'teams/getTeams',
      currentUser: 'getCurrentUser',
      uiFlags: 'inboxAssignableAgents/getUIFlags',
    }),
    conversationAdditionalAttributes() {
      return this.currentConversationMetaData.additional_attributes || {};
    },
    channelType() {
      return this.currentChat.meta?.channel;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
    contactAdditionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    contactId() {
      return this.currentChat.meta?.sender?.id;
    },
    currentConversationMetaData() {
      return this.$store.getters[
        'conversationMetadata/getConversationMetadata'
      ](this.conversationId);
    },
    hasContactAttributes() {
      const { custom_attributes: customAttributes } = this.contact;
      return customAttributes && Object.keys(customAttributes).length;
    },
    teamsList() {
      if (this.assignedTeam) {
        return [
          {
            id: 0,
            name: 'None',
          },
          ...this.teams,
        ];
      }
      return this.teams;
    },
    assignedAgent: {
      get() {
        return this.currentChat.meta.assignee;
      },
      set(agent) {
        const agentId = agent ? agent.id : 0;
        this.$store.dispatch('setCurrentChatAssignee', agent);
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId,
          })
          .then(() => {
            this.showAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
          });
      },
    },
    assignedTeam: {
      get() {
        return this.currentChat.meta.team;
      },
      set(team) {
        const teamId = team ? team.id : 0;
        this.$store.dispatch('setCurrentChatTeam', team);
        this.$store
          .dispatch('assignTeam', {
            conversationId: this.currentChat.id,
            teamId,
          })
          .then(() => {
            this.showAlert(this.$t('CONVERSATION.CHANGE_TEAM'));
          });
      },
    },
    showSelfAssign() {
      if (!this.assignedAgent) {
        return true;
      }
      if (this.assignedAgent.id !== this.currentUser.id) {
        return true;
      }
      return false;
    },
  },
  watch: {
    conversationId(newConversationId, prevConversationId) {
      if (newConversationId && newConversationId !== prevConversationId) {
        this.getContactDetails();
      }
    },
    contactId() {
      this.getContactDetails();
    },
  },
  mounted() {
    this.getContactDetails();
    this.$store.dispatch('attributes/get', 0);
  },
  methods: {
    onPanelToggle() {
      this.onToggle();
    },
    getContactDetails() {
      if (this.contactId) {
        this.$store.dispatch('contacts/show', { id: this.contactId });
      }
    },
    getAttributesByModel() {
      if (this.contactId) {
        this.$store.dispatch('contacts/show', { id: this.contactId });
      }
    },
    openTranscriptModal() {
      this.showTranscriptModal = true;
    },
    onSelfAssign() {
      const {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        avatar_url,
      } = this.currentUser;
      const selfAssign = {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        thumbnail: avatar_url,
      };
      this.assignedAgent = selfAssign;
    },
    onClickAssignAgent(selectedItem) {
      if (this.assignedAgent && this.assignedAgent.id === selectedItem.id) {
        this.assignedAgent = null;
      } else {
        this.assignedAgent = selectedItem;
      }
    },

    onClickAssignTeam(selectedItemTeam) {
      if (this.assignedTeam && this.assignedTeam.id === selectedItemTeam.id) {
        this.assignedTeam = null;
      } else {
        this.assignedTeam = selectedItemTeam;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.contact--panel {
  background: white;
  border-left: 1px solid var(--color-border);
  font-size: $font-size-small;
  overflow-y: auto;
  overflow: auto;
  position: relative;

  i {
    margin-right: $space-smaller;
  }
}

::v-deep {
  .contact--profile {
    padding-bottom: var(--space-slab);
    border-bottom: 1px solid var(--color-border);
  }
  .conversation--actions .multiselect-wrap--small {
    .multiselect {
      padding-left: var(--space-medium);
      box-sizing: border-box;
    }
    .multiselect__element {
      span {
        width: 100%;
      }
    }
  }
}

.close-button {
  position: absolute;
  right: $space-two;
  top: $space-slab + $space-two;
  font-size: $font-size-default;
  color: $color-heading;
  z-index: 9989;
}

.conversation--labels {
  padding: $space-medium;

  .icon {
    margin-right: $space-micro;
    font-size: $font-size-micro;
    color: #fff;
  }

  .label {
    color: #fff;
    padding: 0.2rem;
  }
}

.contact--mute {
  color: $alert-color;
  display: block;
  text-align: left;
}

.contact--actions {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.contact-info {
  margin-top: var(--space-two);
}
</style>
