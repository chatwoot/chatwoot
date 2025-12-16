<template>
  <div class="relative items-center p-4 bg-white dark:bg-slate-900 w-full">
    <div class="text-left rtl:text-right flex flex-col gap-2 w-full">
      <div class="flex justify-between flex-row">
        <thumbnail
          v-if="showAvatar"
          :src="contact.thumbnail"
          size="56px"
          :username="displayName"
          :status="contact.availability_status"
        />
        <woot-button
          v-if="showCloseButton"
          :icon="closeIconName"
          class="clear secondary rtl:rotate-180"
          @click="onPanelToggle"
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div v-if="showAvatar" class="flex items-start gap-2 min-w-0 w-full">
          <h3
            class="flex-shrink min-w-0 text-base text-slate-800 dark:text-slate-100 capitalize my-0 max-w-full break-words"
          >
            {{ displayName }}
          </h3>
          <div class="flex flex-row items-center gap-1">
            <fluent-icon
              v-if="contact.created_at"
              v-tooltip.left="
                `${$t('CONTACT_PANEL.CREATED_AT_LABEL')} ${dynamicTime(
                  contact.created_at
                )}`
              "
              icon="info"
              size="14"
              class="mt-0.5"
            />
            <a
              :href="contactProfileLink"
              class="text-base"
              target="_blank"
              rel="noopener nofollow noreferrer"
            >
              <woot-button
                size="tiny"
                icon="open"
                variant="clear"
                color-scheme="secondary"
              />
            </a>
          </div>
        </div>

        <p v-if="additionalAttributes.description" class="break-words mb-0.5">
          {{ additionalAttributes.description }}
        </p>
        <div
          v-if="shouldShowContactDetails"
          class="flex flex-col gap-2 items-start w-full"
        >
          <contact-info-row
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="mail"
            emoji="✉️"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
          />
          <contact-info-row
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="call"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
          />
          <contact-info-row
            v-if="contact.identifier"
            :value="contact.identifier"
            icon="contact-identify"
            emoji="🪪"
            :title="$t('CONTACT_PANEL.IDENTIFIER')"
          />
          <contact-info-row
            :value="additionalAttributes.company_name"
            icon="building-bank"
            emoji="🏢"
            :title="$t('CONTACT_PANEL.COMPANY')"
          />
          <contact-info-row
            v-if="location || additionalAttributes.location"
            :value="location || additionalAttributes.location"
            icon="map"
            emoji="🌍"
            :title="$t('CONTACT_PANEL.LOCATION')"
          />
          <social-icons :social-profiles="socialProfiles" />

          <!-- Contact Assignee Section (only show if feature enabled or admin) -->
          <div
            v-if="shouldShowContactAssignee"
            class="flex flex-col gap-1 w-full mt-2 pt-2 border-t border-slate-100 dark:border-slate-700"
          >
            <div class="flex items-center justify-between">
              <span
                class="text-xs font-medium text-slate-600 dark:text-slate-400"
              >
                {{ $t('CONTACT_PANEL.ASSIGNEE') }}
              </span>
            </div>
            <multiselect-dropdown
              :options="agentsListForAssignment"
              :selected-item="assignedContactAgent"
              :multiselector-title="$t('CONTACT_PANEL.ASSIGNEE')"
              :multiselector-placeholder="
                $t('CONTACT_PANEL.ASSIGNEE_PLACEHOLDER')
              "
              :no-search-result="
                $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
              "
              :input-placeholder="
                $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
              "
              :disabled="isContactAssignmentDisabled"
              @click="onClickAssignContactAgent"
            />
          </div>
        </div>
      </div>
      <div class="flex items-center w-full mt-0.5 gap-2">
        <woot-button
          v-if="shouldShowCallButton"
          v-tooltip="'Call this user'"
          title="Call user"
          :custom-icon="callingIcon"
          size="small"
          class="no-shrink-button"
          @click="callUser"
        >
          Call
        </woot-button>
        <woot-button
          v-tooltip="$t('CONTACT_PANEL.NEW_MESSAGE')"
          title="$t('CONTACT_PANEL.NEW_MESSAGE')"
          icon="chat"
          size="small"
          @click="toggleConversationModal"
        />
        <woot-button
          v-tooltip="$t('EDIT_CONTACT.BUTTON_LABEL')"
          title="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="edit"
          variant="smooth"
          size="small"
          @click="toggleEditModal"
        />
        <woot-button
          v-tooltip="$t('CONTACT_PANEL.MERGE_CONTACT')"
          title="$t('CONTACT_PANEL.MERGE_CONTACT')"
          icon="merge"
          variant="smooth"
          size="small"
          color-scheme="secondary"
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <woot-button
          v-show="contact.phone_number"
          v-tooltip="'Unsubscribe Contact'"
          title="'Unsubscribe Contact'"
          class="unsub-contact"
          variant="smooth"
          size="small"
          @click="toggleUnsubModal"
        >
          Unsubscribe
        </woot-button>
        <woot-button
          v-if="isAdmin"
          v-tooltip="$t('DELETE_CONTACT.BUTTON_LABEL')"
          title="$t('DELETE_CONTACT.BUTTON_LABEL')"
          icon="delete"
          variant="smooth"
          size="small"
          color-scheme="alert"
          :disabled="uiFlags.isDeleting"
          @click="toggleDeleteModal"
        />
      </div>
      <edit-contact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
      />
      <new-conversation
        v-if="contact.id"
        :show="showConversationModal"
        :contact="contact"
        @cancel="toggleConversationModal"
      />
      <contact-merge-modal
        v-if="showMergeModal"
        :primary-contact="contact"
        :show="showMergeModal"
        @close="toggleMergeModal"
      />
      <unsub-modal
        v-if="showUnsubModal"
        :contact="contact"
        :show="showUnsubModal"
        @cancel="toggleUnsubModal"
      />
    </div>
    <woot-delete-modal
      v-if="showDeleteModal"
      :show.sync="showDeleteModal"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="$t('DELETE_CONTACT.CONFIRM.TITLE')"
      :message="$t('DELETE_CONTACT.CONFIRM.MESSAGE')"
      :message-value="confirmDeleteMessage"
      :confirm-text="$t('DELETE_CONTACT.CONFIRM.YES')"
      :reject-text="$t('DELETE_CONTACT.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import timeMixin from 'dashboard/mixins/time';
