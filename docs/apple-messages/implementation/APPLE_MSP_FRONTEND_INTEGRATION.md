# Apple Messages for Business - Frontend Integration

## Frontend Components Implementation

This document covers the frontend integration for Apple Messages for Business, including Vue.js components, message rendering, and UI elements.

## 1. Channel Configuration Components

### 1.1 Channel Settings Component
```vue
<!-- app/javascript/dashboard/routes/dashboard/settings/inbox/channels/AppleMessagesForBusiness.vue -->
<template>
  <div class="apple-messages-for-business-settings">
    <div class="medium-9 columns">
      <woot-input
        v-model="businessId"
        :label="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.BUSINESS_ID.LABEL')"
        :placeholder="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.BUSINESS_ID.PLACEHOLDER')"
        :error="businessIdError"
        @blur="validateBusinessId"
      />
      
      <woot-input
        v-model="teamId"
        :label="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.TEAM_ID.LABEL')"
        :placeholder="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.TEAM_ID.PLACEHOLDER')"
        :error="teamIdError"
        @blur="validateTeamId"
      />
      
      <woot-input
        v-model="keyId"
        :label="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.KEY_ID.LABEL')"
        :placeholder="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.KEY_ID.PLACEHOLDER')"
        :error="keyIdError"
        @blur="validateKeyId"
      />
      
      <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
        {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PRIVATE_KEY.LABEL') }}
      </label>
      <textarea
        v-model="privateKey"
        :placeholder="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PRIVATE_KEY.PLACEHOLDER')"
        class="w-full p-3 border border-slate-200 dark:border-slate-600 rounded-md"
        rows="8"
        @blur="validatePrivateKey"
      />
      <span v-if="privateKeyError" class="text-red-400 text-xs block mt-1">
        {{ privateKeyError }}
      </span>
      
      <woot-input
        v-model="imessageExtensionBid"
        :label="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_EXTENSION_BID.LABEL')"
        :placeholder="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_EXTENSION_BID.PLACEHOLDER')"
        :error="imessageExtensionBidError"
        @blur="validateImessageExtensionBid"
      />
      
      <div class="mt-4">
        <label class="flex items-center">
          <input
            v-model="enableInteractiveMessages"
            type="checkbox"
            class="form-checkbox h-4 w-4 text-woot-600"
          />
          <span class="ml-2 text-sm text-slate-700 dark:text-slate-300">
            {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.ENABLE_INTERACTIVE_MESSAGES') }}
          </span>
        </label>
      </div>
      
      <div class="mt-4">
        <label class="flex items-center">
          <input
            v-model="enableApplePay"
            type="checkbox"
            class="form-checkbox h-4 w-4 text-woot-600"
          />
          <span class="ml-2 text-sm text-slate-700 dark:text-slate-300">
            {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.ENABLE_APPLE_PAY') }}
          </span>
        </label>
      </div>
    </div>
    
    <div class="medium-3 columns">
      <div class="channel-info-wrap">
        <div class="info-element">
          <thumbnail
            :src="channelLogo"
            size="50px"
            :username="channelName"
            variant="square"
          />
          <div class="channel-name">{{ channelName }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleMessagesForBusinessSettings',
  props: {
    channelItem: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      businessId: '',
      teamId: '',
      keyId: '',
      privateKey: '',
      imessageExtensionBid: '',
      enableInteractiveMessages: true,
      enableApplePay: false,
      businessIdError: '',
      teamIdError: '',
      keyIdError: '',
      privateKeyError: '',
      imessageExtensionBidError: '',
    };
  },
  computed: {
    channelName() {
      return 'Apple Messages for Business';
    },
    channelLogo() {
      return '/assets/channels/apple_messages_for_business.png';
    },
  },
  mounted() {
    if (this.channelItem && this.channelItem.provider_config) {
      const config = this.channelItem.provider_config;
      this.businessId = config.business_id || '';
      this.teamId = config.team_id || '';
      this.keyId = config.key_id || '';
      this.privateKey = config.private_key || '';
      this.imessageExtensionBid = config.imessage_extension_bid || '';
      this.enableInteractiveMessages = config.enable_interactive_messages !== false;
      this.enableApplePay = config.enable_apple_pay || false;
    }
  },
  methods: {
    validateBusinessId() {
      if (!this.businessId) {
        this.businessIdError = this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.BUSINESS_ID.ERROR');
      } else {
        this.businessIdError = '';
      }
    },
    validateTeamId() {
      if (!this.teamId) {
        this.teamIdError = this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.TEAM_ID.ERROR');
      } else {
        this.teamIdError = '';
      }
    },
    validateKeyId() {
      if (!this.keyId) {
        this.keyIdError = this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.KEY_ID.ERROR');
      } else {
        this.keyIdError = '';
      }
    },
    validatePrivateKey() {
      if (!this.privateKey) {
        this.privateKeyError = this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PRIVATE_KEY.ERROR');
      } else if (!this.privateKey.includes('BEGIN PRIVATE KEY')) {
        this.privateKeyError = this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PRIVATE_KEY.INVALID');
      } else {
        this.privateKeyError = '';
      }
    },
    validateImessageExtensionBid() {
      if (!this.imessageExtensionBid) {
        this.imessageExtensionBidError = this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_EXTENSION_BID.ERROR');
      } else {
        this.imessageExtensionBidError = '';
      }
    },
  },
};
</script>
```

