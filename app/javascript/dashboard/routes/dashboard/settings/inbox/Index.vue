<script setup>
import { useAlert } from 'dashboard/composables';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WhatsAppStatusIndicator from 'dashboard/components/widgets/WhatsAppStatusIndicator.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import ChannelName from './components/ChannelName.vue';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const showDeletePopup = ref(false);
const selectedInbox = ref({});

const inboxesList = computed(() => getters['inboxes/getInboxes'].value);
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

const isWhatsAppUnofficial = (inbox) => {
  return inbox.channel_type === 'Channel::WhatsappUnofficial';
};

const whatsappStatus = ref({});
const statusCheckTimer = ref(null);

const handleStatusChanged = (inboxId, statusData) => {
  whatsappStatus.value[inboxId] = statusData;
  // console.log(`📱 Status changed for inbox ${inboxId}:`, statusData);
};

// Check status for all WhatsApp inboxes on mount and periodically
const checkAllWhatsAppStatus = async () => {
  const whatsappInboxes = inboxesList.value.filter(inbox => isWhatsAppUnofficial(inbox));
  
  // console.log('🔄 Checking status for all WhatsApp inboxes:', whatsappInboxes.length);
  
  for (const inbox of whatsappInboxes) {
    try {
      const response = await WhatsAppUnofficialChannels.getConnectionStatus(inbox.id, false);
      const connected = response.data?.connected || false;
      
      whatsappStatus.value[inbox.id] = {
        connected,
        inboxId: inbox.id,
        lastChecked: Date.now()
      };
      
      // console.log(`📱 Inbox ${inbox.id} (${inbox.name}) status:`, connected ? '🟢 Connected' : '🔴 Disconnected');
    } catch (error) {
      console.error(`❌ Failed to check status for inbox ${inbox.id}:`, error);
      whatsappStatus.value[inbox.id] = {
        connected: false,
        inboxId: inbox.id,
        lastChecked: Date.now(),
        error: true
      };
    }
  }
};

// Start periodic status checking
const startPeriodicStatusCheck = () => {
  // Check immediately on mount
  checkAllWhatsAppStatus();
  
  // Then check every 15 seconds for real-time monitoring (no conditions)
  statusCheckTimer.value = setInterval(() => {
    // console.log('⏰ Periodic status check triggered - checking ALL WhatsApp inboxes for real-time updates');
    checkAllWhatsAppStatus();
  }, 15000); // 15 seconds - more frequent for real-time feel
};

// Stop periodic checking
const stopPeriodicStatusCheck = () => {
  if (statusCheckTimer.value) {
    clearInterval(statusCheckTimer.value);
    statusCheckTimer.value = null;
  }
};

onMounted(() => {
  // console.log('📋 Inbox list mounted, starting WhatsApp status monitoring...');
  startPeriodicStatusCheck();
});

onUnmounted(() => {
  // console.log('📋 Inbox list unmounted, stopping WhatsApp status monitoring...');
  stopPeriodicStatusCheck();
});

const getChannelIcon = (inbox) => {
  const icon = getInboxIconByType(inbox.channel_type, inbox.phone_number, 'fill');
  return icon;
};

const getChannelIconColor = (inbox) => {
  const channelType = inbox.channel_type;

  switch (channelType) {
    case 'Channel::Whatsapp':
    case 'Channel::WhatsappUnofficial':
      return '!text-green-600'; // WhatsApp green with !important
    case 'Channel::Instagram':
      return '!text-pink-600'; // Instagram pink/purple with !important
    case 'Channel::FacebookPage':
      return '!text-blue-600'; // Facebook blue with !important
    case 'Channel::TwitterProfile':
      return '!text-sky-500'; // Twitter blue with !important
    case 'Channel::Telegram':
      return '!text-blue-500'; // Telegram blue with !important
    case 'Channel::Email':
      return '!text-gray-600'; // Email gray with !important
    case 'Channel::Api':
      return '!text-purple-600'; // API purple with !important
    case 'Channel::Line':
      return '!text-green-500'; // LINE green with !important
    case 'Channel::WebWidget':
      return '!text-blue-500'; // Web widget blue with !important
    default:
      return '!text-gray-600'; // Default gray with !important
  }
};

const getStatusTooltip = (inbox) => {
  const status = whatsappStatus.value[inbox.id];
  if (!status) {
    return 'Status belum diketahui';
  }
  
  const statusText = status.connected ? 'Terhubung' : 'Terputus';
  const lastChecked = status.lastChecked || status.lastUpdated;
  const timeAgo = lastChecked ? new Date(lastChecked).toLocaleString('id-ID') : 'Tidak diketahui';
  
  return `Status: ${statusText}\nTerakhir update: ${timeAgo}`;
};