import ContactInfoRow from './ContactInfoRow.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from './SocialIcons.vue';
import * as Sentry from '@sentry/vue';
import EditContact from './EditContact.vue';
import NewConversation from './NewConversation.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import UnsubModal from './UnsubModal';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import alertMixin from 'shared/mixins/alertMixin';
import adminMixin from '../../../../mixins/isAdmin';
import { mapGetters } from 'vuex';
import { getCountryFlag } from 'dashboard/helper/flag';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from '../../../../helper/routeHelpers';
import Calling from '../../../../api/callling';
import callingIcon from '../../../../assets/images/calling.svg';
import { getContactDisplayName } from 'shared/helpers/contactHelper';

export default {
  components: {
    ContactInfoRow,
    EditContact,
    Thumbnail,
    SocialIcons,
    NewConversation,
    ContactMergeModal,
    UnsubModal,
    MultiselectDropdown,
  },
  mixins: [alertMixin, adminMixin, timeMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    channelType: {
      type: String,
      default: '',
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
    showCloseButton: {
      type: Boolean,
      default: true,
    },
    closeIconName: {
      type: String,
      default: 'chevron-right',
    },
  },
  data() {
    return {
      showEditModal: false,
      showConversationModal: false,
      showMergeModal: false,
      showUnsubModal: false,
      showDeleteModal: false,
      callingIcon,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      accountId: 'getCurrentAccountId',
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      getAccount: 'accounts/getAccount',
      agentsList: 'agents/getAgents',
    }),
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
    shouldShowCallButton() {
      if (
        this.currentAccount?.custom_attributes?.call_config?.enabled &&
        this.contact.phone_number
      )
        return true;
      return false;
    },
    contactProfileLink() {
      return `/app/accounts/${this.$route.params.accountId}/contacts/${this.contact.id}`;
    },
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },

    location() {
      const {
        country = '',
        city = '',
        country_code: countryCode,
      } = this.additionalAttributes;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (!cityAndCountry) {
        return '';
      }
      return this.findCountryFlag(countryCode, cityAndCountry);
    },
    socialProfiles() {
      const {
        social_profiles: socialProfiles,
        screen_name: twitterScreenName,
      } = this.additionalAttributes;

      return { twitter: twitterScreenName, ...(socialProfiles || {}) };
    },
    // Delete Modal
    confirmDeleteMessage() {
      return ` ${this.contact.name}?`;
    },
    displayName() {
      return getContactDisplayName(this.contact);
    },
    shouldShowContactDetails() {
      const contactMasking =
        this.currentAccount?.custom_attributes?.contact_masking;
      if (this.currentUser.role === 'administrator' && contactMasking?.admin)
        return false;
      if (this.currentUser.role === 'agent' && contactMasking?.agent)
        return false;
      return true;
    },
    shouldShowContactAssignee() {
      const isFeatureEnabled =
        this.currentAccount?.custom_attributes?.enable_contact_assignment ===
        true;

      if (!isFeatureEnabled) return false;

      // Admins see assignee dropdown for all contacts
      if (this.isAdmin) return true;

      // Agents see assignee dropdown ONLY for unassigned contacts (to claim them)
      return !this.contact.assignee_id;
    },
    assignedContactAgent() {
      if (!this.contact.assignee_id) {
        return null;
      }
      // Find the agent from the agents list
      return this.agentsList.find(
        agent => agent.id === this.contact.assignee_id
      );
    },
    agentsListForAssignment() {
      // Admins can assign to any agent
      if (this.isAdmin) return this.agentsList;

      // Agents can only assign to themselves
      return this.agentsList.filter(agent => agent.id === this.currentUser.id);
    },
    isContactAssignmentDisabled() {
      // Admins can always modify
      if (this.isAdmin) return false;

      // Agents cannot modify if contact is already assigned
      return !!this.contact.assignee_id;
    },
  },
  mounted() {
    // Load agents if not already loaded
    if (this.agentsList.length === 0) {
      this.$store.dispatch('agents/get');
    }
  },
  methods: {
    toggleUnsubModal() {
      this.showUnsubModal = !this.showUnsubModal;
    },
    toggleMergeModal() {
      this.showMergeModal = !this.showMergeModal;
    },
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    onPanelToggle() {
      this.$emit('toggle-panel');
    },
    toggleConversationModal() {
      this.showConversationModal = !this.showConversationModal;
      this.$emitter.emit(
        BUS_EVENTS.NEW_CONVERSATION_MODAL,
        this.showConversationModal
      );
    },
    toggleDeleteModal() {
      this.showDeleteModal = !this.showDeleteModal;
    },
    confirmDeletion() {
      this.deleteContact(this.contact);
      this.closeDelete();
    },
    async callUser() {
      if (!this.currentUser?.custom_attributes?.phone_number) {
        this.showAlert(
          'Please update your phone number in profile settings to make a call'
        );
        return;
      }
      try {
        const response = await Calling.startCall({
          from: this.currentUser.custom_attributes.phone_number,
          to: this.contact.phone_number,
          accountId: this.accountId,
          contactId: this.contact.id,
          accessToken: this.currentUser.access_token,
        });
        if (response?.data?.success) {
          this.showAlert('Call initiated');
        } else {
          this.showAlert(
            response?.data?.response ??
              'Something went wrong in initiating the call.'
          );
        }
      } catch (error) {
        Sentry.setContext('CallingInitiation', {
          from: this.currentUser.custom_attributes.phone_number,
          to: this.contact.phone_number,
          accountId: this.accountId,
          contactId: this.contact.id,
          accessToken: this.currentUser.access_token,
        });
        Sentry.captureException(error);
        Sentry.captureMessage('Error in initiating the call');
        this.showAlert('Something went in intiating the call.');
      }
    },
    closeDelete() {
      this.showDeleteModal = false;
      this.showConversationModal = false;
      this.showEditModal = false;
    },
    findCountryFlag(countryCode, cityAndCountry) {
      try {
        const countryFlag = countryCode ? getCountryFlag(countryCode) : '🌎';
        return `${cityAndCountry} ${countryFlag}`;
      } catch (error) {
        return '';
      }
    },
    async deleteContact({ id }) {
      try {
        await this.$store.dispatch('contacts/delete', id);
        this.$emit('panel-close');
        this.showAlert(this.$t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));

        if (isAConversationRoute(this.$route.name)) {
          this.$router.push({
            name: getConversationDashboardRoute(this.$route.name),
          });
        } else if (isAInboxViewRoute(this.$route.name)) {
          this.$router.push({
            name: 'inbox_view',
          });
        } else if (this.$route.name !== 'contacts_dashboard') {
          this.$router.push({
            name: 'contacts_dashboard',
          });
        }
      } catch (error) {
        this.showAlert(
          error.message
            ? error.message
            : this.$t('DELETE_CONTACT.API.ERROR_MESSAGE')
        );
      }
    },
    openMergeModal() {
      this.toggleMergeModal();
    },
    async onClickAssignContactAgent(selectedAgent) {
      try {
        const assigneeId = selectedAgent ? selectedAgent.id : null;
        await this.$store.dispatch('contacts/reassignContact', {
          contactId: this.contact.id,
          assigneeId,
        });
        this.showAlert(this.$t('CONTACT_PANEL.ASSIGNEE_UPDATED'));
      } catch (error) {
        this.showAlert(this.$t('CONTACT_PANEL.ASSIGNEE_UPDATE_FAILED'));
      }
    },
  },
};
</script>

