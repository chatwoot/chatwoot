<template>
  <div>
    <div v-if="isWidgetVisible" class="screen-selector">
      <input-radio-group
        name="widget-screen"
        :items="widgetScreens"
        :action="handleScreenChange"
      />
    </div>
    <div v-if="isWidgetVisible" class="widget-wrapper">
      <WidgetHead :config="getWidgetHeadConfig" />
      <WidgetBody :config="getWidgetBodyConfig" />
      <WidgetFooter :config="getWidgetFooterConfig" />
      <div class="branding">
        {{ $t('INBOX_MGMT.WIDGET_BUILDER.BRANDING_TEXT') }}
      </div>
    </div>
    <div
      class="widget-bubble"
      :style="{
        justifyContent: widgetBubblePosition === 'left' ? 'start' : 'end',
      }"
    >
      <button
        class="bubble"
        :class="{
          'bubble-close': isWidgetVisible,
          'bubble-expanded':
            !isWidgetVisible && widgetBubbleType === 'expanded_bubble',
        }"
        :style="{ background: color }"
        @click="toggleWidget"
      >
        <img
          v-if="!isWidgetVisible"
          src="~dashboard/assets/images/bubble-logo.svg"
          alt=""
        />
        <div>
          {{
            isWidgetVisible || widgetBubbleType === 'standard'
              ? ' '
              : widgetBubbleLauncherTitle
          }}
        </div>
      </button>
    </div>
  </div>
</template>

<script>
import WidgetHead from './WidgetHead';
import WidgetBody from './WidgetBody';
import WidgetFooter from './WidgetFooter';
import InputRadioGroup from '../../../routes/dashboard/settings/inbox/components/InputRadioGroup.vue';

export default {
  name: 'Widget',
  components: {
    WidgetHead,
    WidgetBody,
    WidgetFooter,
    InputRadioGroup,
  },
  data: function() {
    return {
      widgetScreens: [
        { id: 'default', title: 'Default', checked: true },
        { id: 'chat', title: 'Chat', checked: false },
      ],
      isDefaultScreen: true,
      isWidgetVisible: true,
    };
  },
  props: {
    welcomeHeading: {
      type: String,
      default: 'Hi There!',
    },
    welcomeTagline: {
      type: String,
      default: '',
    },
    websiteName: {
      type: String,
      default: '',
      required: true,
    },
    logo: {
      type: String,
      default: '',
    },
    isOnline: {
      type: Boolean,
      default: true,
    },
    replyTime: {
      type: String,
      default: 'in_a_few_minutes',
    },
    color: {
      type: String,
      default: '#1f93ff',
    },
    widgetBubblePosition: {
      type: String,
      default: 'left',
    },
    widgetBubbleLauncherTitle: {
      type: String,
      default: 'Chat with us',
    },
    widgetBubbleType: {
      type: String,
      default: 'standard',
    },
  },
  computed: {
    getWidgetHeadConfig() {
      return {
        welcomeHeading: this.welcomeHeading,
        welcomeTagline: this.welcomeTagline,
        websiteName: this.websiteName,
        logo: this.logo,
        isDefaultScreen: this.isDefaultScreen,
        isOnline: this.isOnline,
        replyTime: this.replyTimeText,
        color: this.color,
      };
    },
    getWidgetBodyConfig() {
      return {
        isDefaultScreen: this.isDefaultScreen,
        isOnline: this.isOnline,
        replyTime: this.replyTimeText,
        color: this.color,
      };
    },
    getWidgetFooterConfig() {
      return {
        isDefaultScreen: this.isDefaultScreen,
        color: this.color,
      };
    },
    replyTimeText() {
      switch (this.replyTime) {
        case 'in_a_few_minutes':
          return this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_MINUTES'
          );
        case 'in_a_few_hours':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
        case 'in_a_day':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
      }
    },
  },
  methods: {
    handleScreenChange(item) {
      this.isDefaultScreen = item.id === 'default';
    },
    toggleWidget() {
      this.isWidgetVisible = !this.isWidgetVisible;
      this.isDefaultScreen = true;
    },
  },
};
</script>

<style lang="scss" scoped>
.text-lg {
  font-size: var(--font-size-default);
}
.screen-selector {
  display: flex;
  flex-direction: column;
  align-items: center;
}
.widget-wrapper {
  box-shadow: 0 0px 20px 5px rgb(0 0 0 / 10%);
  border-radius: var(--border-radius-large);
  background-color: rgba(244, 246, 251, 1);
  z-index: 99;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-width: 320px;
  max-width: 320px;
  transition: opacity 0.2s linear, transform 0.25s linear;

  .branding {
    padding-top: 1rem;
    padding-bottom: 1rem;
    text-align: center;
  }
}
.widget-bubble {
  display: flex;
  flex-direction: row;
  margin-top: 15px;
  min-width: 32rem;
  max-width: 32rem;

  .bubble {
    display: flex;
    align-items: center;
    border-radius: 100px;
    border-width: 0px;
    bottom: 20px;
    box-shadow: 0 8px 24px rgb(0 0 0 / 16%) !important;
    cursor: pointer;
    height: 60px;
    width: 60px;
    position: relative;
    top: 0px;
    overflow-wrap: anywhere;

    img {
      height: 25px;
      margin: 10px 8px 5px 17px;
      width: 25px;
    }

    div {
      padding-right: 20px;
    }
  }

  .bubble-close::before,
  .bubble-close::after {
    background-color: #fff;
    content: ' ';
    display: inline;
    height: 24px;
    left: 29px;
    position: absolute;
    top: 18px;
    width: 2px;
  }

  .bubble-close::before {
    transform: rotate(45deg);
  }

  .bubble-close::after {
    transform: rotate(-45deg);
  }

  .bubble-expanded {
    font-size: 16px;
    font-weight: 500;
    color: white;
    width: auto !important;
    height: 48px !important;
  }
}
</style>
