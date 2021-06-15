<template>
  <div class="medium-3 bg-white contact--panel">
    <span class="close-button" @click="onPanelToggle">
      <i class="ion-chevron-right" />
    </span>
    <contact-info :contact="contact" :channel-type="channelType" />
    <div class="conversation--actions">
      <div class="multiselect-wrap--small">
        <div class="self-assign">
          <contact-details-item
            :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
            icon="ion-headphone"
            emoji="🧑‍🚀"
          >
          </contact-details-item>
          <woot-button
            v-if="showSelfAssign"
            icon="ion-arrow-right-c"
            variant="link"
            size="small"
            class-names="button-content"
            @click="onSelfAssign"
          >
            {{ $t('CONVERSATION_SIDEBAR.SELF_ASSIGN') }}
          </woot-button>
        </div>
        <agent-dropdown
          :assigned-agent="assignedAgent"
          :agents-list="agentsList"
          @click="onClickShowAgent"
        />
      </div>
      <div class="multiselect-wrap--small">
        <contact-details-item
          :title="$t('CONVERSATION_SIDEBAR.TEAM_LABEL')"
          icon="ion-ios-people"
          emoji="🎢"
        />
        <teams-dropdown
          :assigned-team="assignedTeam"
          :teams-list="teamsList"
          @click="onClickShowTeam"
        />
      </div>
    </div>
    <conversation-labels :conversation-id="conversationId" />
    <div v-if="browser.browser_name" class="conversation--details">
      <contact-details-item
        v-if="location"
        :title="$t('CONTACT_FORM.FORM.LOCATION.LABEL')"
        :value="location"
        icon="ion-map"
        emoji="📍"
      />
      <contact-details-item
        v-if="ipAddress"
        :title="$t('CONTACT_PANEL.IP_ADDRESS')"
        :value="ipAddress"
        icon="ion-android-locate"
        emoji="🧭"
      />
      <contact-details-item
        v-if="browser.browser_name"
        :title="$t('CONTACT_PANEL.BROWSER')"
        :value="browserName"
        icon="ion-ios-world-outline"
        emoji="🌐"
      />
      <contact-details-item
        v-if="browser.platform_name"
        :title="$t('CONTACT_PANEL.OS')"
        :value="platformName"
        icon="ion-laptop"
        emoji="💻"
      />
      <contact-details-item
        v-if="referer"
        :title="$t('CONTACT_PANEL.INITIATED_FROM')"
        :value="referer"
        icon="ion-link"
        emoji="🔗"
      >
        <a :href="referer" rel="noopener noreferrer nofollow" target="_blank">
          {{ referer }}
        </a>
      </contact-details-item>
      <contact-details-item
        v-if="initiatedAt"
        :title="$t('CONTACT_PANEL.INITIATED_AT')"
        :value="initiatedAt.timestamp"
        icon="ion-clock"
        emoji="🕰"
      />
    </div>
    <contact-custom-attributes
      v-if="hasContactAttributes"
      :custom-attributes="contact.custom_attributes"
    />
    <contact-conversations
      v-if="contact.id"
      :contact-id="contact.id"
      :conversation-id="conversationId"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { mixin as clickaway } from 'vue-clickaway';

import ContactConversations from './ContactConversations.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';
import ContactInfo from './contact/ContactInfo';
import ConversationLabels from './labels/LabelBox.vue';
import ContactCustomAttributes from './ContactCustomAttributes';
import flag from 'country-code-emoji';
import AgentDropdown from 'shared/components/ui/AgentDropdown.vue';
import TeamsDropdown from 'shared/components/ui/TeamsDropdown.vue';

