<template>
  <div class="widget-preview-container">
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
    <div class="widget-bubble" :style="getBubblePositionStyle">
      <button
        class="bubble"
        :class="getBubbleTypeClass"
        :style="{ background: color }"
        @click="toggleWidget"
      >
        <img
          v-if="!isWidgetVisible"
          src="~dashboard/assets/images/bubble-logo.svg"
          alt=""
        />
        <div>
          {{ getWidgetBubbleLauncherTitle }}
        </div>
      </button>
    </div>
  </div>
</template>

<script>
import WidgetHead from './WidgetHead';
import WidgetBody from './WidgetBody';
import WidgetFooter from './WidgetFooter';
import InputRadioGroup from 'dashboard/routes/dashboard/settings/inbox/components/InputRadioGroup';

export default {
  name: 'Widget',
  components: {
    WidgetHead,
    WidgetBody,
    WidgetFooter,
    InputRadioGroup,
  },
  props: {
    welcomeHeading: {
      type: String,
      default: '',
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
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    widgetBubblePosition: {
      type: String,
      default: '',
    },
    widgetBubbleLauncherTitle: {
      type: String,
      default: '',
    },
    widgetBubbleType: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      widgetScreens: [
        {
          id: 'default',
          title: this.$t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_SCREEN.DEFAULT'),
          checked: true,
        },
        {
          id: 'chat',
          title: this.$t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_SCREEN.CHAT'),
          checked: false,
        },
      ],
      isDefaultScreen: true,
      isWidgetVisible: true,
    };
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
        welcomeHeading: this.welcomeHeading,
        welcomeTagline: this.welcomeTagline,
        isDefaultScreen: this.isDefaultScreen,
        isOnline: this.isOnline,
        replyTime: this.replyTimeText,
        color: this.color,
        logo: this.logo,
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
        case 'in_a_day':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
      }
    },
    getBubblePositionStyle() {
      return {
        justifyContent: this.widgetBubblePosition === 'left' ? 'start' : 'end',
      };
    },
    getBubbleTypeClass() {
      return {
        'bubble-close': this.isWidgetVisible,
        'bubble-expanded':
          !this.isWidgetVisible && this.widgetBubbleType === 'expanded_bubble',
      };
    },
    getWidgetBubbleLauncherTitle() {
      return this.isWidgetVisible || this.widgetBubbleType === 'standard'
        ? ' '
        : this.widgetBubbleLauncherTitle;
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
.screen-selector {
  display: flex;
  flex-direction: column;
  align-items: center;
}
.widget-wrapper {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-shadow: 0 0px 20px 5px rgb(0 0 0 / 10%);
  border-radius: var(--border-radius-large);
  background-color: #f4f6fb;
  min-width: calc(var(--space-large) * 10);
  max-width: calc(var(--space-large) * 10);
  min-height: calc(var(--space-giga) * 2);

  .branding {
    padding-top: var(--space-one);
    padding-bottom: var(--space-one);
    text-align: center;
  }
}
.widget-bubble {
  display: flex;
  flex-direction: row;
  margin-top: var(--space-normal);
  min-width: calc(var(--space-large) * 10);
  max-width: calc(var(--space-large) * 10);

  .bubble {
    display: flex;
    align-items: center;
    border-radius: calc(var(--border-radius-small) * 10);
    height: calc(var(--space-three) * 2);
    width: calc(var(--space-three) * 2);
    position: relative;
    overflow-wrap: anywhere;
    cursor: pointer;

    img {
      height: var(--space-medium);
      width: var(--space-medium);
      margin: var(--space-one) var(--space-one) calc(var(--space-micro) * 3)
        var(--space-normal);
    }

    div {
      padding-right: var(--space-normal);
    }
  }

  .bubble-close::before,
  .bubble-close::after {
    background-color: var(--white);
    content: ' ';
    display: inline;
    height: var(--space-medium);
    width: var(--space-micro);
    left: var(--space-three);
    position: absolute;
  }

  .bubble-close::before {
    transform: rotate(45deg);
  }

  .bubble-close::after {
    transform: rotate(-45deg);
  }

  .bubble-expanded {
    font-size: var(--font-size-default);
    font-weight: var(--font-weight-medium);
    color: var(--white);
    width: auto !important;
    height: var(--space-larger) !important;
  }
}
</style>
