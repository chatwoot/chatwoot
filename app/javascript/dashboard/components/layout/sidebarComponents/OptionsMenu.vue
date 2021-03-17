<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="() => $emit('close')"
      class="dropdown-pane top"
    >
      <ul class="vertical dropdown menu">
        <li v-if="showChangeAccountOption">
          <woot-button
            class-names="change-accounts--button"
            variant="clear"
            @click="$emit('toggle-accounts')"
          >
            {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
          </woot-button>
        </li>
        <li v-if="globalConfig.chatwootInboxToken">
          <woot-button
            class-names="change-accounts--button"
            variant="clear"
            @click="$emit('show-support-chat-window')"
          >
            Contact Support
          </woot-button>
        </li>
        <li>
          <router-link :to="`/app/accounts/${accountId}/profile/settings`">
            {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
          </router-link>
        </li>
        <li>
          <a href="#" @click.prevent="logout">
            {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
          </a>
        </li>
      </ul>
    </div>
  </transition>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import Auth from '../../../api/auth';

export default {
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