<style scoped lang="scss">
.contact--profile {
  position: relative;
  align-items: flex-start;
  padding: var(--space-normal);
}

.contact--details {
  margin-top: var(--space-small);
  width: 100%;
}

.contact--info {
  text-align: left;
}

.contact-info--header {
  display: flex;
  justify-content: space-between;
  flex-direction: row;
}

.contact--name-wrap {
  display: flex;
  align-items: center;
  margin-bottom: var(--space-small);
}

.contact--name {
  text-transform: capitalize;
  white-space: normal;
  margin: 0 var(--space-smaller) 0 var(--space-smaller);

  a {
    color: var(--color-body);
  }
}

.contact--metadata {
  margin-bottom: var(--space-slab);
}

.contact-actions {
  margin-top: var(--space-small);
}

.contact-actions {
  display: flex;
  align-items: center;
  width: 100%;

  .new-message,
  .edit-contact,
  .merge-contact,
  .delete-contact,
  .unsub-contact {
    margin-right: var(--space-small);
  }
}
.merge-summary--card {
  padding: var(--space-normal);
}

.contact--bio {
  word-wrap: break-word;
}

.button--contact-menu {
  position: absolute;
  right: var(--space-normal);
  top: 0;
}

.no-shrink-button {
  flex-shrink: 0;
  white-space: nowrap;
  min-width: max-content;
}
</style>
