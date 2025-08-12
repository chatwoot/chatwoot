<script>
import { mapGetters } from 'vuex';
import AddAccountModal from './components/app/AddAccountModal.vue';
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
      showCallWidget: false, // Will be set to true when calls are active
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
      incomingCall: 'calls/getIncomingCall',
      hasIncomingCall: 'calls/hasIncomingCall',
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
    hasIncomingCall: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.showCallWidget = true;
        } else {
          this.showCallWidget = false;
        }
      },
    },
    hasActiveCall: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.showCallWidget = true;
        } else {
          this.showCallWidget = false;
        }
      },
    },
  },
  mounted() {
    this.initializeColorTheme();
    this.listenToThemeChanges();
    this.setLocale(window.chatwootConfig.selectedLocale);

    // Make app instance available globally for direct call widget updates
    window.app = this;
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
      this.showCallWidget = false;
      this.$store.dispatch('calls/clearActiveCall');
      this.$store.dispatch('calls/clearIncomingCall');

      // Clear the activeCallConversation state in all ContactInfo components
      this.$nextTick(() => {
        const clearContactInfoCallState = components => {
          if (!components) return;

          components.forEach(component => {
            if (
              component.$options &&
              component.$options.name === 'ContactInfo'
            ) {
              if (component.activeCallConversation) {
                component.activeCallConversation = null;
                component.$forceUpdate();
              }
            }
            if (component.$children && component.$children.length) {
              clearContactInfoCallState(component.$children);
            }
          });
        };

        clearContactInfoCallState(this.$children);
      });
    },
    handleCallJoined() {
      this.showCallWidget = true;
    },
    handleCallRejected() {
      this.showCallWidget = false;
      this.$store.dispatch('calls/clearIncomingCall');
    },
    forceEndCall() {
      this.showCallWidget = false;
      if (window.forceEndCallHandlers) {
        window.forceEndCallHandlers.forEach(handler => {
          try {
            handler();
          } catch (e) {
            // Optionally log error in production
          }
        });
      }
      if (this.activeCall && this.activeCall.callSid) {
        const { callSid, conversationId } = this.activeCall;
        const savedCallSid = callSid;
        const savedConversationId = conversationId;
        this.$store.dispatch('calls/clearActiveCall');
        if (savedConversationId) {
          VoiceAPI.endCall(savedCallSid, savedConversationId)
            .then(() => {
              useAlert({ message: 'Call ended successfully', type: 'success' });
            })
            .catch(() => {
              setTimeout(() => {
                VoiceAPI.endCall(savedCallSid, savedConversationId)
                  .then(() => {})
                  .catch(() => {});
              }, 1000);
              useAlert({ message: 'Call UI has been reset', type: 'info' });
            });
        } else {
          useAlert({ message: 'Call ended', type: 'success' });
        }
      } else {
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
    class="flex flex-col w-full h-screen min-h-0"
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
      v-if="showCallWidget || hasActiveCall || hasIncomingCall"
      :key="
        activeCall
          ? activeCall.callSid
          : incomingCall
            ? incomingCall.callSid
            : 'no-call'
      "
      :call-sid="
        activeCall
          ? activeCall.callSid
          : incomingCall
            ? incomingCall.callSid
            : ''
      "
      :inbox-name="
        activeCall
          ? activeCall.inboxName || 'Primary'
          : incomingCall
            ? incomingCall.inboxName
            : 'Primary'
      "
      :conversation-id="
        activeCall
          ? activeCall.conversationId
          : incomingCall
            ? incomingCall.conversationId
            : null
      "
      :contact-name="
        activeCall
          ? activeCall.contactName
          : incomingCall
            ? incomingCall.contactName
            : ''
      "
      :contact-id="
        activeCall
          ? activeCall.contactId
          : incomingCall
            ? incomingCall.contactId
            : null
      "
      :inbox-id="
        activeCall
          ? activeCall.inboxId
          : incomingCall
            ? incomingCall.inboxId
            : null
      "
      :inbox-avatar-url="
        activeCall
          ? activeCall.inboxAvatarUrl
          : incomingCall
            ? incomingCall.inboxAvatarUrl
            : ''
      "
      :inbox-phone-number="
        activeCall
          ? activeCall.inboxPhoneNumber
          : incomingCall
            ? incomingCall.inboxPhoneNumber
            : ''
      "
      :avatar-url="
        activeCall
          ? activeCall.avatarUrl
          : incomingCall
            ? incomingCall.avatarUrl
            : ''
      "
      :phone-number="
        activeCall
          ? activeCall.phoneNumber
          : incomingCall
            ? incomingCall.phoneNumber
            : ''
      "
      use-web-rtc
      @call-ended="handleCallEnded"
      @call-joined="handleCallJoined"
      @call-rejected="handleCallRejected"
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