### 1.2 Channel Creation Component
```vue
<!-- app/javascript/dashboard/routes/dashboard/settings/inbox/channels/AddAppleMessagesForBusiness.vue -->
<template>
  <div class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.DESC')"
    />
    
    <form class="mx-0 flex-grow-0 flex-shrink-0" @submit.prevent="createChannel">
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <apple-messages-for-business-settings
          ref="appleMessagesSettings"
          :channel-item="channelItem"
        />
        
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.CHANNEL_NAME.PLACEHOLDER')"
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.CHANNEL_NAME.ERROR') }}
          </span>
        </label>
        
        <label :class="{ error: $v.webhookUrl.$error }">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.WEBHOOK_URL.LABEL') }}
          <input
            v-model.trim="webhookUrl"
            type="text"
            readonly
            :placeholder="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.WEBHOOK_URL.PLACEHOLDER')"
          />
          <span class="help-text">
            {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.WEBHOOK_URL.HELP_TEXT') }}
          </span>
        </label>
        
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.CREATE_CHANNEL')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required } from 'vuelidate/lib/validators';
import AppleMessagesForBusinessSettings from './AppleMessagesForBusiness.vue';
import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';

export default {
  name: 'AddAppleMessagesForBusiness',
  components: {
    AppleMessagesForBusinessSettings,
    PageHeader,
  },
  data() {
    return {
      channelName: '',
      channelItem: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    webhookUrl() {
      return `${window.location.origin}/webhooks/apple_messages_for_business`;
    },
  },
  validations: {
    channelName: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      
      const settings = this.$refs.appleMessagesSettings;
      
      // Validate all settings
      settings.validateBusinessId();
      settings.validateTeamId();
      settings.validateKeyId();
      settings.validatePrivateKey();
      settings.validateImessageExtensionBid();
      
      if (
        settings.businessIdError ||
        settings.teamIdError ||
        settings.keyIdError ||
        settings.privateKeyError ||
        settings.imessageExtensionBidError
      ) {
        return;
      }
      
      try {
        const appleMessagesForBusinessChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName,
            channel: {
              type: 'apple_messages_for_business',
              business_id: settings.businessId,
              team_id: settings.teamId,
              key_id: settings.keyId,
              private_key: settings.privateKey,
              imessage_extension_bid: settings.imessageExtensionBid,
              enable_interactive_messages: settings.enableInteractiveMessages,
              enable_apple_pay: settings.enableApplePay,
            },
          }
        );
        
        router.push({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: appleMessagesForBusinessChannel.id,
          },
        });
      } catch (error) {
        this.$store.dispatch('alerts/show', {
          message: this.$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.API.ERROR_MESSAGE'),
        });
      }
    },
  },
};
</script>
```

## 2. Message Bubble Components

