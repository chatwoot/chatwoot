<template>
  <div class="settings--content">
    <div class="widget-builder-conatiner">
      <div class="settings-container">
        <div style="padding: 25px 0px; overflow-y: scroll; min-height: 100%;">
          <woot-input
            v-model.trim="websiteName"
            class="medium-9 columns settings-item"
            label="Website Name"
            placeholder="Website Name"
          />
          <woot-input
            v-model.trim="welcomeTitle"
            class="medium-9 columns settings-item"
            label="Welcome Title"
            placeholder="Welcome Title"
          />
          <woot-input
            v-model.trim="welcomeTagline"
            class="medium-9 columns settings-item"
            label="Welcome Tagline"
            placeholder="Welcome Tagline"
          />
          <label class="medium-9 columns settings-item">
            {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.TITLE') }}
            <select v-model="replyTime">
              <option key="in_a_few_minutes" value="in_a_few_minutes">
                {{
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_MINUTES'
                  )
                }}
              </option>
              <option key="in_a_few_hours" value="in_a_few_hours">
                {{
                  $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_HOURS')
                }}
              </option>
              <option key="in_a_day" value="in_a_day">
                {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_DAY') }}
              </option>
            </select>
          </label>
          <label class="medium-9 columns settings-item">
            Widget Color
            <woot-color-picker v-model="color" />
          </label>
          <input-radio-group
            name="widget-bubble-position"
            label="Widget Bubble Position"
            :items="widgetBubblePositions"
            :action="handleWidgetBubblePositionChange"
          />
          <input-radio-group
            name="widget-bubble-type"
            label="Widget Bubble Types"
            :items="widgetBubbleTypes"
            :action="handleWidgetBubbleTypeChange"
          />
          <woot-input
            v-model.trim="widgetBubbleLauncherText"
            class="medium-9 columns settings-item"
            label="Widget Bubble Launcher Text"
            placeholder="Bubble Launcher Text"
          />
          <woot-submit-button button-text="Update" @click="updateInbox" />
        </div>
      </div>
      <div class="widget-container">
        <input-radio-group
          name="widget-view-options"
          :items="widgetViewOptions"
          :action="handleWidgetViewChange"
          :style="{ 'text-align': 'center' }"
        />
        <div v-if="isWidgetPreview" class="widget-preview">
          <Widget
            :welcome-heading="welcomeTitle"
            :welcome-tagline="welcomeTagline"
            :website-name="websiteName"
            website-domain=""
            :logo="inbox.avatar_url"
            is-online
            :reply-time="replyTime"
            :color="color"
            :widget-bubble-position="widgetBubblePosition"
            :widget-bubble-launcher-text="widgetBubbleLauncherText"
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
import Widget from '../../../../modules/widget-preview/components/Widget';
import InputRadioGroup from './components/InputRadioGroup';
import alertMixin from 'shared/mixins/alertMixin';
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
      widgetViewOptions: [
        { id: 'preview', title: 'Preview', checked: true },
        { id: 'script', title: 'Script', checked: false },
      ],
      widgetBubblePositions: [
        { id: 'left', title: 'Left', checked: false },
        { id: 'right', title: 'Right', checked: true },
      ],
      widgetBubbleTypes: [
        { id: 'standard', title: 'Standard', checked: true },
        { id: 'expanded_bubble', title: 'Expanded Bubble', checked: false },
      ],
      isWidgetPreview: true,
      color: '#1f93ff',
      websiteName: '',
      welcomeTitle: '',
      welcomeTagline: '',
      replyTime: '',
      widgetBubblePosition: 'right',
      widgetBubbleLauncherText: 'Chat with us',
      widgetBubbleType: 'standard',
    };
  },
  mounted: function() {
    this.websiteName = this.inbox.name;
    this.welcomeTitle = this.inbox.welcome_title;
    this.welcomeTagline = this.inbox.welcome_tagline;
    this.color = this.inbox.widget_color;
    this.replyTime = this.inbox.reply_time;
  },
  computed: {
    widgetScript() {
      let options = {
        position: this.widgetBubblePosition,
        type: this.widgetBubbleType,
        launcherTitle: this.widgetBubbleLauncherText,
        darkMode: 'auto',
      };
      let script = this.inbox.web_widget_script;
      return (
        script.substring(0, 13) +
        this.$t('INBOX_MGMT.WIDGET_BUILDER.SCRIPT_SETTINGS', {
          options: JSON.stringify(options),
        }) +
        script.substring(13, script.length)
      );
    },
  },
  methods: {
    handleWidgetBubblePositionChange: function(item) {
      this.widgetBubblePosition = item.id;
    },
    handleWidgetBubbleTypeChange(item) {
      this.widgetBubbleType = item.id;
    },
    handleWidgetViewChange(item) {
      this.isWidgetPreview = item.id === 'preview';
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          name: this.websiteName,
          channel: {
            widget_color: this.color,
            welcome_title: this.welcomeTitle || '',
            welcome_tagline: this.welcomeTagline || '',
            reply_time: this.replyTime || 'in_a_few_minutes',
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(
          error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';

.widget-builder-conatiner {
  display: flex;
  flex-direction: row;
  @include breakpoint(900px down) {
    flex-direction: column;
  }
}

.settings-container {
  width: 50%;
  @include breakpoint(900px down) {
    width: 100%;
  }
}
.widget-container {
  width: 50%;
  @include breakpoint(900px down) {
    width: 100%;
  }

  .widget-preview {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    min-height: 63rem;
    margin: 0 2rem 2rem 2rem;
    padding: 0 1rem 1rem 1rem;
    background: var(--s-50);

    @include breakpoint(500px down) {
      background: none;
    }
  }
  .widget-script {
    margin: 2rem 2rem;
    padding: 1rem;
    background: var(--s-50);
  }
}
</style>
