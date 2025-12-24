<template>
  <div class="mx-8">
    <div class="widget-builder-container">
      <div class="settings-container w-100 lg:w-[40%]">
        <div class="settings-content">
          <form @submit.prevent="updateWidget">
            <woot-avatar-uploader
              :label="
                $t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.AVATAR.LABEL')
              "
              :src="avatarUrl"
              delete-avatar
              @change="handleImageUpload"
              @onAvatarDelete="handleAvatarDelete"
            />
            <woot-avatar-uploader
              :label="'Channel Avatar'"
              :src="channelAvatarUrl"
              delete-avatar
              @change="handleChannelImageUpload"
              @onAvatarDelete="handleChannelAvatarDelete"
            />
            <woot-input
              v-model.trim="websiteName"
              :class="{ error: $v.websiteName.$error }"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WEBSITE_NAME.LABEL'
                )
              "
              :placeholder="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WEBSITE_NAME.PLACE_HOLDER'
                )
              "
              :error="websiteNameValidationErrorMsg"
              @blur="$v.websiteName.$touch"
            />
            <woot-input
              v-model.trim="welcomeHeading"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WELCOME_HEADING.LABEL'
                )
              "
              :placeholder="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WELCOME_HEADING.PLACE_HOLDER'
                )
              "
            />
            <woot-input
              v-model.trim="welcomeTagline"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WELCOME_TAGLINE.LABEL'
                )
              "
              :placeholder="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WELCOME_TAGLINE.PLACE_HOLDER'
                )
              "
            />
            <label class="w-full">
              Back populate previous conversation messages
              <select v-model="backPopulateConversationMessages">
                <option :value="true">
                  {{ 'Enabled' }}
                </option>
                <option :value="false">
                  {{ 'Disabled' }}
                </option>
              </select>
            </label>
            <label class="w-full pb-4">
              Show AI Message Indicators
              <select v-model="showAiMessageIndicators">
                <option :value="true">
                  {{ 'Show' }}
                </option>
                <option :value="false">
                  {{ 'Hide' }}
                </option>
              </select>
            </label>
            <woot-input
              v-model.trim="askQuestionText"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.ASK_QUESTION_TEXT.LABEL'
                )
              "
              :placeholder="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.ASK_QUESTION_TEXT.PLACEHOLDER'
                )
              "
            />
            <label class="w-full pb-4">
              Chat on WhatsApp
              <select v-model="chatOnWhatsappSettings.enabled">
                <option :value="true">
                  {{ 'Enabled' }}
                </option>
                <option :value="false">
                  {{ 'Disabled' }}
                </option>
              </select>
            </label>
            <div
              v-if="chatOnWhatsappSettings.enabled"
              class="chat-on-whatsapp-settings"
            >
              <div class="w-full">
                <label
                  :class="{
                    error: isPhoneNumberNotValid,
                  }"
                >
                  {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.LABEL') }}
                  <woot-phone-input
                    v-model="chatOnWhatsappSettings.phoneNumber"
                    :value="chatOnWhatsappSettings.phoneNumber"
                    :error="isPhoneNumberNotValid"
                    :placeholder="'Whatsapp phone number'"
                    @input="onPhoneNumberInputChange"
                    @blur="$v.chatOnWhatsappSettings.phoneNumber.$touch"
                    @setCode="setPhoneCode"
                  />
                  <span v-if="isPhoneNumberNotValid" class="message">
                    {{ phoneNumberError }}
                  </span>
                </label>
              </div>
              <woot-input
                v-model.trim="chatOnWhatsappSettings.buttonText"
                :class="{ error: $v.chatOnWhatsappSettings.buttonText.$error }"
                :label="'Button text'"
                :placeholder="'Button text'"
                :error="chatOnWhatsappSettingsButtonTextValidationErrorMsg"
                @blur="$v.chatOnWhatsappSettings.buttonText.$touch"
              />
              <woot-input
                v-model.trim="chatOnWhatsappSettings.defaultText"
                :class="{ error: $v.chatOnWhatsappSettings.defaultText.$error }"
                :label="'Default text'"
                :placeholder="'Default text'"
                :error="chatOnWhatsappSettingsDefaultTextValidationErrorMsg"
                @blur="$v.chatOnWhatsappSettings.defaultText.$touch"
              />
            </div>
            <label class="w-full pb-4">
              Default Country for Order Tracking Card
              <select v-model="selectedCountry" class="w-full">
                <option
                  v-for="country in countries"
                  :key="country.id"
                  :value="country.id"
                >
                  {{ country.emoji }} {{ country.name }} ({{
                    country.dial_code
                  }})
                </option>
              </select>
            </label>
            <!-- there can be number of input for faq question and answer. -->
            <div class="faq-section-header">
              <label> FAQs </label>
              <woot-button class="add-faq-button" @click="addFaq">
                Add FAQ
              </woot-button>
            </div>
            <div
              v-for="(faq, index) in faqs"
              :key="index"
              class="faq-container"
            >
              <woot-button
                class="delete-faq-button"
                variant="link"
                size="medium"
                color-scheme="secondary"
                icon="delete"
                class-names="flex justify-end w-4"
                @click="deleteFaq(index)"
              />
              <woot-input
                v-model.trim="faq.question"
                :label="'FAQ Question'"
                :placeholder="'FAQ Question'"
              />
            </div>
            <label>
              {{
                $t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.REPLY_TIME.LABEL')
              }}
              <select v-model="replyTime">
                <option
                  v-for="option in getReplyTimeOptions"
                  :key="option.key"
                  :value="option.value"
                >
                  {{ option.text }}
                </option>
              </select>
            </label>
            <label>
              {{
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_COLOR_LABEL'
                )
              }}
              <woot-color-picker v-model="color" />
            </label>
            <input-radio-group
              name="widget-bubble-position"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION_LABEL'
                )
              "
              :items="widgetBubblePositions"
              :action="handleWidgetBubblePositionChange"
            />
            <input-radio-group
              name="need-help-type"
              :label="'Select need more help button type'"
              :items="needMoreHelpOptions"
              :action="handleNeedMoreHelpChange"
            />
            <input-radio-group
              name="widget-bubble-type"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE_LABEL'
                )
              "
              :items="widgetBubbleTypes"
              :action="handleWidgetBubbleTypeChange"
            />
            <woot-input
              v-model.trim="widgetBubbleLauncherTitle"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.LABEL'
                )
              "
              :placeholder="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.PLACE_HOLDER'
                )
              "
            />
            <woot-submit-button
              class="submit-button"
              :button-text="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.UPDATE.BUTTON_TEXT'
                )
              "
              :loading="uiFlags.isUpdating"
              :disabled="$v.$invalid || uiFlags.isUpdating"
            />
          </form>
        </div>
      </div>
      <div class="widget-container w-100 lg:w-3/5">
        <input-radio-group
          name="widget-view-options"
          :items="getWidgetViewOptions"
          :action="handleWidgetViewChange"
          :style="{ 'text-align': 'center' }"
        />
        <div v-if="isWidgetPreview" class="widget-preview">
          <Widget
            :welcome-heading="welcomeHeading"
            :welcome-tagline="welcomeTagline"
            :website-name="websiteName"
            :logo="avatarUrl"
            is-online
            :reply-time="replyTime"
            :color="color"
            :widget-bubble-position="widgetBubblePosition"
            :widget-bubble-launcher-title="widgetBubbleLauncherTitle"
            :widget-bubble-type="widgetBubbleType"
            :faqs="faqs"
            :channel-avatar-url="channelAvatarUrl"
            :chat-on-whatsapp-settings="chatOnWhatsappSettings"
            :ask-question-text="askQuestionText"
          />
        </div>
        <div v-else class="widget-script">
          <woot-code :script="widgetScript" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Widget from 'dashboard/modules/widget-preview/components/Widget.vue';