### 2.1 Apple List Picker Bubble
```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/AppleListPicker.vue -->
<template>
  <div class="apple-list-picker-bubble">
    <div class="received-message" v-if="contentAttributes.received_message">
      <div class="message-header">
        <h4 class="title">{{ contentAttributes.received_message.title }}</h4>
        <p v-if="contentAttributes.received_message.subtitle" class="subtitle">
          {{ contentAttributes.received_message.subtitle }}
        </p>
      </div>
    </div>
    
    <div class="list-picker-content">
      <div
        v-for="(section, sectionIndex) in sections"
        :key="sectionIndex"
        class="picker-section"
      >
        <h5 v-if="section.title" class="section-title">{{ section.title }}</h5>
        
        <div class="section-items">
          <div
            v-for="item in section.items"
            :key="item.identifier"
            class="picker-item"
            :class="{ 'selected': isItemSelected(item.identifier) }"
            @click="toggleItem(section, item)"
          >
            <div class="item-content">
              <div class="item-text">
                <span class="item-title">{{ item.title }}</span>
                <span v-if="item.subtitle" class="item-subtitle">{{ item.subtitle }}</span>
              </div>
              
              <div v-if="section.multipleSelection" class="checkbox-container">
                <input
                  type="checkbox"
                  :checked="isItemSelected(item.identifier)"
                  class="item-checkbox"
                  readonly
                />
              </div>
              <div v-else class="radio-container">
                <input
                  type="radio"
                  :name="`section-${sectionIndex}`"
                  :checked="isItemSelected(item.identifier)"
                  class="item-radio"
                  readonly
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-if="hasSelections" class="selection-summary">
      <p class="summary-text">
        {{ $t('CONVERSATION.APPLE_LIST_PICKER.SELECTIONS_MADE', { count: selectedItems.length }) }}
      </p>
      <div class="selected-items">
        <span
          v-for="item in selectedItemsDisplay"
          :key="item.identifier"
          class="selected-item-tag"
        >
          {{ item.title }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleListPicker',
  props: {
    contentAttributes: {
      type: Object,
      required: true,
    },
    isIncoming: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedItems: [],
    };
  },
  computed: {
    sections() {
      return this.contentAttributes.sections || [];
    },
    hasSelections() {
      return this.selectedItems.length > 0;
    },
    selectedItemsDisplay() {
      return this.selectedItems.map(id => {
        for (const section of this.sections) {
          const item = section.items.find(item => item.identifier === id);
          if (item) return item;
        }
        return null;
      }).filter(Boolean);
    },
  },
  methods: {
    isItemSelected(identifier) {
      return this.selectedItems.includes(identifier);
    },
    toggleItem(section, item) {
      if (!this.isIncoming) return; // Only allow interaction for incoming messages
      
      const identifier = item.identifier;
      const isSelected = this.isItemSelected(identifier);
      
      if (section.multipleSelection) {
        if (isSelected) {
          this.selectedItems = this.selectedItems.filter(id => id !== identifier);
        } else {
          this.selectedItems.push(identifier);
        }
      } else {
        // Single selection - clear other selections in this section first
        const sectionItemIds = section.items.map(item => item.identifier);
        this.selectedItems = this.selectedItems.filter(id => !sectionItemIds.includes(id));
        
        if (!isSelected) {
          this.selectedItems.push(identifier);
        }
      }
      
      this.$emit('selection-changed', {
        selectedItems: this.selectedItems,
        section: section,
        item: item,
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.apple-list-picker-bubble {
  @apply max-w-md bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden;
  
  .received-message {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-b border-slate-200 dark:border-slate-600;
    
    .title {
      @apply text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1;
    }
    
    .subtitle {
      @apply text-sm text-slate-600 dark:text-slate-400;
    }
  }
  
  .list-picker-content {
    @apply p-4;
    
    .picker-section {
      @apply mb-4 last:mb-0;
      
      .section-title {
        @apply text-base font-medium text-slate-900 dark:text-slate-100 mb-3;
      }
      
      .section-items {
        @apply space-y-2;
        
        .picker-item {
          @apply p-3 border border-slate-200 dark:border-slate-600 rounded-lg cursor-pointer transition-colors;
          
          &:hover {
            @apply bg-slate-50 dark:bg-slate-700;
          }
          
          &.selected {
            @apply bg-blue-50 dark:bg-blue-900/20 border-blue-300 dark:border-blue-600;
          }
          
          .item-content {
            @apply flex items-center justify-between;
            
            .item-text {
              @apply flex-1;
              
              .item-title {
                @apply block text-sm font-medium text-slate-900 dark:text-slate-100;
              }
              
              .item-subtitle {
                @apply block text-xs text-slate-600 dark:text-slate-400 mt-1;
              }
            }
            
            .checkbox-container,
            .radio-container {
              @apply ml-3;
              
              input {
                @apply w-4 h-4 text-blue-600 border-slate-300 dark:border-slate-600 rounded;
              }
            }
          }
        }
      }
    }
  }
  
  .selection-summary {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-t border-slate-200 dark:border-slate-600;
    
    .summary-text {
      @apply text-sm font-medium text-slate-900 dark:text-slate-100 mb-2;
    }
    
    .selected-items {
      @apply flex flex-wrap gap-2;
      
      .selected-item-tag {
        @apply px-2 py-1 bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 text-xs rounded-full;
      }
    }
  }
}
</style>
```

### 2.2 Apple Time Picker Bubble
```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/AppleTimePicker.vue -->
<template>
  <div class="apple-time-picker-bubble">
    <div class="received-message" v-if="contentAttributes.received_message">
      <div class="message-header">
        <h4 class="title">{{ contentAttributes.received_message.title }}</h4>
        <p v-if="contentAttributes.received_message.subtitle" class="subtitle">
          {{ contentAttributes.received_message.subtitle }}
        </p>
      </div>
    </div>
    
    <div class="time-picker-content">
      <div v-if="event.title" class="event-info">
        <h5 class="event-title">{{ event.title }}</h5>
      </div>
      
      <div class="timeslots-container">
        <div
          v-for="timeslot in event.timeslots"
          :key="timeslot.identifier"
          class="timeslot-item"
          :class="{ 'selected': selectedTimeslot === timeslot.identifier }"
          @click="selectTimeslot(timeslot)"
        >
          <div class="timeslot-content">
            <div class="time-info">
              <span class="start-time">{{ formatTime(timeslot.startTime) }}</span>
              <span class="duration">{{ formatDuration(timeslot.duration) }}</span>
            </div>
            
            <div class="radio-container">
              <input
                type="radio"
                name="timeslot"
                :checked="selectedTimeslot === timeslot.identifier"
                class="timeslot-radio"
                readonly
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-if="selectedTimeslot" class="selection-summary">
      <p class="summary-text">
        {{ $t('CONVERSATION.APPLE_TIME_PICKER.SELECTED_TIME') }}
      </p>
      <div class="selected-time">
        <span class="selected-time-display">
          {{ formatSelectedTime() }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleTimePicker',
  props: {
    contentAttributes: {
      type: Object,
      required: true,
    },
    isIncoming: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedTimeslot: null,
    };
  },
  computed: {
    event() {
      return this.contentAttributes.event || {};
    },
  },
  methods: {
    selectTimeslot(timeslot) {
      if (!this.isIncoming) return; // Only allow interaction for incoming messages
      
      this.selectedTimeslot = timeslot.identifier;
      
      this.$emit('timeslot-selected', {
        timeslot: timeslot,
        selectedId: timeslot.identifier,
      });
    },
    formatTime(timestamp) {
      const date = new Date(timestamp * 1000);
      return date.toLocaleTimeString([], { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: true 
      });
    },
    formatDuration(seconds) {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      
      if (hours > 0) {
        return `${hours}h ${minutes}m`;
      }
      return `${minutes}m`;
    },
    formatSelectedTime() {
      const selectedSlot = this.event.timeslots.find(
        slot => slot.identifier === this.selectedTimeslot
      );
      
      if (!selectedSlot) return '';
      
      const startTime = this.formatTime(selectedSlot.startTime);
      const duration = this.formatDuration(selectedSlot.duration);
      
      return `${startTime} (${duration})`;
    },
  },
};
</script>

<style lang="scss" scoped>
.apple-time-picker-bubble {
  @apply max-w-md bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden;
  
  .received-message {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-b border-slate-200 dark:border-slate-600;
    
    .title {
      @apply text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1;
    }
    
    .subtitle {
      @apply text-sm text-slate-600 dark:text-slate-400;
    }
  }
  
  .time-picker-content {
    @apply p-4;
    
    .event-info {
      @apply mb-4;
      
      .event-title {
        @apply text-base font-medium text-slate-900 dark:text-slate-100;
      }
    }
    
    .timeslots-container {
      @apply space-y-2;
      
      .timeslot-item {
        @apply p-3 border border-slate-200 dark:border-slate-600 rounded-lg cursor-pointer transition-colors;
        
        &:hover {
          @apply bg-slate-50 dark:bg-slate-700;
        }
        
        &.selected {
          @apply bg-blue-50 dark:bg-blue-900/20 border-blue-300 dark:border-blue-600;
        }
        
        .timeslot-content {
          @apply flex items-center justify-between;
          
          .time-info {
            @apply flex-1;
            
            .start-time {
              @apply block text-sm font-medium text-slate-900 dark:text-slate-100;
            }
            
            .duration {
              @apply block text-xs text-slate-600 dark:text-slate-400 mt-1;
            }
          }
          
          .radio-container {
            @apply ml-3;
            
            input {
              @apply w-4 h-4 text-blue-600 border-slate-300 dark:border-slate-600 rounded-full;
            }
          }
        }
      }
    }
  }
  
  .selection-summary {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-t border-slate-200 dark:border-slate-600;
    
    .summary-text {
      @apply text-sm font-medium text-slate-900 dark:text-slate-100 mb-2;
    }
    
    .selected-time {
      .selected-time-display {
        @apply px-3 py-2 bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 text-sm rounded-lg font-medium;
      }
    }
  }
}
</style>
```

