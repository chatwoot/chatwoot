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
      <div>
        <WidgetBody :config="getWidgetBodyConfig" />
        <WidgetFooter :config="getWidgetFooterConfig" />
        <div class="branding">
          <a class="branding-link">
            <img class="branding-image" :src="globalConfig.logoThumbnail" />
            <span>{{ $t('INBOX_MGMT.WIDGET_BUILDER.BRANDING_TEXT') }}</span>
          </a>
        </div>
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

const { LOGO_THUMBNAIL: logoThumbnail } = window.globalConfig || {};

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
      globalConfig: {
        logoThumbnail,
      },
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
  box-shadow: var(--shadow-widget-builder);
  border-radius: var(--border-radius-large);
  background-color: #f4f6fb;
  width: calc(var(--space-large) * 10);
  height: calc(var(--space-mega) * 5);

  .branding {
    padding-top: var(--space-one);
    padding-bottom: var(--space-one);
    display: flex;
    justify-content: center;

    .branding-link {
      display: flex;
      flex-direction: row;
      align-items: center;
      color: var(--b-500);
      cursor: pointer;
      filter: grayscale(1);
      font-size: var(--font-size-micro);
      opacity: 0.9;
      text-decoration: none;

      &:hover {
        filter: grayscale(0);
        opacity: 1;
        color: var(--b-600);
      }

      .branding-image {
        max-width: var(--space-one);
        max-height: var(--space-one);
        margin-right: var(--space-micro);
      }
    }
  }
}
.widget-bubble {
  display: flex;
  flex-direction: row;
  margin-top: var(--space-normal);
  width: calc(var(--space-large) * 10);

  .bubble {
    display: flex;
    align-items: center;
    border-radius: calc(var(--border-radius-small) * 10);
    height: calc(var(--space-large) * 2);
    width: calc(var(--space-large) * 2);
    position: relative;
    overflow-wrap: anywhere;
    cursor: pointer;

    img {
      height: var(--space-two);
      width: var(--space-two);
      margin: var(--space-one) var(--space-one) var(--space-one)
        var(--space-two);
    }

    div {
      padding-right: var(--space-two);
    }
  }

  .bubble-close::before,
  .bubble-close::after {
    background-color: var(--white);
    content: ' ';
    display: inline;
    height: var(--space-medium);
    width: var(--space-micro);
    left: var(--space-large);
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
