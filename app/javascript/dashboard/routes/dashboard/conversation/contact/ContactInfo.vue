<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
import ContactInfoRow from './ContactInfoRow.vue';
import inboxMixin from 'shared/mixins/inboxMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from './SocialIcons.vue';
import EditContact from './EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VoiceAPI from 'dashboard/api/channels/voice';
import CallManager from './CallManager.vue';

import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from '../../../../helper/routeHelpers';
import { emitter } from 'shared/helpers/mitt';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';

export default {
  components: {
    NextButton,
    ContactInfoRow,
    EditContact,
    Thumbnail,
    ComposeConversation,
    SocialIcons,
    ContactMergeModal,
    CallManager,
  },
  mixins: [inboxMixin],
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
      isCallLoading: false,
      activeCallConversation: null,
      isHoveringCallButton: false,
    };
  },
  computed: {
    ...mapGetters({ 
      uiFlags: 'contacts/getUIFlags',
      storeActiveCall: 'calls/getActiveCall',
      storeHasActiveCall: 'calls/hasActiveCall',
    }),
    // Check if there's an active call either in store or local component
    hasActiveCall() {
      return this.storeHasActiveCall || !!this.activeCallConversation;
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
    openComposeConversationModal(toggleFn) {
      toggleFn();
      // Flag to prevent triggering drag n drop,
      // When compose modal is active
      emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
    },
    closeComposeConversationModal() {
      // Flag to enable drag n drop,
      // When compose modal is closed
      emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
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
    async initiateVoiceCall() {
      if (!this.contact || !this.contact.id) return;

      this.isCallLoading = true;
      try {
        const response = await VoiceAPI.initiateCall(this.contact.id);
        const conversation = response.data;

        // First set local state for immediate UI update
        this.activeCallConversation = conversation;
        console.log('Call initiated, conversation data:', conversation);

        // Always create a call SID even if it's not in the response
        let callSid = conversation?.call_sid;

        // If not directly available, try to find it in messages
        if (!callSid) {
          const messages = conversation?.messages || [];
          const callMessage = messages.find(
            message =>
              message.message_type === 10 &&
              message.additional_attributes &&
              message.additional_attributes.call_sid
          );

          callSid = callMessage?.additional_attributes?.call_sid;
        }

        // If still not found, check conversation.additional_attributes
        if (!callSid && conversation?.additional_attributes) {
          callSid = conversation.additional_attributes.call_sid;
        }

        // If we don't have a call SID, log the error but continue
        // This will allow the UI to show something while we wait for the real call SID
        if (!callSid) {
          console.log(
            'No call SID found in response, waiting for server to assign one'
          );

          // We'll rely on WebSocket updates to get the real call SID when available
          // For now just set a placeholder for UI purposes
          callSid = 'pending';
        }

        // Log for debugging
        console.log('Voice call response:', conversation);
        console.log('Using call SID:', callSid);

        // Always set the global call state for the floating widget
        const inbox = conversation.inbox_id
          ? this.$store.getters['inboxes/getInbox'](conversation.inbox_id)
          : null;

        this.$store.dispatch('calls/setActiveCall', {
          callSid,
          inboxName: inbox?.name || 'Primary',
          conversationId: conversation.id,
          contactId: this.contact.id,
          inboxId: conversation.inbox_id,
        });

        // Set App's showCallWidget to true
        if (window.app && window.app.$data) {
          window.app.$data.showCallWidget = true;
        }

        // IMPORTANT: Redirect to the conversation view
        if (conversation.id) {
          const accountId = this.$route.params.accountId;
          const path = frontendURL(
            conversationUrl({
              accountId,
              id: conversation.id,
            })
          );
          console.log(`Redirecting to conversation path: ${path}`);
          this.$router.push({ path });
        }

        // After a brief delay, force update UI
        setTimeout(() => {
          this.$forceUpdate();
        }, 100);

        useAlert('Voice call initiated successfully');
      } catch (error) {
        // Error handled with useAlert
        useAlert('Failed to initiate voice call');
      } finally {
        this.isCallLoading = false;
      }
    },

    handleCallEnded() {
      // Immediately reset local state
      this.activeCallConversation = null;
      this.isCallLoading = false;
      
      // Clear global call state
      this.$store.dispatch('calls/clearActiveCall');
      
      // Force re-render the component to ensure button state updates
      this.$forceUpdate();
    },

    // Simplified emergency end call function
    forceEndActiveCall() {
      console.log('FORCE END ACTIVE CALL triggered from ContactInfo');

      // Important: Save a reference to the conversation before resetting it
      const savedConversation = this.activeCallConversation;

      // 1. Immediately update local state for immediate UI feedback
      this.activeCallConversation = null;
      this.isHoveringCallButton = false;
      this.$forceUpdate();

      // 2. Reset App global state
      if (window.app) {
        window.app.$data.showCallWidget = false;
      }

      // 3. Reset store state
      this.$store.dispatch('calls/clearActiveCall');

      // 4. Get the call SID from the saved conversation
      if (savedConversation) {
        // Try to find the call SID
        let callSid = null;

        // Check all possible locations
        if (savedConversation.call_sid) {
          callSid = savedConversation.call_sid;
        } else if (savedConversation.additional_attributes?.call_sid) {
          callSid = savedConversation.additional_attributes.call_sid;
        } else if (
          savedConversation.messages &&
          savedConversation.messages.length > 0
        ) {
          // Look in messages
          const callMessage = savedConversation.messages.find(
            message =>
              message.message_type === 10 &&
              message.additional_attributes?.call_sid
          );

          if (callMessage) {
            callSid = callMessage.additional_attributes.call_sid;
          }
        }

        console.log('ContactInfo: Found call SID for API call:', callSid);

        // 5. Make direct API call to end the call if we have a valid call SID
        if (callSid && callSid !== 'pending') {
          // Check if it's a valid Twilio call SID
          const isValidTwilioSid =
            callSid.startsWith('CA') || callSid.startsWith('TJ');

          if (isValidTwilioSid) {
            console.log(
              'ContactInfo: Making direct API call to end call with SID:',
              callSid
            );

            // Make API call with conversation ID
            VoiceAPI.endCall(callSid, savedConversation.id)
              .then(response => {
                console.log(
                  'ContactInfo: Call ended successfully via API:',
                  response
                );
              })
              .catch(error => {
                console.error('ContactInfo: Error ending call via API:', error);
              });
          } else {
            console.log(
              'ContactInfo: Invalid Twilio call SID format:',
              callSid
            );
          }
        } else if (callSid === 'pending') {
          console.log(
            'ContactInfo: Call was still in pending state, no API call needed'
          );
        } else {
          console.log('ContactInfo: No call SID available for API call');
        }
      }

      // 6. User feedback
      useAlert({ message: 'Call ended successfully', type: 'success' });
    },

    // Original more careful implementation
    async endActiveCall() {
      console.log('End active call triggered from ContactInfo component');

      // First, immediately update the UI for responsive feedback
      const savedActiveCall = this.activeCallConversation;
      this.activeCallConversation = null;
      this.$forceUpdate();

      // Reset app-level state
      if (window.app && window.app.$data) {
        window.app.$data.showCallWidget = false;
      }

      // Clear global state
      this.$store.dispatch('calls/clearActiveCall');

      // Always give user success feedback
      useAlert({ message: 'Call ended successfully', type: 'success' });

      // Then try the API call (after UI is updated)
      try {
        if (savedActiveCall) {
          // Try to find the call SID
          let callSid = null;

          // Check all possible locations
          if (savedActiveCall.call_sid) {
            callSid = savedActiveCall.call_sid;
          } else if (savedActiveCall.additional_attributes?.call_sid) {
            callSid = savedActiveCall.additional_attributes.call_sid;
          } else {
            // Look in messages
            const messages = savedActiveCall.messages || [];
            const callMessage = messages.find(
              message =>
                message.message_type === 10 &&
                message.additional_attributes?.call_sid
            );

            if (callMessage) {
              callSid = callMessage.additional_attributes.call_sid;
            }
          }

          console.log('Found call SID for API call:', callSid);

          // Make the API call if we have a valid call SID
          if (callSid && callSid !== 'pending') {
            // Check if it's a valid Twilio call SID
            const isValidTwilioSid =
              callSid.startsWith('CA') || callSid.startsWith('TJ');

            if (isValidTwilioSid) {
              try {
                console.log('Making API call to end call with SID:', callSid);
                await VoiceAPI.endCall(callSid, savedActiveCall.id);
                console.log('API call to end call succeeded');
              } catch (apiError) {
                console.error('API call to end call failed:', apiError);
                // We've already updated UI, so don't show error to user
              }
            } else {
              console.log('Invalid Twilio call SID format:', callSid);
            }
          } else if (callSid === 'pending') {
            console.log('Call was still in pending state, no API call needed');
          } else {
            console.log('No call SID available for API call');
          }
        }
      } catch (error) {
        console.error('Error in endActiveCall:', error);
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
    onCallButtonClick() {
      // If there's an active call in the store, just show widget
      if (this.storeHasActiveCall) {
        useAlert('Call already active, showing call widget', 'info');
        if (window.app && window.app.$data) {
          window.app.$data.showCallWidget = true;
        }
        return;
      }
      
      // Check if we have a stale local state
      if (this.activeCallConversation) {
        // Reset our local state
        this.activeCallConversation = null;
        this.$forceUpdate();
        
        // If store is clear, initiate a new call after state reset
        if (!this.storeHasActiveCall) {
          this.$nextTick(() => {
            this.initiateVoiceCall();
          });
        }
      } else {
        // No active call, proceed with initiating a new one
        this.initiateVoiceCall();
      }
    },
  },
};
</script>

<template>
  <div class="relative items-center w-full p-4">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <!-- Call Manager Component - Shows only when a call is active -->
      <CallManager
        v-if="activeCallConversation && contact && contact.id"
        :contact="contact"
        :conversation="activeCallConversation"
        @call-ended="handleCallEnded"
      />

      <div class="flex flex-row justify-between">
        <Thumbnail
          v-if="showAvatar"
          :src="contact.thumbnail"
          size="48px"
          :username="contact.name"
          :status="contact.availability_status"
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div v-if="showAvatar" class="flex items-center w-full min-w-0 gap-3">
          <h3
            class="flex-shrink max-w-full min-w-0 my-0 text-base capitalize break-words text-n-slate-12"
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
        <div class="flex flex-col items-start w-full gap-2">
          <ContactInfoRow
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="mail"
            emoji="✉️"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
          />
          <ContactInfoRow
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="call"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
          />
          <ContactInfoRow
            v-if="contact.identifier"
            :value="contact.identifier"
            icon="contact-identify"
            emoji="🪪"
            :title="$t('CONTACT_PANEL.IDENTIFIER')"
          />
          <ContactInfoRow
            :value="additionalAttributes.company_name"
            icon="building-bank"
            emoji="🏢"
            :title="$t('CONTACT_PANEL.COMPANY')"
          />
          <ContactInfoRow
            v-if="location || additionalAttributes.location"
            :value="location || additionalAttributes.location"
            icon="map"
            emoji="🌍"
            :title="$t('CONTACT_PANEL.LOCATION')"
          />
          <SocialIcons :social-profiles="socialProfiles" />
        </div>
      </div>
      <div class="flex items-center w-full mt-0.5 gap-2">
        <ComposeConversation
          :contact-id="String(contact.id)"
          is-modal
          @close="closeComposeConversationModal"
        >
          <template #trigger="{ toggle }">
            <NextButton
              v-tooltip.top-end="$t('CONTACT_PANEL.NEW_MESSAGE')"
              icon="i-ph-chat-circle-dots"
              slate
              faded
              sm
              @click="openComposeConversationModal(toggle)"
            />
          </template>
        </ComposeConversation>
        <NextButton
          v-if="contact.phone_number"
          v-tooltip.top-end="hasActiveCall ? 'Call already ongoing' : 'Call'"
          icon="i-ph-phone"
          slate
          faded
          sm
          :is-loading="!hasActiveCall && isCallLoading"
          :color="hasActiveCall ? 'teal' : undefined"
          @click.stop.prevent="onCallButtonClick"
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
