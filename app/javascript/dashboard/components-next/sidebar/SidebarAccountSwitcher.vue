<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import ButtonNext from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';
import Logo from 'next/icon/Logo.vue';

import {
  DropdownContainer,
  DropdownBody,
  DropdownSection,
  DropdownItem,
} from 'next/dropdown-menu/base';

defineProps({
  isCollapsed: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['showCreateAccountModal']);

const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');

const userAccounts = useMapGetter('getUserAccounts');

const showAccountSwitcher = computed(
  () => userAccounts.value.length > 1 && currentAccount.value.name
);

const sortedCurrentUserAccounts = computed(() => {
  return [...(currentUser.value.accounts || [])].sort((a, b) =>
    a.name.localeCompare(b.name)
  );
});

const onChangeAccount = newId => {
  const accountUrl = `/app/accounts/${newId}/dashboard`;
  window.location.href = accountUrl;
};

const emitNewAccount = () => {
  emit('showCreateAccountModal');
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle, isOpen }">
      <!-- Collapsed view: Logo trigger -->
      <button
        v-if="isCollapsed"
        class="grid flex-shrink-0 place-content-center p-2 rounded-lg cursor-pointer hover:bg-n-alpha-1"
        :class="{ 'bg-n-alpha-1': isOpen }"
        :title="currentAccount.name"
        @click="toggle"
      >
        <Logo class="size-9 object-contain" />
      </button>
      <!-- Expanded view: logo is branding; only the account row opens the switcher. -->
      <div
        v-else
        class="flex w-full min-w-0 flex-col items-center gap-1.5 text-center"
      >
        <Logo class="h-14 w-full max-w-[10rem] object-contain" />
        <button
          id="sidebar-account-switcher"
          :data-account-id="accountId"
          aria-haspopup="listbox"
          aria-controls="account-options"
          class="flex h-7 w-full min-w-0 items-center justify-center gap-1 rounded-lg px-2 text-center"
          :class="[
            isOpen && 'bg-n-alpha-1',
            showAccountSwitcher
              ? 'hover:bg-n-alpha-1 cursor-pointer'
              : 'cursor-default',
          ]"
          @click="() => showAccountSwitcher && toggle()"
        >
          <span
            class="min-w-0 truncate text-sm font-medium leading-5 text-n-slate-12"
            aria-live="polite"
          >
            {{ currentAccount.name }}
          </span>

          <span
            v-if="showAccountSwitcher"
            aria-hidden="true"
            class="i-lucide-chevron-down size-4 flex-shrink-0 text-n-slate-10"
          />
        </button>
      </div>
    </template>
    <DropdownBody
      v-if="showAccountSwitcher || isCollapsed"
      class="sidebar-branded-dropdown min-w-80 z-50"
    >
      <DropdownSection :title="t('SIDEBAR_ITEMS.SWITCH_ACCOUNT')">
        <DropdownItem
          v-for="account in sortedCurrentUserAccounts"
          :id="`account-${account.id}`"
          :key="account.id"
          class="cursor-pointer"
          @click="onChangeAccount(account.id)"
        >
          <template #label>
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
          </template>
        </DropdownItem>
      </DropdownSection>
      <DropdownItem v-if="globalConfig.createNewAccountFromDashboard">
        <ButtonNext
          color="slate"
          variant="faded"
          class="w-full"
          size="sm"
          @click="emitNewAccount"
        >
          {{ t('CREATE_ACCOUNT.NEW_ACCOUNT') }}
        </ButtonNext>
      </DropdownItem>
    </DropdownBody>
  </DropdownContainer>
</template>
