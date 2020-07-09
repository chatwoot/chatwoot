<template>
  <header class="header-expanded">
    <img v-if="avatarUrl" class="logo" :src="avatarUrl" />
    <span class="close close-button" @click="closeWindow"></span>
    <span class="header-elements">
        <h2 class="title" v-html="introHeading"></h2>
        <span class="reply-eta">Usually replys within 1 hour</span>
        <span class="social-links">
            <span class="email">
                <a href="mailto:care@wevrlabs.net" target="_blank" rel="noopener noreferrer">
                    <i class="fas fa-envelope"></i>
                </a>
            </span>
            <span class="whatsapp">
                <a href="https://wa.me/19712514959" target="_blank" rel="noopener noreferrer">
                    <i class="fab fa-whatsapp"></i>
                </a>
            </span>
            <span class="facebook">
                <a href="https://fb.me/WevrLabs" target="_blank" rel="noopener noreferrer">
                    <i class="fab fa-facebook-f"></i>
                </a>
            </span>
            <span class="twitter">
                <a href="https://twitter.com/WevrLabs" target="_blank" rel="noopener noreferrer">
                    <i class="fab fa-twitter"></i>
                </a>
            </span>
        </span>
    </span>
    <p class="body" v-html="introBody"></p>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  name: 'ChatHeaderExpanded',
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    introHeading: {
      type: String,
      default: '',
    },
    introBody: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
  methods: {
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'toggleBubble',
        });
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.header-expanded {
  padding: $space-large $space-medium $space-large;
  width: 100%;
  box-sizing: border-box;
  position: relative;

  .logo {
    width: 56px;
    height: 56px;
  }

  .close {
    position: absolute;
    right: $space-medium;
    top: $space-medium;
    display: none;
  }
  .title {
    color: $color-heading;
    font-size: $font-size-mega;
    font-weight: $font-weight-normal;
    margin-bottom: $space-slab;
    margin-top: $space-medium;
  }
  .reply-eta {
    display: block;
    opacity: .8!important;
    font-size: 11.6px!important;
    line-height: 16px;
    margin: 7px 2px 0;
  }
  .social-links {
    span {
      background: #fff;
      display: inline-block;
      border-radius: 50%;
    }
  }

  .body {
    color: $color-body;
    font-size: 1.8rem;
    line-height: 1.5;
  }
}
</style>
