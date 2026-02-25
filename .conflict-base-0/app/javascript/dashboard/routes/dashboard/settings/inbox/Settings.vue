<script>
import { mapGetters } from 'vuex';
import { shouldBeUrl } from 'shared/helpers/Validators';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import Avatar from 'next/avatar/Avatar.vue';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsAccordion from 'dashboard/components-next/Settings/SettingsAccordion.vue';
import inboxMixin from 'shared/mixins/inboxMixin';
import FacebookReauthorize from './facebook/Reauthorize.vue';
import InstagramReauthorize from './channels/instagram/Reauthorize.vue';
import TiktokReauthorize from './channels/tiktok/Reauthorize.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import MicrosoftReauthorize from './channels/microsoft/Reauthorize.vue';
import GoogleReauthorize from './channels/google/Reauthorize.vue';
import WhatsappReauthorize from './channels/whatsapp/Reauthorize.vue';
import InboxHealthAPI from 'dashboard/api/inboxHealth';
import PreChatFormSettings from './PreChatForm/Settings.vue';
import WeeklyAvailability from './components/WeeklyAvailability.vue';
import GreetingsEditor from 'shared/components/GreetingsEditor.vue';
import ConfigurationPage from './settingsPage/ConfigurationPage.vue';
import CustomerSatisfactionPage from './settingsPage/CustomerSatisfactionPage.vue';
import CollaboratorsPage from './settingsPage/CollaboratorsPage.vue';
import BotConfiguration from './components/BotConfiguration.vue';
import AccountHealth from './components/AccountHealth.vue';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import SenderNameExamplePreview from './components/SenderNameExamplePreview.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SpinnerLoader from 'dashboard/components-next/spinner/Spinner.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import Widget from 'dashboard/modules/widget-preview/components/Widget.vue';

