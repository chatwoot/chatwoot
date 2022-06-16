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
    <div
      v-for="account in currentUser.accounts"
      :key="account.id"
      class="account-selector"
    >
      <a :href="`/app/accounts/${account.id}/dashboard`">
        <fluent-icon
          v-if="account.id === accountId"
          class="selected--account"
          icon="checkmark-circle"
          type="solid"
          size="24"
        />
        <label :for="account.name" class="account--details">
          <div class="account--name">{{ account.name }}</div>
          <div class="account--role">{{ account.role }}</div>
        </label>
      </a>
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
};
</script>
