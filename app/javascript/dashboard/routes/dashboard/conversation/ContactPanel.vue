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
        <div v-on-clickaway="onCloseDropdown" class="dropdown-wrap">
          <button
            :v-model="assignedAgent"
            class="button-input"
            @click="toggleDropdown"
          >
            <Thumbnail
              v-if="
                assignedAgent &&
                  assignedAgent.name &&
                  assignedAgent &&
                  assignedAgent.id
              "
              :src="assignedAgent && assignedAgent.thumbnail"
              size="24px"
              :badge="assignedAgent && assignedAgent.channel"
              :username="assignedAgent && assignedAgent.name"
            />
            <div class="name-icon-wrap">
              <div v-if="!assignedAgent" class="name select-agent">
                {{ $t('AGENT_MGMT.SELECTOR.PLACEHOLDER') }}
              </div>
              <div v-else class="name">
                {{ assignedAgent && assignedAgent.name }}
              </div>
              <i v-if="showSearchDropdown" class="icon ion-close-round" />
              <i v-else class="icon ion-chevron-down" />
            </div>
          </button>
          <div
            :class="{ 'dropdown-pane--open': showSearchDropdown }"
            class="dropdown-pane"
          >
            <h4 class="text-block-title">
              {{ $t('AGENT_MGMT.SELECTOR.TITLE.AGENT') }}
            </h4>
            <select-menu
              v-if="showSearchDropdown"
              :options="agentsList"
              :value="assignedAgent"
              @click="onClick"
            />
          </div>
        </div>
      </div>
      <div class="multiselect-wrap--small">
        <label class="multiselect__label">
          {{ $t('CONVERSATION_SIDEBAR.TEAM_LABEL') }}
        </label>

        <div v-on-clickaway="onCloseDropdownTeam" class="dropdown-wrap">
          <button
            :v-model="assignedTeam"
            class="button-input"
            @click="toggleDropdownTeam"
          >
            <Thumbnail
              v-if="
                assignedTeam &&
                  assignedTeam.name &&
                  assignedTeam &&
                  assignedTeam.id
              "
              :src="assignedTeam && assignedTeam.thumbnail"
              size="24px"
              :badge="assignedTeam.channel"
              :username="assignedTeam && assignedTeam.name"
            />
            <div class="name-icon-wrap">
              <div v-if="!assignedTeam" class="name select-agent">
                {{ $t('AGENT_MGMT.SELECTOR.PLACEHOLDER') }}
              </div>
              <div v-else class="name">
                {{ assignedTeam && assignedTeam.name }}
              </div>

              <i v-if="showSearchDropdownTeam" class="icon ion-close-round" />
              <i v-else class="icon ion-chevron-down" />
            </div>
          </button>
          <div
            :class="{ 'dropdown-pane--open': showSearchDropdownTeam }"
            class="dropdown-pane"
          >
            <h4 class="text-block-title">
              {{ $t('AGENT_MGMT.SELECTOR.TITLE.TEAM') }}
            </h4>
            <select-menu
              v-if="showSearchDropdownTeam"
              :options="teamsList"
              :value="assignedTeam"
              @click="onClickTeam"
            />
          </div>
        </div>
      </div>
    </div>
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
    <conversation-labels :conversation-id="conversationId" />
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
import SelectMenu from 'shared/components/ui/DropdownWithSearch';
import Thumbnail from 'components/widgets/Thumbnail.vue';

export default {
  components: {
    ContactCustomAttributes,
    ContactConversations,
    ContactDetailsItem,
    ContactInfo,
    ConversationLabels,
    Thumbnail,
    SelectMenu,
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
      getAgents: 'inboxMembers/getMembersByInbox',
      uiFlags: 'inboxMembers/getUIFlags',
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
    toggleDropdown() {
      this.showSearchDropdown = !this.showSearchDropdown;
    },
    toggleDropdownTeam() {
      this.showSearchDropdownTeam = !this.showSearchDropdownTeam;
    },
    onClick(selectedItem) {
      if (this.assignedAgent && this.assignedAgent.id === selectedItem.id) {
        this.assignedAgent = '';
      } else {
        this.assignedAgent = selectedItem;
      }
      return this.assignedAgent;
    },
    onClickTeam(selectedItemTeam) {
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

.sub-block-title {
  margin-bottom: var(--space-small);
}

.conversation--actions {
  padding: 0 var(--space-normal) var(--space-small);
}

.multiselect__label {
  margin-bottom: var(--space-smaller);
}
.conversation--actions {
  .dropdown-wrap {
    display: flex;
    position: relative;
    width: 100%;
    margin-right: var(--space-one);

    .button-input {
      display: flex;
      width: 100%;
      cursor: pointer;
      justify-content: flex-start;
      background: white;
      font-size: var(--font-size-small);
      padding: var(--space-small) 0 var(--space-one) 0;
    }

    &::v-deep .user-thumbnail-box {
      margin-right: var(--space-one);
    }

    .name-icon-wrap {
      display: flex;
      justify-content: space-between;
      width: 100%;
      padding: var(--space-smaller) 0;
      line-height: var(--space-normal);

      .select-agent {
        color: var(--b-600);
      }

      .name {
        display: flex;
        justify-content: space-between;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .icon {
        display: flex;
        justify-content: space-between;
        padding: 0.1rem;
      }
    }

    .dropdown-pane {
      box-sizing: border-box;
      top: 4rem;
      right: 0;
      position: absolute;
      width: 100%;

      &::v-deep {
        .dropdown-menu__item .button {
          width: 100%;
          text-overflow: ellipsis;
          overflow: hidden;
          white-space: nowrap;
          padding: var(--space-smaller) var(--space-small);

          .name-icon-wrap {
            width: 100%;
          }

          .name {
            width: 100%;
          }
        }
      }
    }
  }
}
</style>