### 2.3 Apple Quick Reply Bubble
```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/AppleQuickReply.vue -->
<template>
  <div class="apple-quick-reply-bubble">
    <div class="summary-text" v-if="contentAttributes.summary_text">
      <p class="text">{{ contentAttributes.summary_text }}</p>
    </div>
    
    <div class="quick-reply-items">
      <button
        v-for="item in items"
        :key="item.identifier"
        class="quick-reply-button"
        :class="{ 'selected': selectedItem === item.identifier }"
        @click="selectItem(item)"
        :disabled="!isIncoming"
      >
        {{ item.title }}
      </button>
    </div>
    
    <div v-if="selectedItem" class="selection-summary">
      <p class="summary-text">
        {{ $t('CONVERSATION.APPLE_QUICK_REPLY.SELECTED') }}
      </p>
      <div class="selected-reply">
        <span class="selected-reply-text">
          {{ getSelectedItemTitle() }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleQuickReply',
  props: {
    contentAttributes: {
      type: Object,
      required: true,
    },
    isIncoming: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedItem: null,
    };
  },
  computed: {
    items() {
      return this.contentAttributes.items || [];
    },
  },
  methods: {
    selectItem(item) {
      if (!this.isIncoming) return; // Only allow interaction for incoming messages
      
      this.selectedItem = item.identifier;
      
      this.$emit('quick-reply-selected', {
        item: item,
        selectedId: item.identifier,
      });
    },
    getSelectedItemTitle() {
      const item = this.items.find(item => item.identifier === this.selectedItem);
      return item ? item.title : '';
    },
  },
};
</script>

<style lang="scss" scoped>
.apple-quick-reply-bubble {
  @apply max-w-md bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden p-4;
  
  .summary-text {
    @apply mb-4;
    
    .text {
      @apply text-sm text-slate-700 dark:text-slate-300;
    }
  }
  
  .quick-reply-items {
    @apply flex flex-wrap gap-2 mb-4;
    
    .quick-reply-button {
      @apply px-4 py-2 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300 text-sm rounde

    
    .picker-section {
      @apply mb-4 last:mb-0;
      
      .section-title {
        @apply text-base font-medium text-slate-900 dark:text-slate-100 mb-3;
      }
      
      .section-items {
        @apply space-y-2;
        
        .picker-item {
          @apply p-3 border border-slate-200 dark:border-slate-600 rounded-lg cursor-pointer transition-colors;
          
          &:hover {
            @apply bg-slate-50 dark:bg-slate-700;
          }
          
          &.selected {
            @apply bg-blue-50 dark:bg-blue-900/20 border-blue-300 dark:border-blue-600;
          }
          
          .item-content {
            @apply flex items-center justify-between;
            
            .item-text {
              @apply flex-1;
              
              .item-title {
                @apply block text-sm font-medium text-slate-900 dark:text-slate-100;
              }
              
              .item-subtitle {
                @apply block text-xs text-slate-600 dark:text-slate-400 mt-1;
              }
            }
            
            .checkbox-container,
            .radio-container {
              @apply ml-3;
              
              input {
                @apply w-4 h-4 text-blue-600 border-slate-300 dark:border-slate-600 rounded;
              }
            }
          }
        }
      }
    }
  }
  
  .selection-summary {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-t border-slate-200 dark:border-slate-600;
    
    .summary-text {
      @apply text-sm font-medium text-slate-900 dark:text-slate-100 mb-2;
    }
    
    .selected-items {
      @apply flex flex-wrap gap-2;
      
      .selected-item-tag {
        @apply px-2 py-1 bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 text-xs rounded-full;
      }
    }
  }
}
</style>
```

