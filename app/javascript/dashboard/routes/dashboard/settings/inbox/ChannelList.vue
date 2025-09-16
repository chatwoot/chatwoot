<script>
import ChannelItem from 'dashboard/components/widgets/ChannelItem.vue';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    ChannelItem,
    PageHeader,
  },
  mixins: [globalConfigMixin],
  data() {
    return {
      enabledFeatures: {},
      isLoadingFeatures: true, // Add loading state
    };
  },
  computed: {
    account() {
      return this.$store.getters['accounts/getAccount'](this.accountId);
    },
    inboxesList() {
      return this.$store.getters['inboxes/getInboxes'];
    },
    currentInboxCount() {
      return this.inboxesList.length;
    },
    maxChannels() {
      // Return null if still loading
      if (this.isLoadingFeatures) {
        return null;
      }
      
      // Return the actual value from database, don't fallback to 0 if null
      const rawValue = this.enabledFeatures?.max_channels;
      
      return rawValue; // This could be null, 0, or positive number
    },
    isChannelLimitReached() {
      
      // If still loading, don't restrict
      if (this.isLoadingFeatures) {
        return false;
      }
      
      // Get max channels from database
      const maxChannels = this.maxChannels;
      
      // Handle different database values:
      // null = limited but no specific limit set (block creation)
      // 0 = unlimited (no restriction) 
      // positive number = limited to that number
      if (maxChannels === null) {
        return true; // Block channel creation
      }
      
      if (maxChannels === 0) {
        return false;
      }
      
      if (maxChannels > 0) {
        const currentCount = this.currentInboxCount;
        return currentCount >= maxChannels;
      }
      
      // Fallback for any other unexpected value
      return true;
    },
    channelList() {
      const { apiChannelName, apiChannelThumbnail } = this.globalConfig;
      return [
        { key: 'website', name: 'Website' },
        { key: 'whatsapp', name: 'WhatsApp' },
        {
          key: 'whatsapp_unofficial',
          name: 'WhatsApp (Unofficial)',
          thumbnail: '/assets/images/channels/whatsapp.png',
        },
        {
          key: 'api',
          name: apiChannelName || 'API',
          thumbnail: apiChannelThumbnail,
        },
        { key: 'telegram', name: 'Telegram' },
        { key: 'instagram', name: 'Instagram' },
      ];
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    this.initializeEnabledFeatures();
  },
  methods: {
    async initializeEnabledFeatures() {
      try {
        this.isLoadingFeatures = true;
        const response = await this.$store.dispatch('myActiveSubscription');
        this.enabledFeatures = response || {};
      } catch (error) {
        console.error('Failed to fetch active subscription:', error);
        // Set default values if fetch fails
        this.enabledFeatures = {
          max_channels: 0, // Default to unlimited if can't fetch
          available_channels: []
        };
      } finally {
        this.isLoadingFeatures = false;
      }
    },

    initChannelAuth(channel) {
      // Don't proceed if still loading features
      if (this.isLoadingFeatures) {
        return;
      }
      
      // Check channel limit before proceeding
      if (this.isChannelLimitReached) {
        let errorMessage;
        if (this.maxChannels === null) {
          errorMessage = this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL_LIMIT_NO_QUOTA') || 'Channel creation is restricted. No quota has been set for your account.';
        } else {
          errorMessage = this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL_LIMIT_REACHED', {
            current: this.currentInboxCount,
            max: this.maxChannels
          });
        }
        
        this.$root.$emit('show-snackbar', {
          message: errorMessage,
          type: 'error'
        });
        return;
      }
      
      const params = {
        sub_page: channel,
        accountId: this.accountId,
      };
      router.push({ name: 'settings_inboxes_page_channel', params });
    },
  },
};

</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <PageHeader
      class="max-w-4xl"
      :header-title="$t('INBOX_MGMT.ADD.AUTH.TITLE')"
      :header-content="
        useInstallationName(
          $t('INBOX_MGMT.ADD.AUTH.DESC'),
          globalConfig.installationName
        )
      "
    />
    
    <!-- Channel limit warning - Show when there's any kind of limitation (null or positive number) -->
    <div 
      v-if="!isLoadingFeatures && (maxChannels === null || maxChannels > 0)" 
      class="mb-4 mt-4 p-4 rounded-md"
      :class="isChannelLimitReached ? 'bg-red-50 border border-red-200 dark:bg-red-900/20 dark:border-red-800' : 'bg-blue-50 border border-blue-200 dark:bg-blue-900/20 dark:border-blue-800'"
    >
      <div class="flex">
        <div class="flex-shrink-0">
          <fluent-icon 
            :icon="isChannelLimitReached ? 'warning' : 'info'"
            :class="isChannelLimitReached ? 'text-red-400' : 'text-blue-400'"
          />
        </div>
        <div class="ml-3">
          <p 
            :class="isChannelLimitReached ? 'text-red-800 dark:text-red-200' : 'text-blue-800 dark:text-blue-200'"
            class="text-sm font-medium"
          >
            <span v-if="isChannelLimitReached && maxChannels === null">
              {{ $t('INBOX_MGMT.ADD.AUTH.CHANNEL_LIMIT_NO_QUOTA') || 'Channel creation is restricted. No quota has been set for your account.' }}
            </span>
            <span v-else-if="isChannelLimitReached && maxChannels > 0">
              {{ $t('INBOX_MGMT.ADD.AUTH.CHANNEL_LIMIT_REACHED', { current: currentInboxCount, max: maxChannels }) }}
            </span>
            <span v-else-if="maxChannels > 0">
              {{ $t('INBOX_MGMT.ADD.AUTH.CHANNEL_LIMIT_INFO', { current: currentInboxCount, max: maxChannels }) }}
            </span>
          </p>
        </div>
      </div>
    </div>

    <!-- Loading indicator -->
    <div v-if="isLoadingFeatures" class="mb-4 p-4 bg-gray-50 border border-gray-200 dark:bg-gray-800/20 dark:border-gray-700 rounded-md">
      <div class="flex items-center">
        <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-500"></div>
        <span class="ml-3 text-sm text-gray-600 dark:text-gray-400">Loading channel limits...</span>
      </div>
    </div>

    <div
      class="grid max-w-3xl grid-cols-2 mx-0 mt-6 sm:grid-cols-3 lg:grid-cols-4"
    >
      <ChannelItem
        v-for="channel in channelList"
        :key="channel.key"
        :channel="channel"
        :enabled-features="enabledFeatures"
        :disabled="!isLoadingFeatures && isChannelLimitReached"
        @channel-item-click="initChannelAuth"
      />
    </div>
  </div>
</template>
