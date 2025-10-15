<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
// import ContactInfoRow from './ContactInfoRow.vue'; // Removed for poker UI
import Avatar from 'next/avatar/Avatar.vue';
// import SocialIcons from './SocialIcons.vue'; // Removed for poker UI
import EditContact from './EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from '../../../../helper/routeHelpers';

export default {
  components: {
    NextButton,
    // ContactInfoRow, // Removed for poker UI
    EditContact,
    Avatar,
    // SocialIcons, // Removed for poker UI
    ContactMergeModal,
    VoiceCallButton,
    MultiselectDropdown,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['panelClose'],
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      showEditModal: false,
      showMergeModal: false,
      showDeleteModal: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      agents: 'agents/getAgents',
      currentChat: 'getSelectedChat',
    }),
    contactProfileLink() {
      return `/app/accounts/${this.$route.params.accountId}/contacts/${this.contact.id}`;
    },
    assignedAgent() {
      return this.currentChat?.meta?.assignee || null;
    },
    agentsList() {
      return [
        {
          id: null,
          name: this.$t('CONVERSATION.UNASSIGNED'),
          thumbnail: '',
        },
        ...this.agents,
      ];
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
        social_telegram_user_name: telegramUsername,
      } = this.additionalAttributes;
      return {
        twitter: twitterScreenName,
        telegram: telegramUsername,
        ...(socialProfiles || {}),
      };
    },
    // Delete Modal
    confirmDeleteMessage() {
      return ` ${this.contact.name}?`;
    },
    playerStatus() {
      return this.additionalAttributes.player_status || null;
    },
    playerStatusLabel() {
      const statusMap = {
        beginner: this.$t('CONTACT_FORM.PLAYER_STATUS.BEGINNER'),
        amateur: this.$t('CONTACT_FORM.PLAYER_STATUS.AMATEUR'),
        regular: this.$t('CONTACT_FORM.PLAYER_STATUS.REGULAR'),
        advanced: this.$t('CONTACT_FORM.PLAYER_STATUS.ADVANCED'),
        professional: this.$t('CONTACT_FORM.PLAYER_STATUS.PROFESSIONAL'),
        high_roller: this.$t('CONTACT_FORM.PLAYER_STATUS.HIGH_ROLLER'),
      };
      return statusMap[this.playerStatus] || this.playerStatus;
    },
  },
  watch: {
    'contact.id': {
      handler(id) {
        this.$store.dispatch('contacts/fetchContactableInbox', id);
      },
      immediate: true,
    },
  },
  methods: {
    dynamicTime,
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    copyContactName() {
      navigator.clipboard.writeText(this.contact.name).then(() => {
        useAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
      });
    },
    onAssignAgent(agent) {
      if (!this.currentChat?.id) return;

      const agentId = agent?.id || 0;
      this.$store.dispatch('setCurrentChatAssignee', agent);
      this.$store
        .dispatch('assignAgent', {
          conversationId: this.currentChat.id,
          agentId,
        })
        .then(() => {
          useAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
        });
    },
    toggleDeleteModal() {
      this.showDeleteModal = !this.showDeleteModal;
    },
    confirmDeletion() {
      this.deleteContact(this.contact);
      this.closeDelete();
    },
    closeDelete() {
      this.showDeleteModal = false;
      this.showEditModal = false;
    },
    findCountryFlag(countryCode, cityAndCountry) {
      try {
        if (!countryCode) {
          return `${cityAndCountry} 🌎`;
        }

        const code = countryCode?.toLowerCase();
        return `${cityAndCountry} <span class="fi fi-${code} size-3.5"></span>`;
      } catch (error) {
        return '';
      }
    },
    async deleteContact({ id }) {
      try {
        await this.$store.dispatch('contacts/delete', id);
        this.$emit('panelClose');
        useAlert(this.$t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));

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
        useAlert(
          error.message
            ? error.message
            : this.$t('DELETE_CONTACT.API.ERROR_MESSAGE')
        );
      }
    },
    closeMergeModal() {
      this.showMergeModal = false;
    },
    openMergeModal() {
      this.showMergeModal = true;
    },
  },
};
</script>

<template>
  <!-- Block 4: Simplified contact info panel for operators -->
  <div class="relative items-center w-full p-4">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <div class="flex flex-row justify-between">
        <Avatar
          v-if="showAvatar"
          :src="contact.thumbnail"
          :name="contact.name"
          :status="contact.availability_status"
          :size="48"
          hide-offline-status
          rounded-full
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div v-if="showAvatar" class="flex items-center w-full min-w-0 gap-3">
          <h3
            v-tooltip.left="$t('CONTACT_PANEL.COPY_CONTACT_NAME')"
            class="flex-shrink max-w-full min-w-0 my-0 text-base capitalize break-words text-n-slate-12 cursor-pointer hover:text-n-slate-11"
            @click="copyContactName"
          >
            {{ contact.name }}
          </h3>
          <div class="flex flex-row items-center gap-2">
            <span
              v-if="contact.created_at"
              v-tooltip.left="
                `${$t('CONTACT_PANEL.CREATED_AT_LABEL')} ${dynamicTime(
                  contact.created_at
                )}`
              "
              class="i-lucide-info text-sm text-n-slate-10"
            />
            <button
              v-tooltip.left="$t('CONTACT_PANEL.COPY_CONTACT_NAME')"
              class="i-lucide-copy text-sm text-n-slate-10 hover:text-n-slate-12 cursor-pointer"
              @click="copyContactName"
            />
            <a
              :href="contactProfileLink"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="leading-3"
            >
              <span class="i-lucide-external-link text-sm text-n-slate-10" />
            </a>
          </div>
        </div>

        <p v-if="additionalAttributes.description" class="break-words mb-0.5">
          {{ additionalAttributes.description }}
        </p>

        <!-- Player status display -->
        <div
          v-if="playerStatus"
          class="flex items-center text-n-slate-11 text-xs"
        >
          <span class="font-medium">
            {{ playerStatusLabel }}
          </span>
        </div>

        <!-- Block 4: Agent selector for operators -->
        <div v-if="currentChat" class="mt-4 w-full">
          <p class="text-xs font-medium text-n-slate-11 mb-2">
            {{ $t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL') }}
          </p>
          <MultiselectDropdown
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
            @select="onAssignAgent"
          />
        </div>
      </div>
      <div class="flex items-center w-full mt-0.5 gap-2">
        <VoiceCallButton
          :phone="contact.phone_number"
          icon="i-ri-phone-fill"
          size="sm"
          :tooltip-label="$t('CONTACT_PANEL.CALL')"
          slate
          faded
        />
        <NextButton
          v-tooltip.top-end="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="i-ph-pencil-simple"
          slate
          faded
          sm
          @click="toggleEditModal"
        />
        <NextButton
          v-tooltip.top-end="$t('CONTACT_PANEL.MERGE_CONTACT')"
          icon="i-ph-arrows-merge"
          slate
          faded
          sm
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <NextButton
          v-if="isAdmin"
          v-tooltip.top-end="$t('DELETE_CONTACT.BUTTON_LABEL')"
          icon="i-ph-trash"
          slate
          faded
          sm
          ruby
          :disabled="uiFlags.isDeleting"
          @click="toggleDeleteModal"
        />
      </div>
      <EditContact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
      />
      <ContactMergeModal
        v-if="showMergeModal"
        :primary-contact="contact"
        :show="showMergeModal"
        @close="closeMergeModal"
      />
    </div>
    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
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