### 2.2 Apple Time Picker Bubble
```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/AppleTimePicker.vue -->
<template>
  <div class="apple-time-picker-bubble">
    <div class="received-message" v-if="contentAttributes.received_message">
      <div class="message-header">
        <h4 class="title">{{ contentAttributes.received_message.title }}</h4>
        <p v-if="contentAttributes.received_message.subtitle" class="subtitle">
          {{ contentAttributes.received_message.subtitle }}
        </p>
      </div>
    </div>
    
    <div class="time-picker-content">
      <div v-if="event.title" class="event-info">
        <h5 class="event-title">{{ event.title }}</h5>
      </div>
      
      <div class="timeslots-container">
        <div
          v-for="timeslot in event.timeslots"
          :key="timeslot.identifier"
          class="timeslot-item"
          :class="{ 'selected': selectedTimeslot === timeslot.identifier }"
          @click="selectTimeslot(timeslot)"
        >
          <div class="timeslot-content">
            <div class="time-info">
              <span class="start-time">{{ formatTime(timeslot.startTime) }}</span>
              <span class="duration">{{ formatDuration(timeslot.duration) }}</span>
            </div>
            
            <div class="radio-container">
              <input
                type="radio"
                name="timeslot"
                :checked="selectedTimeslot === timeslot.identifier"
                class="timeslot-radio"
                readonly
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-if="selectedTimeslot" class="selection-summary">
      <p class="summary-text">
        {{ $t('CONVERSATION.APPLE_TIME_PICKER.SELECTED_TIME') }}
      </p>
      <div class="selected-time">
        <span class="selected-time-display">
          {{ formatSelectedTime() }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleTimePicker',
  props: {
    contentAttributes: {
      type: Object,
      required: true,
    },
    isIncoming: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedTimeslot: null,
    };
  },
  computed: {
    event() {
      return this.contentAttributes.event || {};
    },
  },
  methods: {
    selectTimeslot(timeslot) {
      if (!this.isIncoming) return; // Only allow interaction for incoming messages
      
      this.selectedTimeslot = timeslot.identifier;
      
      this.$emit('timeslot-selected', {
        timeslot: timeslot,
        selectedId: timeslot.identifier,
      });
    },
    formatTime(timestamp) {
      const date = new Date(timestamp * 1000);
      return date.toLocaleTimeString([], { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: true 
      });
    },
    formatDuration(seconds) {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      
      if (hours > 0) {
        return `${hours}h ${minutes}m`;
      }
      return `${minutes}m`;
    },
    formatSelectedTime() {
      const selectedSlot = this.event.timeslots.find(
        slot => slot.identifier === this.selectedTimeslot
      );
      
      if (!selectedSlot) return '';
      
      const startTime = this.formatTime(selectedSlot.startTime);
      const duration = this.formatDuration(selectedSlot.duration);
      
      return `${startTime} (${duration})`;
    },
  },
};
</script>

<style lang="scss" scoped>
.apple-time-picker-bubble {
  @apply max-w-md bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden;
  
  .received-message {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-b border-slate-200 dark:border-slate-600;
    
    .title {
      @apply text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1;
    }
    
    .subtitle {
      @apply text-sm text-slate-600 dark:text-slate-400;
    }
  }
  
  .time-picker-content {
    @apply p-4;
    
    .event-info {
      @apply mb-4;
      
      .event-title {
        @apply text-base font-medium text-slate-900 dark:text-slate-100;
      }
    }
    
    .timeslots-container {
      @apply space-y-2;
      
      .timeslot-item {
        @apply p-3 border border-slate-200 dark:border-slate-600 rounded-lg cursor-pointer transition-colors;
        
        &:hover {
          @apply bg-slate-50 dark:bg-slate-700;
        }
        
        &.selected {
          @apply bg-blue-50 dark:bg-blue-900/20 border-blue-300 dark:border-blue-600;
        }
        
        .timeslot-content {
          @apply flex items-center justify-between;
          
          .time-info {
            @apply flex-1;
            
            .start-time {
              @apply block text-sm font-medium text-slate-900 dark:text-slate-100;
            }
            
            .duration {
              @apply block text-xs text-slate-600 dark:text-slate-400 mt-1;
            }
          }
          
          .radio-container {
            @apply ml-3;
            
            input {
              @apply w-4 h-4 text-blue-600 border-slate-300 dark:border-slate-600 rounded-full;
            }
          }
        }
      }
    }
  }
  
  .selection-summary {
    @apply p-4 bg-slate-50 dark:bg-slate-700 border-t border-slate-200 dark:border-slate-600;
    
    .summary-text {
      @apply text-sm font-medium text-slate-900 dark:text-slate-100 mb-2;
    }
    
    .selected-time {
      .selected-time-display {
        @apply px-3 py-2 bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 text-sm rounded-lg font-medium;
      }
    }
  }
}
</style>
```

