<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="() => $emit('close')"
      class="dropdown-pane dropdowm--top"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="showChangeAccountOption">
          <woot-button
            variant="clear"
            size="small"
            class=" change-accounts--button"
            @click="$emit('toggle-accounts')"
          >
            {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item v-if="globalConfig.chatwootInboxToken">
          <woot-button
            variant="clear"
            size="small"
            class=" change-accounts--button"
            @click="$emit('show-support-chat-window')"
          >
            Contact Support
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <router-link
            :to="`/app/accounts/${accountId}/profile/settings`"
            class="button clear small change-accounts--button"
          >
            {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
          </router-link>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            size="small"
            class=" change-accounts--button"
            @click="logout"
          >
            {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </transition>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import Auth from '../../../api/auth';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
  },
  mixins: [clickaway],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
    showChangeAccountOption() {
      if (this.globalConfig.createNewAccountFromDashboard) {
        return true;
      }
      return this.currentUser.accounts.length > 1;
    },
  },
  methods: {
    logout() {
      Auth.logout();

      if (this.globalConfig.chatwootInboxToken) {
        window.$chatwoot.reset();
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.dropdown-pane {
  right: 0;
}
</style>
