<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Widget from 'dashboard/modules/widget-preview/components/Widget.vue';
import InputRadioGroup from './components/InputRadioGroup.vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Widget,
    InputRadioGroup,
    NextButton,
  },
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  setup() {
    return { v$: useVuelidate() };
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
      widgetBubblePosition: 'right',
      widgetBubbleLauncherTitle: this.$t(
        'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.DEFAULT'
      ),
      widgetBubbleType: 'standard',
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
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
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
      return this.v$.websiteName.$error
        ? this.$t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WEBSITE_NAME.ERROR')
        : '';
    },
  },
  mounted() {
    this.setDefaults();
  },
  validations: {
    websiteName: { required },
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
      } = this.inbox;
      this.websiteName = name;
      this.welcomeHeading = welcome_title;
      this.welcomeTagline = welcome_tagline;
      this.color = widget_color;
      this.replyTime = reply_time;
      this.avatarUrl = avatar_url;

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
    handleWidgetBubblePositionChange(item) {
      this.widgetBubblePosition = item.id;
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
    async handleAvatarDelete() {
      try {
        await this.$store.dispatch('inboxes/deleteInboxAvatar', this.inbox.id);
        this.avatarFile = null;
        this.avatarUrl = '';
        useAlert(
          this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.AVATAR.DELETE.API.SUCCESS_MESSAGE'
          )
        );
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t(
                'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.AVATAR.DELETE.API.ERROR_MESSAGE'
              )
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
          },
        };
        if (this.avatarFile) {
          payload.avatar = this.avatarFile;
        }
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(
          this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.UPDATE.API.SUCCESS_MESSAGE'
          )
        );
      } catch (error) {
        useAlert(
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
  },
};
</script>

<template>
  <div class="mx-8">
    <div class="flex p-2.5">
      <div class="w-100 lg:w-[40%]">
        <div class="min-h-full py-4 overflow-y-scroll px-px">
          <form @submit.prevent="updateWidget">
            <woot-avatar-uploader
              :label="
                $t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.AVATAR.LABEL')
              "
              :src="avatarUrl"
              delete-avatar
              @on-avatar-select="handleImageUpload"
              @on-avatar-delete="handleAvatarDelete"
            />
            <woot-input
              v-model="websiteName"
              :class="{ error: v$.websiteName.$error }"
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
              @blur="v$.websiteName.$touch"
            />
            <woot-input
              v-model="welcomeHeading"
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
              v-model="welcomeTagline"
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
            <InputRadioGroup
              name="widget-bubble-position"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION_LABEL'
                )
              "
              :items="widgetBubblePositions"
              :action="handleWidgetBubblePositionChange"
            />
            <InputRadioGroup
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
              v-model="widgetBubbleLauncherTitle"
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
            <NextButton
              type="submit"
              class="mt-4"
              :label="
                $t(
                  'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.UPDATE.BUTTON_TEXT'
                )
              "
              :is-loading="uiFlags.isUpdating"
              :disabled="v$.$invalid || uiFlags.isUpdating"
            />
          </form>
        </div>
      </div>
      <div class="w-100 lg:w-3/5">
        <InputRadioGroup
          name="widget-view-options"
          class="text-center"
          :items="getWidgetViewOptions"
          :action="handleWidgetViewChange"
        />
        <div
          v-if="isWidgetPreview"
          class="flex flex-col items-center justify-end min-h-[40.625rem] mx-5 mb-5 p-2.5 bg-slate-50 dark:bg-slate-900/50 rounded-lg"
        >
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
          />
        </div>
        <div
          v-else
          class="mx-5 p-2.5 bg-n-slate-3 rounded-lg dark:bg-n-solid-3"
        >
          <woot-code :script="widgetScript" />
        </div>
      </div>
    </div>
  </div>
</template>