### 2.3 Apple Quick Reply Bubble
```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/AppleQuickReply.vue -->
<template>
  <div class="apple-quick-reply-bubble">
    <div class="summary-text" v-if="contentAttributes.summary_text">
      <p class="text">{{ contentAttributes.summary_text }}</p>
    </div>
    
    <div class="quick-reply-items">
      <button
        v-for="item in items"
        :key="item.identifier"
        class="quick-reply-button"
        :class="{ 'selected': selectedItem === item.identifier }"
        @click="selectItem(item)"
        :disabled="!isIncoming"
      >
        {{ item.title }}
      </button>
    </div>
    
    <div v-if="selectedItem" class="selection-summary">
      <p class="summary-text">
        {{ $t('CONVERSATION.APPLE_QUICK_REPLY.SELECTED') }}
      </p>
      <div class="selected-reply">
        <span class="selected-reply-text">
          {{ getSelectedItemTitle() }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleQuickReply',
  props: {
    contentAttributes: {
      type: Object,
      required: true,
    },
    isIncoming: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedItem: null,
    };
  },
  computed: {
    items() {
      return this.contentAttributes.items || [];
    },
  },
  methods: {
    selectItem(item) {
      if (!this.isIncoming) return; // Only allow interaction for incoming messages
      
      this.selectedItem = item.identifier;
      
      this.$emit('quick-reply-selected', {
        item: item,
        selectedId: item.identifier,
      });
    },
    getSelectedItemTitle() {
      const item = this.items.find(item => item.identifier === this.selectedItem);
      return item ? item.title : '';
    },
  },
};
</script>

<style lang="scss" scoped>
.apple-quick-reply-bubble {
  @apply max-w-md bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden p-4;
  
  .summary-text {
    @apply mb-4;
    
    .text {
      @apply text-sm text-slate-700 dark:text-slate-300;
    }
  }
  
  .quick-reply-items {
    @apply flex flex-wrap gap-2 mb-4;
    
    .quick-reply-button {
      @apply px-4 py-2 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300 text-sm rounded-lg border border-transparent transition-colors cursor-pointer;
      
      &:hover:not(:disabled) {
        @apply bg-slate-200 dark:bg-slate-600;
      }
      
      &:disabled {
        @apply opacity-50 cursor-not-allowed;
      }
      
      &.selected {
        @apply bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 border-blue-300 dark:border-blue-600;
      }
    }
  }
  
  .selection-summary {
    @apply pt-4 border-t border-slate-200 dark:border-slate-600;
    
    .summary-text {
      @apply text-sm font-medium text-slate-900 dark:text-slate-100 mb-2;
    }
    
    .selected-reply {
      .selected-reply-text {
        @apply px-3 py-2 bg-green-100 dark:bg-green-900/40 text-green-800 dark:text-green-200 text-sm rounded-lg font-medium;
      }
    }
  }
}
</style>
```

## 3. Message Composer Components

