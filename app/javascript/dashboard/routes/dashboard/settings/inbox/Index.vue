<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Avatar from 'next/avatar/Avatar.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import SettingsLayout from '../SettingsLayout.vue';
import {
  useMapGetter,
  useStoreGetters,
  useStore,
} from 'dashboard/composables/store';
import ChannelName from './components/ChannelName.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const showDeletePopup = ref(false);
const selectedInbox = ref({});

const inboxes = useMapGetter('inboxes/getInboxes');
const helpURL = computed(() => getHelpUrlForFeature('inboxes'));

const inboxesList = computed(() => {
  return inboxes.value?.slice().sort((a, b) => a.name.localeCompare(b.name));
});

const uiFlags = computed(() => getters['inboxes/getUIFlags'].value);

const deleteConfirmText = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.YES')} ${selectedInbox.value.name}`
);

const deleteRejectText = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.NO')} ${selectedInbox.value.name}`
);

const confirmDeleteMessage = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.MESSAGE')} ${selectedInbox.value.name}?`
);
const confirmPlaceHolderText = computed(
  () =>
    `${t('INBOX_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
      inboxName: selectedInbox.value.name,
    })}`
);

const channelIconAccent = channelType => {
  const map = {
    'Channel::Api': 'text-secondary',
    'Channel::Email': 'text-tertiary',
    'Channel::WebWidget': 'text-secondary',
    'Channel::FacebookPage': 'text-on-tertiary-container',
    'Channel::TwitterProfile': 'text-on-surface-variant',
    'Channel::TwilioSms': 'text-on-surface-variant',
    'Channel::Whatsapp': 'text-[#25D366]',
    'Channel::Sms': 'text-on-surface',
    'Channel::Telegram': 'text-on-tertiary-container',
    'Channel::Line': 'text-secondary-fixed',
    'Channel::Instagram': 'text-on-tertiary-container',
    'Channel::Tiktok': 'text-on-surface-variant',
    'Channel::Voice': 'text-tertiary',
  };
  return map[channelType] || 'text-secondary';
};

const deleteInbox = async ({ id }) => {
  try {
    await store.dispatch('inboxes/delete', id);
    useAlert(t('INBOX_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.DELETE.API.ERROR_MESSAGE'));
  }
};
const closeDelete = () => {
  showDeletePopup.value = false;
  selectedInbox.value = {};
};

const confirmDeletion = () => {
  deleteInbox(selectedInbox.value);
  closeDelete();
};
const openDelete = inbox => {
  showDeletePopup.value = true;
  selectedInbox.value = inbox;
};

const inboxStatusDisconnected = inbox => !!inbox.reauthorization_required;
</script>

<template>
  <SettingsLayout
    :no-records-found="!inboxesList.length"
    :no-records-message="$t('INBOX_MGMT.LIST.404')"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INBOX_MGMT.LIST.LOADING')"
  >
    <template #header>
      <div
        class="flex flex-col gap-6 pb-2 md:flex-row md:items-end md:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <span
            class="mb-0 block text-[11px] font-semibold uppercase tracking-widest text-secondary"
          >
            {{ $t('INBOX_MGMT.PAGE_EYEBROW') }}
          </span>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ $t('INBOX_MGMT.HEADER') }}
          </h2>
          <p class="mb-0 max-w-xl text-base text-on-primary-container">
            {{ $t('INBOX_MGMT.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ $t('INBOX_MGMT.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <router-link
          v-if="isAdmin"
          :to="{ name: 'settings_inbox_new' }"
          class="block w-full shrink-0 md:inline-flex md:w-auto"
        >
          <Button
            solid
            teal
            lg
            icon="i-lucide-plus"
            :label="$t('SETTINGS.INBOXES.NEW_INBOX')"
            class="w-full rounded-lg font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] md:w-auto"
          />
        </router-link>
      </div>
    </template>
    <template #body>
      <div class="mx-auto max-w-5xl space-y-3">
        <div
          v-for="inbox in inboxesList"
          :key="inbox.id"
          class="group flex items-center justify-between gap-4 rounded-xl border border-transparent bg-surface-container-low p-4 transition-all duration-300 hover:border-outline-variant/20 hover:bg-surface-container-high/50"
        >
          <div class="flex min-w-0 flex-1 items-center gap-5">
            <div
              class="flex size-12 shrink-0 items-center justify-center rounded-lg border border-outline-variant/10 bg-surface transition-transform duration-300 group-hover:scale-105"
              :class="channelIconAccent(inbox.channel_type)"
            >
              <div
                v-if="inbox.avatar_url"
                class="flex size-full items-center justify-center p-1.5"
              >
                <Avatar
                  :src="inbox.avatar_url"
                  :name="inbox.name"
                  :size="36"
                  rounded-full
                />
              </div>
              <ChannelIcon v-else class="size-7" :inbox="inbox" />
            </div>
            <div class="min-w-0">
              <h3
                class="mb-0 text-base font-semibold capitalize text-on-surface"
              >
                {{ inbox.name }}
              </h3>
              <div
                class="mt-0.5 flex flex-wrap items-center gap-2 text-on-primary-container"
              >
                <span class="text-xs">
                  <ChannelName
                    :channel-type="inbox.channel_type"
                    :medium="inbox.medium"
                  />
                </span>
                <span
                  class="size-1 shrink-0 rounded-full bg-outline-variant/60"
                  aria-hidden="true"
                />
                <span
                  class="text-[10px] font-bold uppercase tracking-tighter"
                  :class="
                    inboxStatusDisconnected(inbox)
                      ? 'text-error'
                      : 'text-secondary-fixed-dim'
                  "
                >
                  {{
                    inboxStatusDisconnected(inbox)
                      ? $t('INBOX_MGMT.LIST.STATUS_DISCONNECTED')
                      : $t('INBOX_MGMT.LIST.STATUS_ACTIVE')
                  }}
                </span>
              </div>
            </div>
          </div>
          <div
            class="flex shrink-0 items-center gap-1 opacity-40 transition-opacity duration-300 group-hover:opacity-100"
          >
            <router-link
              v-if="isAdmin"
              v-slot="{ href, navigate }"
              :to="{
                name: 'settings_inbox_show',
                params: { inboxId: inbox.id },
              }"
              custom
            >
              <a
                v-tooltip.top="$t('INBOX_MGMT.SETTINGS')"
                :href="href"
                class="inline-flex rounded-lg p-2 text-on-surface-variant transition-colors hover:bg-surface-container-high hover:text-secondary"
                @click="navigate"
              >
                <Icon icon="i-lucide-settings" class="size-5" />
              </a>
            </router-link>
            <button
              v-if="isAdmin"
              v-tooltip.top="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
              type="button"
              class="rounded-lg p-2 text-on-surface-variant transition-colors hover:bg-error-container/20 hover:text-error"
              @click="openDelete(inbox)"
            >
              <Icon icon="i-lucide-trash-2" class="size-5" />
            </button>
          </div>
        </div>
      </div>
      <p
        class="mx-auto mt-6 max-w-5xl text-xs font-medium text-on-primary-container"
      >
        {{ $t('INBOX_MGMT.LIST.SHOWING_COUNT', { count: inboxesList.length }) }}
      </p>
    </template>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="$t('INBOX_MGMT.DELETE.CONFIRM.TITLE')"
      :message="confirmDeleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedInbox.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