// Temporary function to test inline colors (for debugging)
const getInlineColorStyle = (inbox) => {
  const channelType = inbox.channel_type;
  
  switch (channelType) {
    case 'Channel::Whatsapp':
    case 'Channel::WhatsappUnofficial':
      return { color: '#16a34a' }; // green-600
    case 'Channel::Instagram':
      return { color: '#db2777' }; // pink-600
    case 'Channel::FacebookPage':
      return { color: '#2563eb' }; // blue-600
    case 'Channel::TwitterProfile':
      return { color: '#0ea5e9' }; // sky-500
    case 'Channel::Telegram':
      return { color: '#3b82f6' }; // blue-500
    case 'Channel::Email':
      return { color: '#6b7280' }; // gray-600
    case 'Channel::Api':
      return { color: '#9333ea' }; // purple-600
    case 'Channel::Line':
      return { color: '#22c55e' }; // green-500
    case 'Channel::WebWidget':
      return { color: '#3b82f6' }; // blue-500
    default:
      return { color: '#6b7280' }; // gray-600
  }
};
</script>

<template>
  <SettingsLayout
    :no-records-found="!inboxesList.length"
    :no-records-message="$t('INBOX_MGMT.LIST.404')"
    :is-loading="uiFlags.isFetching"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('INBOX_MGMT.HEADER')"
        :description="$t('INBOX_MGMT.DESCRIPTION')"
        :link-text="$t('INBOX_MGMT.LEARN_MORE')"
        feature-name="inboxes"
      >
        <template #actions>
          <router-link
            v-if="isAdmin"
            class="button nice rounded-md"
            :to="{ name: 'settings_inbox_new' }"
          >
            <fluent-icon icon="add-circle" />
            {{ $t('SETTINGS.INBOXES.NEW_INBOX') }}
          </router-link>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table
        class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700"
      >
        <tbody
          class="divide-y divide-slate-25 dark:divide-slate-800 flex-1 text-slate-700 dark:text-slate-100"
        >
          <tr v-for="inbox in inboxesList" :key="inbox.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex items-center flex-row gap-4">
                <div class="relative">
                  <Thumbnail
                    v-if="inbox.avatar_url"
                    class="bg-black-50 dark:bg-black-800 rounded-full p-2 ring ring-opacity-20 dark:ring-opacity-80 ring-black-100 dark:ring-black-900 border border-slate-100 dark:border-slate-700/50 shadow-sm"
                    :src="inbox.avatar_url"
                    :username="inbox.name"
                    size="48px"
                  />
                  <div
                    v-else
                    class="w-12 h-12 bg-black-50 dark:bg-black-800 rounded-full p-2 ring ring-opacity-20 dark:ring-opacity-80 ring-black-100 dark:ring-black-900 border border-slate-100 dark:border-slate-700/50 shadow-sm flex items-center justify-center"
                  >
                    <i 
                      :class="`${getChannelIcon(inbox)} ${getChannelIconColor(inbox)} text-xl`"
                      :style="getInlineColorStyle(inbox)"
                    />
                    <!-- Debug: Show class info -->
                    <span class="sr-only">{{ getChannelIcon(inbox) }} {{ getChannelIconColor(inbox) }}</span>
                  </div>
                  
                  <!-- WhatsApp Status Indicator Circle - positioned at bottom-right corner of avatar -->
                  <div
                    v-if="isWhatsAppUnofficial(inbox)"
                    class="absolute -bottom-0 -right-1 z-10"
                    v-tooltip.top="getStatusTooltip(inbox)"
                  >
                    <WhatsAppStatusIndicator
                      :inbox-id="inbox.id"
                      :account-id="$route.params.accountId"
                      :auto-refresh="true"
                      :refresh-interval="10000"
                      @status-changed="(data) => handleStatusChanged(inbox.id, data)"
                    />
                  </div>
                </div>
                
                <div>
                  <span class="block font-medium capitalize">
                    {{ inbox.name }}
                  </span>
                  <ChannelName
                    :channel-type="inbox.channel_type"
                    :medium="inbox.medium"
                    :phone-number="inbox.phone_number"
                  />
                </div>
              </div>
            </td>

            <td class="py-4">
              <div class="flex gap-1 justify-end">
                <router-link
                  :to="{
                    name: 'settings_inbox_show',
                    params: { inboxId: inbox.id },
                  }"
                >
                  <woot-button
                    v-if="isAdmin"
                    v-tooltip.top="$t('INBOX_MGMT.SETTINGS')"
                    variant="smooth"
                    size="tiny"
                    icon="settings"
                    color-scheme="secondary"
                    class-names="grey-btn"
                  />
                </router-link>

                <woot-button
                  v-if="isAdmin"
                  v-tooltip.top="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  class-names="grey-btn"
                  icon="dismiss-circle"
                  @click="openDelete(inbox)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
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