export default {
  components: {
    ContactCustomAttributes,
    ContactConversations,
    ContactDetailsItem,
    ContactInfo,
    ConversationLabels,
    AgentDropdown,
    TeamsDropdown,
  },
  mixins: [alertMixin, clickaway],
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
  data() {
    return {
      currentChatAssignee: null,
      showSearchDropdown: false,
      showSearchDropdownTeam: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      teams: 'teams/getTeams',
      currentUser: 'getCurrentUser',
      getAgents: 'inboxAssignableAgents/getAssignableAgents',
      uiFlags: 'inboxAssignableAgents/getUIFlags',
    }),
    currentConversationMetaData() {
      return this.$store.getters[
        'conversationMetadata/getConversationMetadata'
      ](this.conversationId);
    },
    additionalAttributes() {
      return this.currentConversationMetaData.additional_attributes || {};
    },
    hasContactAttributes() {
      const { custom_attributes: customAttributes } = this.contact;
      return customAttributes && Object.keys(customAttributes).length;
    },
    browser() {
      return this.additionalAttributes.browser || {};
    },
    referer() {
      return this.additionalAttributes.referer;
    },
    initiatedAt() {
      return this.additionalAttributes.initiated_at;
    },
    browserName() {
      return `${this.browser.browser_name || ''} ${this.browser
        .browser_version || ''}`;
    },
    contactAdditionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    ipAddress() {
      const { created_at_ip: createdAtIp } = this.contactAdditionalAttributes;
      return createdAtIp;
    },
    location() {
      const {
        country = '',
        city = '',
        country_code: countryCode,
      } = this.contactAdditionalAttributes;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (!cityAndCountry) {
        return '';
      }
      const countryFlag = countryCode ? flag(countryCode) : '🌎';
      return `${cityAndCountry} ${countryFlag}`;
    },
    platformName() {
      const {
        platform_name: platformName,
        platform_version: platformVersion,
      } = this.browser;
      return `${platformName || ''} ${platformVersion || ''}`;
    },
    channelType() {
      return this.currentChat.meta?.channel;
    },
    contactId() {
      return this.currentChat.meta?.sender?.id;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
    agentsList() {
      return [{ id: 0, name: 'None' }, ...this.getAgents(this.inboxId)];
    },
    teamsList() {
      return [{ id: 0, name: 'None' }, ...this.teams];
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
    openTranscriptModal() {
      this.showTranscriptModal = true;
    },
    toggleDropdown() {
      this.showSearchDropdown = !this.showSearchDropdown;
    },
    toggleDropdownTeam() {
      this.showSearchDropdownTeam = !this.showSearchDropdownTeam;
    },
    onClickShowAgent(selectedItem) {
      if (this.assignedAgent && this.assignedAgent.id === selectedItem.id) {
        this.assignedAgent = '';
      } else {
        this.assignedAgent = selectedItem;
      }
      return this.assignedAgent;
    },
    onClickShowTeam(selectedItemTeam) {
      if (this.assignedTeam && this.assignedTeam.id === selectedItemTeam.id) {
        this.assignedTeam = '';
      } else {
        this.assignedTeam = selectedItemTeam;
      }
      return this.assignedTeam;
    },
    onCloseDropdown() {
      this.showSearchDropdown = false;
    },
    onCloseDropdownTeam() {
      this.showSearchDropdownTeam = false;
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
        thumbnail,
      } = this.currentUser;
      const selfAssign = {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        thumbnail,
      };
      this.assignedAgent = selfAssign;
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

  &::v-deep {
    .conv-details--item {
      padding-bottom: var(--space-small);
    }
  }

  i {
    margin-right: $space-smaller;
  }

  .conversation--actions {
    align-items: flex-start;
    padding: var(--space-normal) var(--space-normal);
    margin: 0;
  }
}

::v-deep {
  .contact--profile {
    padding-bottom: var(--space-slab);
    margin-bottom: var(--space-normal);
    border-bottom: 1px solid var(--color-border-light);
  }
  .multiselect-wrap--small {
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
  right: $space-normal;
  top: $space-slab;
  font-size: $font-size-default;
  color: $color-heading;
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
    padding: var(--space-micro);
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

.conversation--actions {
  margin-bottom: var(--space-normal);
}

.multiselect__label {
  margin-bottom: var(--space-smaller);
}

.self-assign {
  display: flex;
  justify-content: space-between;
  .button-content {
    margin-bottom: var(--space-one);
   }
 }

.option__desc {
  display: flex;
  align-items: center;

  &::v-deep .status-badge {
    margin-right: var(--space-small);
    min-width: 0;
    flex-shrink: 0;

  }
}
</style>
