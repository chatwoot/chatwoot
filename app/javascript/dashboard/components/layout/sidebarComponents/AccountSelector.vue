<template>
  <woot-modal
    :show="showAccountModal"
    :on-close="() => $emit('close-account-modal')"
    class="account-selector--modal"
  >
    <woot-modal-header
      :header-title="$t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS')"
      :header-content="$t('SIDEBAR_ITEMS.SELECTOR_SUBTITLE')"
    />
    <div>
      <div
        v-for="account in currentUser.accounts"
        :key="account.id"
        class="account-selector"
      >
        <button
          class="button expanded clear link"
          @click="onChangeAccount(account.id)"
        >
          <span class="button__content">
            <label :for="account.name" class="account--details">
              <div class="account--name">{{ account.name }}</div>
              <div class="account--role">{{ account.role }}</div>
            </label>
          </span>
          <fluent-icon
            v-show="account.id === accountId"
            class="selected--account"
            icon="checkmark-circle"
            type="solid"
            size="24"
          />
        </button>
      </div>
    </div>

    <div
      v-if="globalConfig.createNewAccountFromDashboard"
      class="modal-footer delete-item"
    >
      <button
        class="button success large expanded nice"
        @click="$emit('show-create-account-modal')"
      >
        {{ $t('CREATE_ACCOUNT.NEW_ACCOUNT') }}
      </button>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    showAccountModal: {
      type: Boolean,
      default: true,
    },
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
    }),
  },
  methods: {
    async onChangeAccount(accountId) {
      const accountUrl = `/app/accounts/${accountId}/dashboard`;
      window.location.href = accountUrl;
      await this.$store.dispatch('setActiveAccount', {
        accountId: accountId,
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.account-selector {
  button {
    padding: var(--space-one) 0;
    .account--details {
      padding-left: var(--space-normal);
      text-align: left;
      .account--name {
        cursor: pointer;
        font-size: var(--font-size-medium);
        font-weight: var(--font-weight-medium);
        line-height: 1;
      }

      .account--role {
        cursor: pointer;
        font-size: var(--font-size-mini);
        text-transform: capitalize;
      }
    }
  }
}
</style>
