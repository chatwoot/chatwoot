<template>
  <div class="row app-wrapper">
    <sidebar
      :route="currentRoute"
      :sidebar-class-name="sidebarClassName"
      @open-notification-panel="openNotificationPanel"
      @toggle-account-modal="toggleAccountModal"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
      @show-add-label-popup="showAddLabelPopup"
    />
    <section class="app-content columns" :class="contentClassName">
      <router-view />
      <command-bar />
      <ShowPlans
        :is-subscription-valid="!isSubscriptionValid"
        :available-product-prices="availableProductPrices"
        :plan-id="planId"
        :plan-name="planName"
        :response-for-plans="responseForPlans"
        @hideModal="hideModal"
      />
      <account-selector
        :show-account-modal="showAccountModal"
        @close-account-modal="toggleAccountModal"
        @show-create-account-modal="openCreateAccountModal"
      />
      <add-account-modal
        :show="showCreateAccountModal"
        @close-account-create-modal="closeCreateAccountModal"
      />
      <woot-key-shortcut-modal
        v-if="showShortcutModal"
        @close="closeKeyShortcutModal"
        @clickaway="closeKeyShortcutModal"
      />
      <notification-panel
        v-if="isNotificationPanel"
        @close="closeNotificationPanel"
      />
      <woot-modal :show.sync="showAddLabelModal" :on-close="hideAddLabelPopup">
        <add-label-modal @close="hideAddLabelPopup" />
      </woot-modal>
    </section>
  </div>
</template>

<script>
import Sidebar from '../../components/layout/Sidebar';
import CommandBar from './commands/commandbar.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import Cookies from 'js-cookie';
import ShowPlans from './ShowPlans';
import { mapGetters } from 'vuex';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal';
import AddAccountModal from 'dashboard/components/layout/sidebarComponents/AddAccountModal';
import AccountSelector from 'dashboard/components/layout/sidebarComponents/AccountSelector';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel';

export default {
  components: {
    Sidebar,
    CommandBar,
    ShowPlans,
    WootKeyShortcutModal,
    AddAccountModal,
    AccountSelector,
    AddLabelModal,
    NotificationPanel,
  },
  data() {
    return {
      isSidebarOpen: false,
      isOnDesktop: true,
      isSubscriptionValid: true,
      availableProductPrices: [],
      planId: 0,
      planName: 0,
      responseForPlans: false,
      showAccountModal: false,
      showCreateAccountModal: false,
      showAddLabelModal: false,
      showShortcutModal: false,
      isNotificationPanel: false,
    };
  },
  computed: {
    currentRoute() {
      return ' ';
    },
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
    }),
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
    sidebarClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas is-open';
      }
      return 'off-canvas is-transition-push is-closed';
    },
    contentClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas-content is-open-left has-transition-push';
      }
      return 'off-canvas-content has-transition-push';
    },
  },
  mounted() {
    window.addEventListener('resize', this.handleResize);
    this.handleResize();
    bus.$on(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
    this.initializeAccountBillingSubscription();
    bus.$on(BUS_EVENTS.SHOW_PLAN_MODAL, this.showModal);
  },
  beforeDestroy() {
    bus.$off(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
    window.removeEventListener('resize', this.handleResize);
  },
  methods: {
    handleResize() {
      if (window.innerWidth > 1200) {
        this.isOnDesktop = true;
      } else {
        this.isOnDesktop = false;
      }
    },
    async initializeAccountBillingSubscription() {
      this.responseForPlans = false;
      try {
        await this.$store.dispatch('accounts/getBillingSubscription');
        const response = await this.getAccount(this.$route.params.accountId);
        if (response) {
          const { available_product_prices, plan_id, plan_name } = response;
          this.availableProductPrices = available_product_prices;
          this.planId = plan_id;
          this.planName = plan_name;
          this.responseForPlans = true;
        }
        this.responseForPlans = true;
      } catch (error) {
        this.responseForPlans = true;
        console.log(error);
      }
    },
    hideModal() {
      Cookies.remove('subscription');
      this.isSubscriptionValid = true;
    },
    showModal() {
      this.isSubscriptionValid = false;
    },
    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },
    openCreateAccountModal() {
      this.showAccountModal = false;
      this.showCreateAccountModal = true;
    },
    closeCreateAccountModal() {
      this.showCreateAccountModal = false;
    },
    toggleAccountModal() {
      this.showAccountModal = !this.showAccountModal;
    },
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
    showAddLabelPopup() {
      this.showAddLabelModal = true;
    },
    hideAddLabelPopup() {
      this.showAddLabelModal = false;
    },
    openNotificationPanel() {
      this.isNotificationPanel = true;
    },
    closeNotificationPanel() {
      this.isNotificationPanel = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.off-canvas-content.is-open-left {
  transform: translateX(20rem);
}
</style>