import InputRadioGroup from './components/InputRadioGroup.vue';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';
import countries from 'shared/constants/countries';

export default {
  components: {
    Widget,
    InputRadioGroup,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      isWidgetPreview: true,
      color: '#1f93ff',
      websiteName: '',
      welcomeHeading: '',
      welcomeTagline: '',
      replyTime: 'in_a_few_minutes',
      avatarFile: null,
      avatarUrl: '',
      channelAvatarFile: null,
      channelAvatarUrl: '',
      widgetBubblePosition: 'right',
      widgetBubbleLauncherTitle: this.$t(
        'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.DEFAULT'
      ),
      widgetBubbleType: 'standard',
      faqs: [],
      backPopulateConversationMessages: true,
      needMoreHelpType: 'redirect_to_whatsapp',
      needMoreHelpOptions: [],
      widgetBubblePositions: [
        {
          id: 'left',
          title: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION.LEFT'
          ),
          checked: false,
        },
        {
          id: 'right',
          title: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION.RIGHT'
          ),
          checked: true,
        },
      ],
      widgetBubbleTypes: [
        {
          id: 'standard',
          title: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE.STANDARD'
          ),
          checked: true,
        },
        {
          id: 'expanded_bubble',
          title: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE.EXPANDED_BUBBLE'
          ),
          checked: false,
        },
      ],
      chatOnWhatsappSettings: {
        enabled: false,
        buttonText: '',
        defaultText: '',
        phoneNumber: '',
        activeDialCode: '',
      },
      additionalAttributes: {},
      selectedCountry: 'IN',
      countries,
      showAiMessageIndicators: true,
      askQuestionText: 'Ask a question',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    defaultCountryCode() {
      const country = this.countries.find(c => c.id === this.selectedCountry);
      return country ? country.id : 'IN';
    },
    defaultDialCode() {
      const country = this.countries.find(c => c.id === this.selectedCountry);
      return country ? country.dial_code : '+91';
    },
    parsePhoneNumber() {
      return parsePhoneNumber(this.chatOnWhatsappSettings.phoneNumber);
    },
    storageKey() {
      return `${LOCAL_STORAGE_KEYS.WIDGET_BUILDER}${this.inbox.id}`;
    },
    widgetScript() {
      let options = {
        position: this.widgetBubblePosition,
        type: this.widgetBubbleType,
        launcherTitle: this.widgetBubbleLauncherTitle,
      };
      let script = this.inbox.web_widget_script;
      return (
        script.substring(0, 13) +
        this.$t('INBOX_MGMT.WIDGET_BUILDER.SCRIPT_SETTINGS', {
          options: JSON.stringify(options),
        }) +
        script.substring(13)
      );
    },
    getWidgetViewOptions() {
      return [
        {
          id: 'preview',
          title: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_VIEW_OPTION.PREVIEW'
          ),
          checked: true,
        },
        {
          id: 'script',
          title: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_VIEW_OPTION.SCRIPT'
          ),
          checked: false,
        },
      ];
    },
    getReplyTimeOptions() {
      return [
        {
          key: 'in_a_few_minutes',
          value: 'in_a_few_minutes',
          text: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.REPLY_TIME.IN_A_FEW_MINUTES'
          ),
        },
        {
          key: 'in_a_few_hours',
          value: 'in_a_few_hours',
          text: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.REPLY_TIME.IN_A_FEW_HOURS'
          ),
        },
        {
          key: 'in_a_day',
          value: 'in_a_day',
          text: this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.REPLY_TIME.IN_A_DAY'
          ),
        },
      ];
    },
    websiteNameValidationErrorMsg() {
      return this.$v.websiteName.$error
        ? this.$t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WEBSITE_NAME.ERROR')
        : '';
    },
    chatOnWhatsappSettingsButtonTextValidationErrorMsg() {
      return this.$v.chatOnWhatsappSettings.buttonText.$error
        ? 'Please enter a valid button text'
        : '';
    },
    chatOnWhatsappSettingsDefaultTextValidationErrorMsg() {
      return this.$v.chatOnWhatsappSettings.defaultText.$error
        ? 'Please enter a valid text'
        : '';
    },
    isPhoneNumberNotValid() {
      if (this.chatOnWhatsappSettings.phoneNumber !== '') {
        return (
          !isPhoneNumberValid(
            this.chatOnWhatsappSettings.phoneNumber,
            this.chatOnWhatsappSettings.activeDialCode
          ) ||
          (this.chatOnWhatsappSettings.phoneNumber !== ''
            ? this.chatOnWhatsappSettings.activeDialCode === ''
            : false)
        );
      }
      return false;
    },
    phoneNumberError() {
      if (this.chatOnWhatsappSettings.activeDialCode === '') {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
      }
      if (
        !isPhoneNumberValid(
          this.chatOnWhatsappSettings.phoneNumber,
          this.chatOnWhatsappSettings.activeDialCode
        )
      ) {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR');
      }
      return '';
    },
    setPhoneNumber() {
      if (this.parsePhoneNumber && this.parsePhoneNumber.countryCallingCode) {
        return this.chatOnWhatsappSettings.phoneNumber;
      }
      if (
        this.chatOnWhatsappSettings.phoneNumber === '' &&
        this.chatOnWhatsappSettings.activeDialCode !== ''
      ) {
        return '';
      }
      return this.chatOnWhatsappSettings.activeDialCode
        ? `${this.chatOnWhatsappSettings.activeDialCode}${this.chatOnWhatsappSettings.phoneNumber}`
        : '';
    },
  },
  mounted() {
    this.setDefaults();
    this.setDialCode();
  },
  validations() {
    const baseValidations = {
      websiteName: { required },
    };

    if (this.chatOnWhatsappSettings.enabled) {
      baseValidations.chatOnWhatsappSettings = {
        buttonText: { required },
        defaultText: { required },
        phoneNumber: {},
      };
    }

    return baseValidations;
  },
  methods: {
    setDefaults() {
      // Widget Settings
      const {
        name,
        welcome_title,
        welcome_tagline,
        widget_color,
        reply_time,
        avatar_url,
        channel_avatar_url,
        faqs,
        need_more_help_type,
        back_populates_conversation,
        additional_attributes,
      } = this.inbox;
      this.websiteName = name;
      this.welcomeHeading = welcome_title;
      this.welcomeTagline = welcome_tagline;
      this.color = widget_color;
      this.replyTime = reply_time;
      this.avatarUrl = avatar_url;
      this.channelAvatarUrl = channel_avatar_url;
      this.faqs = JSON.parse(faqs);
      this.needMoreHelpType = need_more_help_type;
      this.additionalAttributes = additional_attributes;
      this.chatOnWhatsappSettings.enabled =
        additional_attributes?.chat_on_whatsapp_settings?.enabled || false;
      this.chatOnWhatsappSettings.buttonText =
        additional_attributes?.chat_on_whatsapp_settings?.button_text ||
        'Send Us a Text on WhatsApp';
      this.chatOnWhatsappSettings.defaultText =
        additional_attributes?.chat_on_whatsapp_settings?.default_text ||
        'Hey! I need help with something.';
      this.chatOnWhatsappSettings.phoneNumber =
        additional_attributes?.chat_on_whatsapp_settings?.phone_number || '';
      this.backPopulateConversationMessages = back_populates_conversation;
      this.selectedCountry =
        additional_attributes?.default_country_code || 'IN';
      this.showAiMessageIndicators =
        additional_attributes?.ai_message_settings?.show_indicators !== false;
      this.askQuestionText =
        additional_attributes?.widget_text_settings?.ask_question_text ||
        'Ask a question';

      this.setNeedMoreHelpOptionsData(
        need_more_help_type ?? 'need_more_help_type'
      );

      const savedInformation = this.getSavedInboxInformation();
      if (savedInformation) {
        this.widgetBubblePositions = this.widgetBubblePositions.map(item => {
          if (item.id === savedInformation.position) {
            item.checked = true;
            this.widgetBubblePosition = item.id;
          }
          return item;
        });
        this.widgetBubbleTypes = this.widgetBubbleTypes.map(item => {
          if (item.id === savedInformation.type) {
            item.checked = true;
            this.widgetBubbleType = item.id;
          }
          return item;
        });
        this.widgetBubbleLauncherTitle =
          savedInformation.launcherTitle || 'Chat with us';
      }
    },
    setNeedMoreHelpOptionsData(needMoreHelpType) {
      this.needMoreHelpOptions = [
        {
          id: 'redirect_to_whatsapp',
          title: 'Redirect to whatsapp',
          checked: needMoreHelpType === 'redirect_to_whatsapp',
        },
        {
          id: 'assign_to_agent',
          title: 'Assign to Agent',
          checked: needMoreHelpType === 'assign_to_agent',
        },
      ];
    },
    handleWidgetBubblePositionChange(item) {
      this.widgetBubblePosition = item.id;
    },
    handleNeedMoreHelpChange(item) {
      this.needMoreHelpType = item.id;
    },
    handleWidgetBubbleTypeChange(item) {
      this.widgetBubbleType = item.id;
    },
    handleWidgetViewChange(item) {
      this.isWidgetPreview = item.id === 'preview';
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    handleChannelImageUpload({ file, url }) {
      this.channelAvatarFile = file;
      this.channelAvatarUrl = url;
    },
    async handleAvatarDelete() {
      try {
        await this.$store.dispatch('inboxes/deleteInboxAvatar', this.inbox.id);
        this.avatarFile = null;
        this.avatarUrl = '';
        this.showAlert(
          this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.AVATAR.DELETE.API.SUCCESS_MESSAGE'
          )
        );
      } catch (error) {
        this.showAlert(
          error.message
            ? error.message
            : this.$t(
                'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.AVATAR.DELETE.API.ERROR_MESSAGE'
              )
        );
      }
    },
    async handleChannelAvatarDelete() {
      try {
        await this.$store.dispatch(
          'inboxes/deleteChannelAvatar',
          this.inbox.id
        );
        this.channelAvatarFile = null;
        this.channelAvatarUrl = '';
        this.showAlert('Channel avatar deleted successfully');
      } catch (error) {
        this.showAlert(
          error.message ? error.message : 'Error deleting channel avatar'
        );
      }
    },
    async updateWidget() {
      const bubbleSettings = {
        position: this.widgetBubblePosition,
        launcherTitle: this.widgetBubbleLauncherTitle,
        type: this.widgetBubbleType,
      };

      LocalStorage.set(this.storageKey, bubbleSettings);

      try {
        const payload = {
          id: this.inbox.id,
          name: this.websiteName,
          channel: {
            widget_color: this.color,
            welcome_title: this.welcomeHeading,
            welcome_tagline: this.welcomeTagline,
            reply_time: this.replyTime,
            faqs: JSON.stringify(this.faqs),
            need_more_help_type: this.needMoreHelpType,
            back_populates_conversation: this.backPopulateConversationMessages,
          },
        };
        if (this.avatarFile) {
          payload.avatar = this.avatarFile;
        }
        if (this.channelAvatarFile) {
          payload.channel.avatar = this.channelAvatarFile;
        }
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(
          this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.UPDATE.API.SUCCESS_MESSAGE'
          )
        );
        await this.$store.dispatch('inboxes/updateInboxIMAP', {
          id: this.inbox.id,
          formData: false,
          channel: {
            additional_attributes: {
              ...this.additionalAttributes,
              chat_on_whatsapp_settings: {
                enabled: this.chatOnWhatsappSettings.enabled,
                button_text: this.chatOnWhatsappSettings.buttonText,
                default_text: this.chatOnWhatsappSettings.defaultText,
                phone_number: this.setPhoneNumber,
              },
              ai_message_settings: {
                show_indicators: this.showAiMessageIndicators,
              },
              widget_text_settings: {
                ask_question_text: this.askQuestionText,
              },
              default_country_code: this.defaultCountryCode,
              default_dial_code: this.defaultDialCode,
            },
          },
        });
      } catch (error) {
        this.showAlert(
          error.message ||
            this.$t(
              'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.UPDATE.API.ERROR_MESSAGE'
            )
        );
      }
    },
    getSavedInboxInformation() {
      return LocalStorage.get(this.storageKey);
    },
    addFaq(event) {
      event.preventDefault();
      this.faqs.push({ question: '', answer: '' });
    },
    deleteFaq(index) {
      this.faqs.splice(index, 1);
    },
    onPhoneNumberInputChange(value, code) {
      this.chatOnWhatsappSettings.activeDialCode = code;
    },
    setDialCode() {
      if (
        this.chatOnWhatsappSettings.phoneNumber !== '' &&
        this.parsePhoneNumber &&
        this.parsePhoneNumber.countryCallingCode
      ) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        this.chatOnWhatsappSettings.activeDialCode = `+${dialCode}`;
      }
    },
    setPhoneCode(code) {
      if (
        this.chatOnWhatsappSettings.phoneNumber !== '' &&
        this.parsePhoneNumber
      ) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        this.chatOnWhatsappSettings.activeDialCode = `+${dialCode}`;
        const newPhoneNumber = this.chatOnWhatsappSettings.phoneNumber.replace(
          `+${dialCode}`,
          `${code}`
        );
        this.chatOnWhatsappSettings.phoneNumber = newPhoneNumber;
      } else {
        this.chatOnWhatsappSettings.activeDialCode = code;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';

.widget-builder-container {
  display: flex;
  flex-direction: row;
  padding: var(--space-one);
  // @include breakpoint(900px down) {
  //   flex-direction: column;
  // }
}

.settings-container {
  .settings-content {
    padding: var(--space-normal) var(--space-zero);
    overflow-y: scroll;
    min-height: 100%;

    .submit-button {
      margin-top: var(--space-normal);
    }
  }
}

.widget-container {
  .widget-preview {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    min-height: 40.625rem;
    margin: var(--space-zero) var(--space-two) var(--space-two) var(--space-two);
    padding: var(--space-one) var(--space-one) var(--space-one) var(--space-one);
    @apply bg-slate-50 dark:bg-slate-700;

    // @include breakpoint(500px down) {
    //   background: none;
    // }
  }

  .widget-script {
    @apply mx-5 p-2.5 bg-slate-50 dark:bg-slate-700;
  }
}

.faq-container {
  margin-bottom: var(--space-normal);
  position: relative;
  padding: var(--space-normal);
  border: 1px solid #e0e0e0; // Light border for separation
  border-radius: 4px; // Rounded corners
  background-color: #f9f9f9;
}

.faq-section-header {
  display: flex;
  align-items: center; // Aligns items vertically centered
  justify-content: space-between; // Space between title and button
  margin-bottom: var(--space-normal); // Space below the header
}

.add-faq-button {
  margin-left: var(--space-normal);
  background-color: transparent !important  ;
  padding: 0;
  cursor: pointer;
  color: #1f93ff !important;
}

.delete-faq-button {
  position: absolute;
  right: 5px;
  top: 5px;
}
</style>