### 3.1 Apple Messages Rich Content Composer
```vue
<!-- app/javascript/dashboard/components/widgets/conversation/ReplyBox/AppleMessagesComposer.vue -->
<template>
  <div class="apple-messages-composer">
    <div class="composer-tabs">
      <button
        v-for="tab in availableTabs"
        :key="tab.key"
        class="tab-button"
        :class="{ 'active': activeTab === tab.key }"
        @click="setActiveTab(tab.key)"
      >
        <fluent-icon :icon="tab.icon" size="16" />
        {{ tab.label }}
      </button>
    </div>
    
    <div class="composer-content">
      <!-- Text Message -->
      <div v-if="activeTab === 'text'" class="text-composer">
        <textarea
          v-model="textContent"
          :placeholder="$t('CONVERSATION.APPLE_MESSAGES.TEXT_PLACEHOLDER')"
          class="text-input"
          rows="3"
        />
      </div>
      
      <!-- List Picker -->
      <div v-if="activeTab === 'list_picker'" class="list-picker-composer">
        <woot-input
          v-model="listPicker.receivedMessage.title"
          :label="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.RECEIVED_TITLE')"
          :placeholder="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.RECEIVED_TITLE_PLACEHOLDER')"
        />
        
        <woot-input
          v-model="listPicker.receivedMessage.subtitle"
          :label="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.RECEIVED_SUBTITLE')"
          :placeholder="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.RECEIVED_SUBTITLE_PLACEHOLDER')"
        />
        
        <div class="sections-container">
          <div class="section-header">
            <h4>{{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.SECTIONS') }}</h4>
            <woot-button
              size="small"
              variant="hollow"
              @click="addSection"
            >
              {{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ADD_SECTION') }}
            </woot-button>
          </div>
          
          <div
            v-for="(section, sectionIndex) in listPicker.sections"
            :key="sectionIndex"
            class="section-item"
          >
            <div class="section-controls">
              <woot-input
                v-model="section.title"
                :label="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.SECTION_TITLE')"
                :placeholder="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.SECTION_TITLE_PLACEHOLDER')"
              />
              
              <label class="checkbox-label">
                <input
                  v-model="section.multiple_selection"
                  type="checkbox"
                  class="form-checkbox"
                />
                {{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.MULTIPLE_SELECTION') }}
              </label>
              
              <woot-button
                size="small"
                variant="clear"
                color-scheme="alert"
                @click="removeSection(sectionIndex)"
              >
                {{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.REMOVE_SECTION') }}
              </woot-button>
            </div>
            
            <div class="items-container">
              <div class="items-header">
                <h5>{{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ITEMS') }}</h5>
                <woot-button
                  size="small"
                  variant="hollow"
                  @click="addItem(sectionIndex)"
                >
                  {{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ADD_ITEM') }}
                </woot-button>
              </div>
              
              <div
                v-for="(item, itemIndex) in section.items"
                :key="itemIndex"
                class="item-row"
              >
                <woot-input
                  v-model="item.title"
                  :label="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ITEM_TITLE')"
                  :placeholder="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ITEM_TITLE_PLACEHOLDER')"
                />
                
                <woot-input
                  v-model="item.subtitle"
                  :label="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ITEM_SUBTITLE')"
                  :placeholder="$t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.ITEM_SUBTITLE_PLACEHOLDER')"
                />
                
                <woot-button
                  size="small"
                  variant="clear"
                  color-scheme="alert"
                  @click="removeItem(sectionIndex, itemIndex)"
                >
                  {{ $t('CONVERSATION.APPLE_MESSAGES.LIST_PICKER.REMOVE_ITEM') }}
                </woot-button>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Time Picker -->
      <div v-if="activeTab === 'time_picker'" class="time-picker-composer">
        <woot-input
          v-model="timePicker.receivedMessage.title"
          :label="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.RECEIVED_TITLE')"
          :placeholder="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.RECEIVED_TITLE_PLACEHOLDER')"
        />
        
        <woot-input
          v-model="timePicker.event.title"
          :label="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.EVENT_TITLE')"
          :placeholder="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.EVENT_TITLE_PLACEHOLDER')"
        />
        
        <div class="timeslots-container">
          <div class="timeslots-header">
            <h4>{{ $t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.TIMESLOTS') }}</h4>
            <woot-button
              size="small"
              variant="hollow"
              @click="addTimeslot"
            >
              {{ $t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.ADD_TIMESLOT') }}
            </woot-button>
          </div>
          
          <div
            v-for="(timeslot, index) in timePicker.event.timeslots"
            :key="index"
            class="timeslot-row"
          >
            <woot-input
              v-model="timeslot.start_time"
              type="datetime-local"
              :label="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.START_TIME')"
            />
            
            <woot-input
              v-model="timeslot.duration"
              type="number"
              :label="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.DURATION_MINUTES')"
              :placeholder="$t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.DURATION_PLACEHOLDER')"
            />
            
            <woot-button
              size="small"
              variant="clear"
              color-scheme="alert"
              @click="removeTimeslot(index)"
            >
              {{ $t('CONVERSATION.APPLE_MESSAGES.TIME_PICKER.REMOVE_TIMESLOT') }}
            </woot-button>
          </div>
        </div>
      </div>
      
      <!-- Quick Reply -->
      <div v-if="activeTab === 'quick_reply'" class="quick-reply-composer">
        <woot-input
          v-model="quickReply.summary_text"
          :label="$t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.SUMMARY_TEXT')"
          :placeholder="$t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.SUMMARY_PLACEHOLDER')"
        />
        
        <div class="quick-reply-items-container">
          <div class="items-header">
            <h4>{{ $t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.ITEMS') }}</h4>
            <woot-button
              size="small"
              variant="hollow"
              @click="addQuickReplyItem"
            >
              {{ $t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.ADD_ITEM') }}
            </woot-button>
          </div>
          
          <div
            v-for="(item, index) in quickReply.items"
            :key="index"
            class="quick-reply-item-row"
          >
            <woot-input
              v-model="item.title"
              :label="$t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.ITEM_TITLE')"
              :placeholder="$t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.ITEM_PLACEHOLDER')"
            />
            
            <woot-button
              size="small"
              variant="clear"
              color-scheme="alert"
              @click="removeQuickReplyItem(index)"
            >
              {{ $t('CONVERSATION.APPLE_MESSAGES.QUICK_REPLY.REMOVE_ITEM') }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
    
    <div class="composer-actions">
      <woot-button
        variant="hollow"
        @click="previewMessage"
      >
        {{ $t('CONVERSATION.APPLE_MESSAGES.PREVIEW') }}
      </woot-button>
      
      <woot-button
        @click="sendMessage"
        :disabled="!isValidMessage"
      >
        {{ $t('CONVERSATION.APPLE_MESSAGES.SEND') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppleMessagesComposer',
  props: {
    conversation: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      activeTab: 'text',
      textContent: '',
      listPicker: {
        receivedMessage: {
          title: '',
          subtitle: '',
        },
        sections: [],
      },
      timePicker: {
        receivedMessage: {
          title: '',
        },
        event: {
          title: '',
          timeslots: [],
        },
      },
      quickReply: {
        summary_text: '',
        items: [],
      },
    };
  },
  computed: {
    availableTabs() {
      const tabs = [
        {
          key: 'text',
          label: this.$t('CONVERSATION.APPLE_MESSAGES.TABS.TEXT'),
          icon: 'chat',
        },
      ];
      
      // Only show interactive tabs if channel supports them
      if (this.conversation.inbox.channel.enable_interactive_messages) {
        tabs.push(
          {
            key: 'list_picker',
            label: this.$t('CONVERSATION.APPLE_MESSAGES.TABS.LIST_PICKER'),
            icon: 'list',
          },
          {
            key: 'time_picker',
            label: this.$t('CONVERSATION.APPLE_MESSAGES.TABS.TIME_PICKER'),
            icon: 'calendar',
          },
          {
            key: 'quick_reply',
            label: this.$t('CONVERSATION.APPLE_MESSAGES.TABS.QUICK_REPLY'),
            icon: 'flash',
          }
        );
      }
      
      return tabs;
    },
    isValidMessage() {
      switch (this.activeTab) {
        case 'text':
          return this.textContent.trim().length > 0;
        case 'list_picker':
          return this.listPicker.receivedMessage.title.trim().length > 0 &&
                 this.listPicker.sections.length > 0 &&
                 this.listPicker.sections.every(section => 
                   section.title.trim().length > 0 && section.items.length > 0
                 );
        case 'time_picker':
          return this.timePicker.receivedMessage.title.trim().length > 0 &&
                 this.timePicker.event.timeslots.length > 0;
        case 'quick_reply':
          return this.quickReply.summary_text.trim().length > 0 &&
                 this.quickReply.items.length > 0 &&
                 this.quickReply.items.every(item => item.title.trim().length > 0);
        default:
          return false;
      }
    },
  },
  methods: {
    setActiveTab(tab) {
      this.activeTab = tab;
    },
    
    // List Picker Methods
    addSection() {
      this.listPicker.sections.push({
        title: '',
        multiple_selection: false,
        items: [],
      });
    },
    removeSection(index) {
      this.listPicker.sections.splice(index, 1);
    },
    addItem(sectionIndex) {
      this.listPicker.sections[sectionIndex].items.push({
        title: '',
        subtitle: '',
        identifier: `item_${Date.now()}`,
      });
    },
    removeItem(sectionIndex, itemIndex) {
      this.listPicker.sections[sectionIndex].items.splice(itemIndex, 1);
    },
    
    // Time Picker Methods
    addTimeslot() {
      this.timePicker.event.timeslots.push({
        start_time: '',
        duration: 60,
        identifier: `slot_${Date.now()}`,
      });
    },
    removeTimeslot(index) {
      this.timePicker.event.timeslots.splice(index, 1);
    },
    
    // Quick Reply Methods
    addQuickReplyItem() {
      this.quickReply.items.push({
        title: '',
        identifier: `reply_${Date.now()}`,
      });
    },
    removeQuickReplyItem(index) {
      this.quickReply.items.splice(index, 1);
    },
    
    previewMessage() {
      const messageData = this.buildMessageData();
      this.$emit('preview', messageData);
    },
    
    sendMessage() {
      if (!this.isValidMessage) return;
      
      const messageData = this.buildMessageData();
      this.$emit('send', messageData);
      this.resetComposer();
    },
    
    buildMessageData() {
      switch (this.activeTab) {
        case 'text':
          return {
            content: this.textContent,
            content_type: 'text',
          };
        case 'list_picker':
          return {
            content: this.listPicker.receivedMessage.title,
            content_type: 'apple_list_picker',
            content_attributes: {
              received_message: this.listPicker.receivedMessage,
              sections: this.listPicker.sections.map((section, index) => ({
                ...section,
                items: section.items.map((item, itemIndex) => ({
                  ...item,
                  identifier: item.identifier || `${index}_${itemIndex}`,
                })),
              })),
            },
          };
        case 'time_picker':
          return {
            content: this.timePicker.receivedMessage.title,
            content_type: 'apple_time_picker',
            content_attributes: {
              received_message: this.timePicker.receivedMessage,
              event: {
                ...this.timePicker.event,
                timeslots: this.timePicker.event.timeslots.map((slot, index) => ({
                  ...slot,
                  identifier: slot.identifier || index.toString(),
                  start_time: new Date(slot.start_time).getTime() / 1000,
                  duration: parseInt(slot.duration) * 60, // Convert minutes to seconds
                })),
              },
            },
          };
        case 'quick_reply':
          return {
            content: this.quickReply.summary_text,
            content_type: 'apple_quick_reply',
            content_attributes: {
              summary_text: this.quickReply.summary_text,
              items: this.quickReply.items.map((item, index) => ({
                ...item,
                identifier: item.identifier || (index + 1).toString(),
              })),
            },
          };
        default:
          return {};
      }
    },
    
    resetComposer() {
      this.textContent = '';
      this.listPicker = {
        receivedMessage: { title: '', subtitle: '' },
        sections: [],
      };
      this.timePicker = {
        receivedMessage: { title: '' },
        event: { title: '', timeslots: [] },
      };
      this.quickReply = {
        summary_text: '',
        items: [],
      };
      this.activeTab = 'text';
    },
  },
};
</script>

<style lang="scss" scoped>
.apple-messages-composer {
  @apply border border-slate-200 dark:border-slate-600 rounded-lg overflow-hidden;
  
  .composer-tabs {
    @apply flex border-b border-slate-200 dark:border-slate-600 bg-slate-50 dark:bg-slate-800;
    
    .tab-button {
      @apply px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-400 border-b-2 border-transparent transition-colors flex items-center gap-2;
      
      &:hover {
        @apply text-slate-900 dark:text-slate-100;
      }
      
      &.