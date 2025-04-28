<script>
import { mapGetters } from 'vuex';
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal.vue';
import LoadingState from './components/widgets/LoadingState.vue';
import NetworkNotification from './components/NetworkNotification.vue';
import UpdateBanner from './components/app/UpdateBanner.vue';
import PaymentPendingBanner from './components/app/PaymentPendingBanner.vue';
import PendingEmailVerificationBanner from './components/app/PendingEmailVerificationBanner.vue';
import FloatingCallWidget from './components/widgets/FloatingCallWidget.vue';
import vueActionCable from './helper/actionCable';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import WootSnackbarBox from './components/SnackbarContainer.vue';
import { setColorTheme } from './helper/themeHelper';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import { useAccount } from 'dashboard/composables/useAccount';
import { useFontSize } from 'dashboard/composables/useFontSize';
import { useAlert } from 'dashboard/composables';
import VoiceAPI from 'dashboard/api/channels/voice';
import {
  registerSubscription,
  verifyServiceWorkerExistence,
} from './helper/pushHelper';
import ReconnectService from 'dashboard/helper/ReconnectService';

export default {
  name: 'App',

  components: {
    AddAccountModal,
    FloatingCallWidget,
    LoadingState,
    NetworkNotification,
    UpdateBanner,
    PaymentPendingBanner,
    WootSnackbarBox,
    PendingEmailVerificationBanner,
  },
  setup() {
    const router = useRouter();
    const store = useStore();
    const { accountId } = useAccount();
    // Use the font size composable (it automatically sets up the watcher)
    const { currentFontSize } = useFontSize();

    return {
      router,
      store,
      currentAccountId: accountId,
      currentFontSize,
    };
  },
  data() {
    return {
      showAddAccountModal: false,
      latestChatwootVersion: null,
      reconnectService: null,
      showCallWidget: false, // Set to true for testing, false for production
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      isRTL: 'accounts/isRTL',
      currentUser: 'getCurrentUser',
      authUIFlags: 'getAuthUIFlags',
      accountUIFlags: 'accounts/getUIFlags',
      activeCall: 'calls/getActiveCall',
      hasActiveCall: 'calls/hasActiveCall',
    }),
    hasAccounts() {
      const { accounts = [] } = this.currentUser || {};
      return accounts.length > 0;
    },
    hideOnOnboardingView() {
      return !isOnOnboardingView(this.$route);
    },
  },

  watch: {
    currentUser() {
      if (!this.hasAccounts) {
        this.showAddAccountModal = true;
      }
    },
    currentAccountId: {
      immediate: true,
      handler() {
        if (this.currentAccountId) {
          this.initializeAccount();
        }
      },
    },
  },
  mounted() {
    // Make app instance available globally for debugging and cross-component access
    window.app = this;
    
    // Set up global force end call mechanism
    window.forceEndCall = () => this.forceEndCall();
    window.forceEndCallHandlers = [];
    
    this.initializeColorTheme();
    this.listenToThemeChanges();
    this.setLocale(window.chatwootConfig.selectedLocale);
  },
  unmounted() {
    if (this.reconnectService) {
      this.reconnectService.disconnect();
    }
  },
  methods: {
    initializeColorTheme() {
      setColorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches);
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = e => setColorTheme(e.matches);
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    handleCallEnded() {
      console.log('Call ended event received in App.vue');
      // Update our local state first for immediate UI update
      this.showCallWidget = false;
      // Then update the store
      this.$store.dispatch('calls/clearActiveCall');
    },
    
    // Public method that can be called from anywhere
    forceEndCall() {
      console.log('Force end call triggered in App.vue');
      
      // 1. Update UI immediately
      this.showCallWidget = false;
      
      // 2. Try to notify any other components
      if (window.forceEndCallHandlers) {
        window.forceEndCallHandlers.forEach(handler => {
          try {
            handler();
          } catch (e) {
            console.error('Error in end call handler:', e);
          }
        });
      }
      
      // 3. CRITICAL: Make API call to actually end the call on the server
      if (this.activeCall && this.activeCall.callSid) {
        const { callSid, conversationId } = this.activeCall;
        
        // Save references before clearing the store
        const savedCallSid = callSid;
        const savedConversationId = conversationId;
        
        // Now clear the store
        this.$store.dispatch('calls/clearActiveCall');
        
        // Make API call if we have a conversation ID
        if (savedConversationId) {
          console.log(
            'App.vue making API call to end call with SID:', 
            savedCallSid, 
            'for conversation:', 
            savedConversationId
          );
          
          // Make the API call to end the call on the server with both parameters
          VoiceAPI.endCall(savedCallSid, savedConversationId)
            .then(response => {
              console.log('Call ended successfully via API:', response);
              useAlert({ message: 'Call ended successfully', type: 'success' });
            })
            .catch(error => {
              console.error('Error ending call via API:', error);
              
              // If first attempt fails, try one more time with additional logging
              console.log('Retrying end call with more debugging...');
              setTimeout(() => {
                VoiceAPI.endCall(savedCallSid, savedConversationId)
                  .then(retryResponse => {
                    console.log('Retry successful:', retryResponse);
                  })
                  .catch(retryError => {
                    console.error('Retry also failed:', retryError);
                  });
              }, 1000);
              
              useAlert({ message: 'Call UI has been reset', type: 'info' });
            });
        } else {
          console.log('App.vue: Not making API call because conversation ID is missing');
          useAlert({ message: 'Call ended', type: 'success' });
        }
      } else {
        // No active call data, just clear the store
        this.$store.dispatch('calls/clearActiveCall');
      }
    },
    async initializeAccount() {
      await this.$store.dispatch('accounts/get');
      this.$store.dispatch('setActiveAccount', {
        accountId: this.currentAccountId,
      });
      const { locale, latest_chatwoot_version: latestChatwootVersion } =
        this.getAccount(this.currentAccountId);
      const { pubsub_token: pubsubToken } = this.currentUser || {};
      this.setLocale(locale);
      this.latestChatwootVersion = latestChatwootVersion;
      vueActionCable.init(this.store, pubsubToken);
      this.reconnectService = new ReconnectService(this.store, this.router);
      window.reconnectService = this.reconnectService;

      verifyServiceWorkerExistence(registration =>
        registration.pushManager.getSubscription().then(subscription => {
          if (subscription) {
            registerSubscription();
          }
        })
      );
    },
  },
};
</script>