export default {
  components: {
    BotConfiguration,
    CollaboratorsPage,
    ConfigurationPage,
    CustomerSatisfactionPage,
    FacebookReauthorize,
    GreetingsEditor,
    PreChatFormSettings,
    SettingIntroBanner,
    SettingsToggleSection,
    SettingsFieldSection,
    SettingsAccordion,
    WeeklyAvailability,
    SenderNameExamplePreview,
    MicrosoftReauthorize,
    GoogleReauthorize,
    NextButton,
    SpinnerLoader,
    InstagramReauthorize,
    TiktokReauthorize,
    WhatsappReauthorize,
    DuplicateInboxBanner,
    Editor,
    Avatar,
    ColorPicker,
    SelectInput,
    AccountHealth,
    Widget,
  },
  mixins: [inboxMixin],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      avatarFile: null,
      avatarUrl: '',
      greetingEnabled: true,
      greetingMessage: '',
      emailCollectEnabled: false,
      senderNameType: 'friendly',
      businessName: '',
      locktoSingleConversation: false,
      allowMessagesAfterResolved: true,
      continuityViaEmail: true,
      selectedInboxName: '',
      channelWebsiteUrl: '',
      webhookUrl: '',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      selectedFeatureFlags: [],
      replyTime: '',
      selectedTabIndex: 0,
      selectedPortalSlug: '',
      showBusinessNameInput: false,
      healthData: null,
      isLoadingHealth: false,
      healthError: null,
      widgetBubblePosition: 'right',
      widgetBubbleType: 'standard',
      widgetBubbleLauncherTitle: '',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      uiFlags: 'inboxes/getUIFlags',
      portals: 'portals/allPortals',
    }),
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
    shouldShowWhatsAppConfiguration() {
      return this.isAWhatsAppCloudChannel;
    },
    whatsAppAPIProviderName() {
      if (this.isAWhatsAppCloudChannel) {
        return this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD');
      }
      if (this.is360DialogWhatsAppChannel) {
        return this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.360_DIALOG');
      }
      if (this.isATwilioWhatsAppChannel) {
        return this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO');
      }
      return '';
    },
    tabs() {
      let visibleToAllChannelTabs = [
        {
          key: 'inbox-settings',
          name: this.$t('INBOX_MGMT.TABS.SETTINGS'),
        },
        {
          key: 'collaborators',
          name: this.$t('INBOX_MGMT.TABS.COLLABORATORS'),
        },
      ];

      if (!this.isAVoiceChannel) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'business-hours',
            name: this.$t('INBOX_MGMT.TABS.BUSINESS_HOURS'),
          },
          {
            key: 'csat',
            name: this.$t('INBOX_MGMT.TABS.CSAT'),
          },
        ];
      }

      if (this.isAWebWidgetInbox) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'pre-chat-form',
            name: this.$t('INBOX_MGMT.TABS.PRE_CHAT_FORM'),
          },
        ];
      }

      if (
        this.isATwilioChannel ||
        this.isALineChannel ||
        this.isAPIInbox ||
        this.isAVoiceChannel ||
        (this.isAnEmailChannel && !this.inbox.provider) ||
        this.shouldShowWhatsAppConfiguration ||
        this.isAWebWidgetInbox
      ) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'configuration',
            name: this.$t('INBOX_MGMT.TABS.CONFIGURATION'),
          },
        ];
      }

      if (
        this.isFeatureEnabledonAccount(this.accountId, FEATURE_FLAGS.AGENT_BOTS)
      ) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'bot-configuration',
            name: this.$t('INBOX_MGMT.TABS.BOT_CONFIGURATION'),
          },
        ];
      }
      if (this.shouldShowWhatsAppConfiguration) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'whatsapp-health',
            name: this.$t('INBOX_MGMT.TABS.ACCOUNT_HEALTH'),
          },
        ];
      }

      return visibleToAllChannelTabs;
    },
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    inboxIcon() {
      const { medium, channel_type: type } = this.inbox;
      return getInboxIconByType(type, medium, 'line');
    },
    bannerMaxWidth() {
      const narrowTabs = [
        'collaborators',
        'configuration',
        'bot-configuration',
      ];
      if (narrowTabs.includes(this.selectedTabKey)) return 'max-w-4xl';
      if (this.selectedTabKey === 'inbox-settings') {
        return this.isAWebWidgetInbox ? 'max-w-7xl' : 'max-w-4xl';
      }
      return 'max-w-7xl';
    },
    inboxName() {
      if (this.isATwilioSMSChannel || this.isATwilioWhatsAppChannel) {
        return `${this.inbox.name} (${
          this.inbox.messaging_service_sid || this.inbox.phone_number
        })`;
      }
      if (this.isAWhatsAppChannel) {
        return `${this.inbox.name} (${this.inbox.phone_number})`;
      }
      if (this.isAnEmailChannel) {
        return `${this.inbox.name} (${this.inbox.email})`;
      }
      return this.inbox.name;
    },
    canLocktoSingleConversation() {
      return (
        this.isASmsInbox ||
        this.isAWhatsAppChannel ||
        this.isAFacebookInbox ||
        this.isAPIInbox ||
        this.isATelegramChannel
      );
    },
    inboxNameLabel() {
      if (this.isAWebWidgetInbox) {
        return this.$t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL');
      }
      return this.$t('INBOX_MGMT.ADD.CHANNEL_NAME.LABEL');
    },
    inboxNamePlaceHolder() {
      if (this.isAWebWidgetInbox) {
        return this.$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER');
      }
      return this.$t('INBOX_MGMT.ADD.CHANNEL_NAME.PLACEHOLDER');
    },
    textAreaChannels() {
      if (
        this.isATwilioChannel ||
        this.isATwitterInbox ||
        this.isAFacebookInbox
      )
        return true;
      return false;
    },
    instagramUnauthorized() {
      return this.isAnInstagramChannel && this.inbox.reauthorization_required;
    },
    tiktokUnauthorized() {
      return this.isATiktokChannel && this.inbox.reauthorization_required;
    },
    // Check if a instagram inbox exists with the same instagram_id
    hasDuplicateInstagramInbox() {
      const instagramId = this.inbox.instagram_id;
      const instagramInbox =
        this.$store.getters['inboxes/getInstagramInboxByInstagramId'](
          instagramId
        );

      return this.inbox.channel_type === INBOX_TYPES.FB && instagramInbox;
    },
    microsoftUnauthorized() {
      return this.isAMicrosoftInbox && this.inbox.reauthorization_required;
    },
    facebookUnauthorized() {
      return this.isAFacebookInbox && this.inbox.reauthorization_required;
    },
    googleUnauthorized() {
      const isLegacyInbox = ['imap.gmail.com', 'imap.google.com'].includes(
        this.inbox.imap_address
      );

      return (
        (this.isAGoogleInbox || isLegacyInbox) &&
        this.inbox.reauthorization_required
      );
    },
    isEmbeddedSignupWhatsApp() {
      return this.inbox.provider_config?.source === 'embedded_signup';
    },
    whatsappUnauthorized() {
      return (
        this.isAWhatsAppCloudChannel &&
        this.isEmbeddedSignupWhatsApp &&
        this.inbox.reauthorization_required
      );
    },
    whatsappRegistrationIncomplete() {
      if (
        !this.healthData ||
        !this.isAWhatsAppCloudChannel ||
        !this.isEmbeddedSignupWhatsApp
      ) {
        return false;
      }

      return (
        this.healthData.platform_type === 'NOT_APPLICABLE' ||
        this.healthData.throughput?.level === 'NOT_APPLICABLE'
      );
    },
    widgetBuilderStorageKey() {
      return `${LOCAL_STORAGE_KEYS.WIDGET_BUILDER}${this.inbox.id}`;
    },
  },
  watch: {
    $route(to, from) {
      if (to.name === 'settings_inbox_show') {
        const inboxChanged = to.params.inboxId !== from.params.inboxId;
        if (inboxChanged) {
          this.syncInboxData();
          this.setTabFromRouteParam();
        }
      }
    },
    inbox: {
      handler(newInbox, oldInbox) {
        if (newInbox?.id !== oldInbox?.id) {
          this.syncInboxData();
          this.fetchHealthData();
          this.$nextTick(() => {
            this.setTabFromRouteParam();
          });
        }
      },
      immediate: true,
    },
  },
  mounted() {
    this.fetchSharedData();
  },
  methods: {
    fetchSharedData() {
      this.$store.dispatch('agents/get');
      this.$store.dispatch('teams/get');
      this.$store.dispatch('labels/get');
      this.$store.dispatch('portals/index');
    },
    syncInboxData() {
      if (!this.inbox || !this.inbox.id) return;

      this.avatarUrl = this.inbox.avatar_url;
      this.selectedInboxName = this.inbox.name;
      this.webhookUrl = this.inbox.webhook_url;
      this.greetingEnabled = this.inbox.greeting_enabled || false;
      this.greetingMessage = this.inbox.greeting_message || '';
      this.emailCollectEnabled = this.inbox.enable_email_collect;
      this.senderNameType = this.inbox.sender_name_type;
      this.businessName = this.inbox.business_name;
      this.allowMessagesAfterResolved =
        this.inbox.allow_messages_after_resolved;
      this.continuityViaEmail = this.inbox.continuity_via_email;
      this.channelWebsiteUrl = this.inbox.website_url;
      this.channelWelcomeTitle = this.inbox.welcome_title;
      this.channelWelcomeTagline = this.inbox.welcome_tagline || '';
      this.selectedFeatureFlags = this.inbox.selected_feature_flags || [];
      this.replyTime = this.inbox.reply_time;
      this.locktoSingleConversation = this.inbox.lock_to_single_conversation;
      this.selectedPortalSlug = this.inbox.help_center
        ? this.inbox.help_center.slug
        : '';

      const savedBubbleSettings = LocalStorage.get(
        this.widgetBuilderStorageKey
      );
      if (savedBubbleSettings) {
        this.widgetBubblePosition = savedBubbleSettings.position || 'right';
        this.widgetBubbleType = savedBubbleSettings.type || 'standard';
        this.widgetBubbleLauncherTitle =
          savedBubbleSettings.launcherTitle || '';
      } else {
        this.widgetBubblePosition = 'right';
        this.widgetBubbleType = 'standard';
        this.widgetBubbleLauncherTitle = '';
      }
    },
    async fetchHealthData() {
      if (!this.inbox) return;

      if (!this.isAWhatsAppCloudChannel) {
        return;
      }

      try {
        this.isLoadingHealth = true;
        this.healthError = null;
        const response = await InboxHealthAPI.getHealthStatus(this.inbox.id);
        this.healthData = response.data;
      } catch (error) {
        this.healthError = error.message || 'Failed to fetch health data';
      } finally {
        this.isLoadingHealth = false;
      }
    },
    handleFeatureFlag(e) {
      this.selectedFeatureFlags = this.toggleInput(
        this.selectedFeatureFlags,
        e.target.value
      );
    },
    toggleInput(selected, current) {
      if (selected.includes(current)) {
        const newSelectedFlags = selected.filter(flag => flag !== current);
        return newSelectedFlags;
      }
      return [...selected, current];
    },
    onTabChange(selectedTabIndex) {
      this.selectedTabIndex = selectedTabIndex;
      this.updateRouteWithoutRefresh(selectedTabIndex);
    },
    updateRouteWithoutRefresh(selectedTabIndex) {
      const tab = this.tabs[selectedTabIndex];
      if (!tab) return;

      const { accountId, inboxId } = this.$route.params;
      const baseUrl = `/app/accounts/${accountId}/settings/inboxes/${inboxId}`;

      // Append the tab key only if it's not the default.
      const newUrl =
        tab.key === 'inbox-settings' ? baseUrl : `${baseUrl}/${tab.key}`;
      // Update URL without triggering route watcher
      window.history.replaceState(null, '', newUrl);
    },
    setTabFromRouteParam() {
      const { tab: tabParam } = this.$route.params;
      if (!tabParam) {
        this.selectedTabIndex = 0;
        return;
      }
      const tabIndex = this.tabs.findIndex(tab => tab.key === tabParam);
      this.selectedTabIndex = tabIndex === -1 ? 0 : tabIndex;
    },
    async updateInbox() {
      const bubbleSettings = {
        position: this.widgetBubblePosition,
        type: this.widgetBubbleType,
        launcherTitle: this.widgetBubbleLauncherTitle,
      };
      LocalStorage.set(this.widgetBuilderStorageKey, bubbleSettings);

      try {
        const payload = {
          id: this.currentInboxId,
          name: this.selectedInboxName?.trim(),
          enable_email_collect: this.emailCollectEnabled,
          allow_messages_after_resolved: this.allowMessagesAfterResolved,
          greeting_enabled: this.greetingEnabled,
          greeting_message: this.greetingMessage || '',
          portal_id: this.selectedPortalSlug
            ? this.portals.find(
                portal => portal.slug === this.selectedPortalSlug
              )?.id || null
            : null,
          lock_to_single_conversation: this.locktoSingleConversation,
          sender_name_type: this.senderNameType,
          business_name: this.businessName || null,
          channel: {
            widget_color: this.inbox.widget_color,
            website_url: this.channelWebsiteUrl,
            webhook_url: this.webhookUrl,
            welcome_title: this.channelWelcomeTitle || '',
            welcome_tagline: this.channelWelcomeTagline || '',
            selectedFeatureFlags: this.selectedFeatureFlags,
            reply_time: this.replyTime || 'in_a_few_minutes',
            continuity_via_email: this.continuityViaEmail,
          },
        };
        if (this.avatarFile) {
          payload.avatar = this.avatarFile;
        }
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.showBusinessNameInput = false;
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async handleAvatarDelete() {
      try {
        await this.$store.dispatch(
          'inboxes/deleteInboxAvatar',
          this.currentInboxId
        );
        this.avatarFile = null;
        this.avatarUrl = '';
        useAlert(this.$t('INBOX_MGMT.DELETE.API.AVATAR_SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('INBOX_MGMT.DELETE.API.AVATAR_ERROR_MESSAGE')
        );
      }
    },
    toggleSenderNameType(key) {
      this.senderNameType = key;
    },
    onClickShowBusinessNameInput() {
      this.showBusinessNameInput = true;
      this.$nextTick(() => {
        this.$refs.businessNameInput?.focus();
      });
    },
    hideBusinessNameInput() {
      this.showBusinessNameInput = false;
    },
  },
  validations: {
    webhookUrl: {
      shouldBeUrl,
    },
    selectedInboxName: {},
  },
};
</script>

<template>
  <div
    v-if="uiFlags.isFetching"
    class="flex items-center justify-center h-full w-full"
  >
    <SpinnerLoader :size="28" class="text-n-blue-9" />
  </div>
  <div
    v-else
    class="grid grid-rows-[auto_1fr] h-full flex-grow flex-shrink pr-0 pl-0 w-full min-w-0 settings"
  >
    <SettingIntroBanner
      :header-image="inbox.avatarUrl"
      :header-title="inboxName"
    >
      <woot-tabs
        class="[&_ul]:p-0 top-px relative"
        :index="selectedTabIndex"
        :border="false"
        @change="onTabChange"
      >
        <woot-tabs-item
          v-for="(tab, index) in tabs"
          :key="tab.key"
          :index="index"
          :name="tab.name"
          :show-badge="false"
          is-compact
        />
      </woot-tabs>
    </SettingIntroBanner>
    <section class="w-full overflow-auto py-8">
      <div class="max-w-7xl mx-auto w-full">
        <MicrosoftReauthorize
          v-if="microsoftUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <FacebookReauthorize
          v-if="facebookUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <GoogleReauthorize
          v-if="googleUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <InstagramReauthorize
          v-if="instagramUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <TiktokReauthorize
          v-if="tiktokUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <WhatsappReauthorize
          v-if="whatsappUnauthorized"
          :whatsapp-registration-incomplete="whatsappRegistrationIncomplete"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <DuplicateInboxBanner
          v-if="hasDuplicateInstagramInbox"
          :content="$t('INBOX_MGMT.ADD.INSTAGRAM.DUPLICATE_INBOX_BANNER')"
          class="mx-6 mb-4"
          :class="bannerMaxWidth"
        />

        <div
          v-if="selectedTabKey === 'inbox-settings'"
          class="flex flex-col md:flex-row items-center lg:items-start justify-between gap-5 lg:gap-10 mx-6"
        >
          <div
            class="flex-1 flex flex-col min-w-0"
            :class="{
              'max-w-2xl': isAWebWidgetInbox,
              'max-w-4xl': !isAWebWidgetInbox,
            }"
          >
            <div class="flex flex-col gap-1 items-start mb-4">
              <label class="text-heading-3 text-n-slate-12">
                {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AVATAR.LABEL') }}
              </label>
              <Avatar
                :src="avatarUrl"
                :size="64"
                :icon-name="inboxIcon"
                name=""
                allow-upload
                rounded-full
                @upload="handleImageUpload"
                @delete="handleAvatarDelete"
              />
            </div>
            <SettingsFieldSection :label="inboxNameLabel">
              <woot-input
                v-model="selectedInboxName"
                class="[&>input]:!mb-0"
                :class="{ error: v$.selectedInboxName.$error }"
                :placeholder="inboxNamePlaceHolder"
                :error="
                  v$.selectedInboxName.$error
                    ? $t('INBOX_MGMT.ADD.CHANNEL_NAME.ERROR')
                    : ''
                "
                @blur="v$.selectedInboxName.$touch"
              />
            </SettingsFieldSection>
            <SettingsFieldSection
              v-if="isAPIInbox"
              :label="
                $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.LABEL')
              "
            >
              <woot-input
                v-model="webhookUrl"
                class="[&>input]:!mb-0"
                :class="{ error: v$.webhookUrl.$error }"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.PLACEHOLDER'
                  )
                "
                :error="
                  v$.webhookUrl.$error
                    ? $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.ERROR'
                      )
                    : ''
                "
                @blur="v$.webhookUrl.$touch"
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="isAWebWidgetInbox"
              :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL')"
            >
              <woot-input
                v-model="channelWebsiteUrl"
                class="[&>input]:!mb-0"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER'
                  )
                "
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="isAWhatsAppChannel"
              :label="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL')"
            >
              <input
                v-model="whatsAppAPIProviderName"
                type="text"
                disabled
                class="!mb-0"
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="!isAVoiceChannel"
              :label="$t('INBOX_MGMT.HELP_CENTER.LABEL')"
              :help-text="$t('INBOX_MGMT.HELP_CENTER.SUB_TEXT')"
            >
              <SelectInput
                v-model="selectedPortalSlug"
                :placeholder="$t('INBOX_MGMT.HELP_CENTER.PLACEHOLDER')"
                :options="[
                  { value: '', label: $t('INBOX_MGMT.HELP_CENTER.NONE') },
                  ...portals.map(p => ({ value: p.slug, label: p.name })),
                ]"
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="isAWebWidgetInbox || isAnEmailChannel"
              :label="$t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.TITLE')"
              class="[&>div>div]:justify-end [&>div>div]:flex lg:[&>div:first-child]:h-12 [&>div:first-child]:h-16"
            >
              <NextButton
                v-if="!showBusinessNameInput"
                ghost
                blue
                sm
                :label="
                  $t(
                    'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.BUSINESS_NAME.BUTTON_TEXT'
                  )
                "
                @click="onClickShowBusinessNameInput"
              />

              <div
                v-if="showBusinessNameInput"
                v-on-clickaway="hideBusinessNameInput"
                class="flex justify-end gap-2 w-full"
              >
                <input
                  ref="businessNameInput"
                  v-model="businessName"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.BUSINESS_NAME.PLACEHOLDER'
                    )
                  "
                  class="!mb-0"
                  type="text"
                />
                <NextButton
                  :label="
                    $t(
                      'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.BUSINESS_NAME.SAVE_BUTTON_TEXT'
                    )
                  "
                  class="flex-shrink-0"
                  @click="updateInbox"
                />
              </div>

              <template #extra>
                <SenderNameExamplePreview
                  :sender-name-type="senderNameType"
                  :business-name="businessName"
                  :is-website-channel="isAWebWidgetInbox"
                  @update="toggleSenderNameType"
                />
              </template>
            </SettingsFieldSection>

            <SettingsAccordion
              v-if="isAWebWidgetInbox"
              :title="$t('INBOX_MGMT.WIDGET_FEATURES')"
              class="mt-6"
            >
              <SettingsFieldSection
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL'
                  )
                "
              >
                <woot-input
                  v-model="channelWelcomeTitle"
                  class="[&>input]:!mb-0"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
                    )
                  "
                />
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL'
                  )
                "
                class="[&>div]:!items-start [&>div>label]:mt-1"
              >
                <Editor
                  v-model="channelWelcomeTagline"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
                    )
                  "
                  :max-length="255"
                  channel-type="Context::InboxSettings"
                />
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL')"
              >
                <div class="justify-start">
                  <ColorPicker v-model="inbox.widget_color" />
                </div>
              </SettingsFieldSection>
              <SettingsFieldSection
                :label="
                  $t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE')
                "
              >
                <div class="flex items-center gap-6">
                  <div class="flex items-center gap-2">
                    <label class="text-n-slate-11 text-heading-3">
                      {{
                        $t(
                          'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION_LABEL'
                        )
                      }}
                    </label>
                    <SelectInput
                      v-model="widgetBubblePosition"
                      :options="[
                        {
                          label: $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION.LEFT'
                          ),
                          value: 'left',
                        },
                        {
                          label: $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION.RIGHT'
                          ),
                          value: 'right',
                        },
                      ]"
                      class="[&>select]:!p-0 min-w-16 [&>select]:!outline-none"
                    />
                  </div>
                  <div class="h-3 w-px bg-n-weak rounded-lg" />
                  <div class="flex items-center gap-2">
                    <label class="text-n-slate-11 text-heading-3">
                      {{
                        $t(
                          'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE_LABEL'
                        )
                      }}
                    </label>
                    <SelectInput
                      v-model="widgetBubbleType"
                      :options="[
                        {
                          label: $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE.STANDARD'
                          ),
                          value: 'standard',
                        },
                        {
                          label: $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE.EXPANDED_BUBBLE'
                          ),
                          value: 'expanded_bubble',
                        },
                      ]"
                      class="[&>select]:!p-0 min-w-16 [&>select]:!outline-none"
                    />
                  </div>
                </div>
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="
                  $t(
                    'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.LABEL'
                  )
                "
              >
                <woot-input
                  v-model="widgetBubbleLauncherTitle"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.PLACE_HOLDER'
                    )
                  "
                  class="[&>input]:!mb-0"
                />
              </SettingsFieldSection>
              <SettingsFieldSection
                :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.TITLE')"
                :help-text="
                  $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.HELP_TEXT')
                "
              >
                <SelectInput
                  v-model="replyTime"
                  :options="[
                    {
                      value: 'in_a_few_minutes',
                      label: $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_MINUTES'
                      ),
                    },
                    {
                      value: 'in_a_few_hours',
                      label: $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_HOURS'
                      ),
                    },
                    {
                      value: 'in_a_day',
                      label: $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_DAY'
                      ),
                    },
                  ]"
                />
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="$t('INBOX_MGMT.FEATURES.LABEL')"
                class="[&>div]:!items-start [&>div>label]:mt-2"
              >
                <div class="flex flex-col gap-1 items-start">
                  <div class="flex gap-2 pt-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="attachments"
                      @input="handleFeatureFlag"
                    />
                    <label for="attachments">
                      {{ $t('INBOX_MGMT.FEATURES.DISPLAY_FILE_PICKER') }}
                    </label>
                  </div>
                  <div class="flex gap-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="emoji_picker"
                      @input="handleFeatureFlag"
                    />
                    <label for="emoji_picker">
                      {{ $t('INBOX_MGMT.FEATURES.DISPLAY_EMOJI_PICKER') }}
                    </label>
                  </div>
                  <div class="flex gap-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="end_conversation"
                      @input="handleFeatureFlag"
                    />
                    <label for="end_conversation">
                      {{ $t('INBOX_MGMT.FEATURES.ALLOW_END_CONVERSATION') }}
                    </label>
                  </div>
                  <div class="flex gap-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="use_inbox_avatar_for_bot"
                      @input="handleFeatureFlag"
                    />
                    <label for="use_inbox_avatar_for_bot">
                      {{ $t('INBOX_MGMT.FEATURES.USE_INBOX_AVATAR_FOR_BOT') }}
                    </label>
                  </div>
                </div>
              </SettingsFieldSection>
            </SettingsAccordion>

            <SettingsAccordion
              :title="$t('INBOX_MGMT.CHANNEL_PREFERENCES')"
              class="mt-6"
            >
              <SettingsToggleSection
                v-model="greetingEnabled"
                :header="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.LABEL'
                  )
                "
                :description="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.HELP_TEXT'
                  )
                "
              >
                <template v-if="greetingEnabled" #editor>
                  <GreetingsEditor
                    v-model="greetingMessage"
                    :label="
                      $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.LABEL'
                      )
                    "
                    :placeholder="
                      $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.PLACEHOLDER'
                      )
                    "
                    :richtext="!textAreaChannels"
                  />
                </template>
              </SettingsToggleSection>

              <SettingsToggleSection
                v-if="isAWebWidgetInbox"
                v-model="emailCollectEnabled"
                :header="
                  $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_EMAIL_COLLECT_BOX')
                "
                :description="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.ENABLE_EMAIL_COLLECT_BOX_SUB_TEXT'
                  )
                "
              />

              <SettingsToggleSection
                v-if="isAWebWidgetInbox"
                v-model="allowMessagesAfterResolved"
                :header="
                  $t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MESSAGES_AFTER_RESOLVED')
                "
                :description="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.ALLOW_MESSAGES_AFTER_RESOLVED_SUB_TEXT'
                  )
                "
              />

              <SettingsToggleSection
                v-if="isAWebWidgetInbox"
                v-model="continuityViaEmail"
                :header="
                  $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CONTINUITY_VIA_EMAIL')
                "
                :description="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.ENABLE_CONTINUITY_VIA_EMAIL_SUB_TEXT'
                  )
                "
              />

              <SettingsToggleSection
                v-if="canLocktoSingleConversation"
                v-model="locktoSingleConversation"
                :header="
                  $t('INBOX_MGMT.SETTINGS_POPUP.LOCK_TO_SINGLE_CONVERSATION')
                "
                :description="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.LOCK_TO_SINGLE_CONVERSATION_SUB_TEXT'
                  )
                "
              />
            </SettingsAccordion>

            <div class="w-full flex justify-end items-center py-4 mt-2">
              <NextButton
                v-if="isAPIInbox"
                type="submit"
                :disabled="v$.webhookUrl.$invalid"
                :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                :is-loading="uiFlags.isUpdating"
                @click="updateInbox"
              />
              <NextButton
                v-else
                type="submit"
                :disabled="v$.$invalid"
                :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                :is-loading="uiFlags.isUpdating"
                @click="updateInbox"
              />
            </div>
          </div>

          <div
            v-if="isAWebWidgetInbox"
            class="flex-1 sticky top-4 self-start max-w-lg flex-shrink-0 w-full min-w-0"
          >
            <div
              class="flex flex-col outline -outline-offset-1 outline-1 outline-n-weak w-full px-3 pt-3 pb-8 bg-n-surface-1 rounded-2xl min-h-[45rem] overflow-hidden"
            >
              <Widget
                :welcome-heading="channelWelcomeTitle"
                :welcome-tagline="channelWelcomeTagline"
                :website-name="selectedInboxName"
                :logo="avatarUrl"
                is-online
                :reply-time="replyTime"
                :color="inbox.widget_color"
                :widget-bubble-position="widgetBubblePosition"
                :widget-bubble-launcher-title="widgetBubbleLauncherTitle"
                :widget-bubble-type="widgetBubbleType"
                :web-widget-script="inbox.web_widget_script"
              />
            </div>
          </div>
        </div>

        <div v-if="selectedTabKey === 'collaborators'" class="mx-6 max-w-4xl">
          <CollaboratorsPage :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'configuration'" class="mx-6 max-w-4xl">
          <ConfigurationPage :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'csat'">
          <CustomerSatisfactionPage :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'pre-chat-form'">
          <PreChatFormSettings :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'business-hours'">
          <WeeklyAvailability :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'bot-configuration'">
          <BotConfiguration :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'whatsapp-health'">
          <AccountHealth :health-data="healthData" />
        </div>
      </div>
    </section>
  </div>
</template>
