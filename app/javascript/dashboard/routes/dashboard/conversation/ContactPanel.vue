<template>
  <div class="medium-3 bg-white contact--panel">
    <span class="close-button" @click="onPanelToggle">
      <i class="ion-chevron-right" />
    </span>
    <contact-info :contact="contact" :channel-type="channelType" />
    <div class="conversation--actions">
      <h4 class="sub-block-title">
        {{ $t('CONVERSATION_SIDEBAR.DETAILS_TITLE') }}
      </h4>
      <div class="multiselect-wrap--small">
        <label class="multiselect__label">
          {{ $t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL') }}
        </label>
        <multiselect
          v-model="assignedAgent"
          :options="agentsList"
          label="name"
          track-by="id"
          deselect-label=""
          select-label=""
          selected-label=""
          :placeholder="$t('CONVERSATION_SIDEBAR.SELECT.PLACEHOLDER')"
          :allow-empty="true"
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
      <div class="multiselect-wrap--small">
        <label class="multiselect__label">
          {{ $t('CONVERSATION_SIDEBAR.TEAM_LABEL') }}
        </label>
        <multiselect
          v-model="assignedTeam"
          :options="teamsList"
          label="name"
          track-by="id"
          deselect-label=""
          select-label=""
          selected-label=""
          :placeholder="$t('CONVERSATION_SIDEBAR.SELECT.PLACEHOLDER')"
          :allow-empty="true"
        >
          <span slot="noResult">{{ $t('AGENT_MGMT.SEARCH.NO_RESULTS') }}</span>
        </multiselect>
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

import ContactConversations from './ContactConversations.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';
import ContactInfo from './contact/ContactInfo';
import ConversationLabels from './labels/LabelBox.vue';
import ContactCustomAttributes from './ContactCustomAttributes';
import AvailabilityStatusBadge from 'dashboard/components/widgets/conversation/AvailabilityStatusBadge.vue';

import flag from 'country-code-emoji';

export default {
  components: {
    ContactCustomAttributes,
    ContactConversations,
    ContactDetailsItem,
    ContactInfo,
    ConversationLabels,
    AvailabilityStatusBadge,
  },
  mixins: [alertMixin],
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
  padding: $space-one;

  i {
    margin-right: $space-smaller;
  }
}

.multiselect-wrap--small {
  &::v-deep .multiselect__element {
    span {
      width: 100%;
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

.conversation--details {
  padding: 0 var(--space-slab);
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

.sub-block-title {
  margin-bottom: var(--space-small);
}

.conversation--actions {
  padding: 0 var(--space-normal) var(--space-smaller);
}

.multiselect__label {
  margin-bottom: var(--space-smaller);
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
