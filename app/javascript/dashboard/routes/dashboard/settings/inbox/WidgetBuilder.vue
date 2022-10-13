<template>
  <div class="settings--content">
    <div class="widget-builder-conatiner">
      <div class="settings-container">
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
      <div class="widget-container">
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
import Widget from 'dashboard/modules/widget-preview/components/Widget';
import InputRadioGroup from './components/InputRadioGroup';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import {
  LocalStorage,
  LOCAL_STORAGE_KEYS,
} from 'dashboard/helper/localStorage';

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
      return this.$v.websiteName.$error
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
        this.showAlert(
          this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.UPDATE.API.SUCCESS_MESSAGE'
          )
        );
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
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';

.widget-builder-conatiner {
  display: flex;
  flex-direction: row;
  padding: var(--space-one);
  @include breakpoint(900px down) {
    flex-direction: column;
  }
}

.settings-container {
  width: 40%;
  @include breakpoint(900px down) {
    width: 100%;
  }

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
  width: 60%;
  @include breakpoint(900px down) {
    width: 100%;
  }

  .widget-preview {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    min-height: 64rem;
    margin: var(--space-zero) var(--space-two) var(--space-two) var(--space-two);
    padding: var(--space-one) var(--space-one) var(--space-one) var(--space-one);
    background: var(--s-50);

    @include breakpoint(500px down) {
      background: none;
    }
  }
  .widget-script {
    margin: 0 var(--space-two);
    padding: var(--space-one);
    background: var(--s-50);
  }
}
</style>