<template>
  <div
    v-if="!authUIFlags.isFetching && !accountUIFlags.isFetchingItem"
    id="app"
    class="flex-grow-0 w-full h-full min-h-0 app-wrapper"
    :class="{ 'app-rtl--wrapper': isRTL }"
    :dir="isRTL ? 'rtl' : 'ltr'"
  >
    <UpdateBanner :latest-chatwoot-version="latestChatwootVersion" />
    <template v-if="currentAccountId">
      <PendingEmailVerificationBanner v-if="hideOnOnboardingView" />
      <PaymentPendingBanner v-if="hideOnOnboardingView" />
    </template>
    <router-view v-slot="{ Component }">
      <transition name="fade" mode="out-in">
        <component :is="Component" />
      </transition>
    </router-view>
    <AddAccountModal :show="showAddAccountModal" :has-accounts="hasAccounts" />
    <WootSnackbarBox />
    <NetworkNotification />
    <!-- Floating call widget that appears during active calls -->
    <FloatingCallWidget
      v-if="showCallWidget || (activeCall && activeCall.callSid)"
      :key="`call-${Date.now()}`"
      :call-sid="activeCall ? activeCall.callSid : 'test-call'"
      :inbox-name="activeCall ? (activeCall.inboxName || 'Primary') : 'Primary'"
      :conversation-id="activeCall ? activeCall.conversationId : null"
      @call-ended="handleCallEnded"
    />
  </div>
  <LoadingState v-else />
</template>

<style lang="scss">
@import './assets/scss/app';

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}

.multiselect__input {
  margin-bottom: 0px !important;
}
</style>

<style src="vue-multiselect/dist/vue-multiselect.css"></style>
