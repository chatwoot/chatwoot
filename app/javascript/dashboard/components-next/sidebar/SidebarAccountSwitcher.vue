<script setup>
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import ButtonNext from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';

const emit = defineEmits(['showCreateAccountModal']);

const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');
const [showDropdown, toggleDropdown] = useToggle(false);

const close = () => {
  if (showDropdown.value) {
    toggleDropdown(false);
  }
};

const onChangeAccount = newId => {
  const accountUrl = `/app/accounts/${newId}/dashboard`;
  window.location.href = accountUrl;
};

const emitNewAccount = () => {
  close();
  emit('showCreateAccountModal');
};
</script>

<template>
  <div class="relative z-20">
    <button
      id="sidebar-account-switcher"
      :data-account-id="accountId"
      aria-haspopup="listbox"
      aria-controls="account-options"
      class="flex items-center gap-2 justify-between w-full rounded-lg hover:bg-n-alpha-1 px-2"
      :class="{ 'bg-n-alpha-1': showDropdown }"
      @click="toggleDropdown()"
    >
      <span
        class="text-sm font-medium leading-5 text-n-slate-12 truncate"
        aria-live="polite"
      >
        {{ currentAccount.name }}
      </span>

      <span
        aria-hidden="true"
        class="i-lucide-chevron-down size-4 text-n-slate-10 flex-shrink-0"
      />
    </button>
    <div v-if="showDropdown" v-on-clickaway="close" class="absolute top-8 z-50">
      <div
        class="min-w-72 max-w-96 text-sm bg-n-solid-1 border border-n-weak rounded-xl shadow-sm py-4 px-2 flex flex-col gap-2"
      >
        <div
          class="px-4 leading-4 font-medium tracking-[0.2px] text-n-slate-10 text-xs"
        >
          {{ t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
        </div>
        <div class="px-1 gap-1 grid">
          <button
            v-for="account in currentUser.accounts"
            :id="`account-${account.id}`"
            :key="account.id"
            class="flex w-full hover:bg-n-alpha-1 space-x-4"
            @click="onChangeAccount(account.id)"
          >
            <div
              :for="account.name"
              class="text-left rtl:text-right flex gap-2 items-center"
            >
              <span
                class="text-n-slate-12 max-w-36 truncate min-w-0"
                :title="account.name"
              >
                {{ account.name }}
              </span>
              <div class="flex-shrink-0 w-px h-3 bg-n-strong" />
              <span
                class="text-n-slate-11 max-w-24 truncate capitalize"
                :title="account.name"
              >
                {{
                  account.custom_role_id
                    ? account.custom_role.name
                    : account.role
                }}
              </span>
            </div>
            <Icon
              v-show="account.id === accountId"
              icon="i-lucide-check"
              class="text-n-teal-11 size-5"
            />
          </button>
        </div>
        <div v-if="globalConfig.createNewAccountFromDashboard" class="px-2">
          <ButtonNext
            variant="secondary"
            class="w-full"
            size="sm"
            @click="emitNewAccount"
          >
            {{ t('CREATE_ACCOUNT.NEW_ACCOUNT') }}
          </ButtonNext>
        </div>
      </div>
    </div>
  </div>
</template>
