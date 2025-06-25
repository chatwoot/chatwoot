<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  components: {},
  props: {
    action: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    isLink() {
      return this.action.type === 'link';
    },
  },
  methods: {
    onClick() {
      if (this.action.type === 'postback') {
        // Send message to parent iframe
        if (IFrameHelper.isIFrame()) {
          IFrameHelper.sendMessage({
            event: 'postback',
            data: { payload: this.action.payload },
          });
        }
      }
    },
  },
};
</script>

<template>
  <a
    v-if="isLink"
    :key="action.uri"
    class="action-button button"
    :href="action.uri"
    :style="{
      background: widgetColor,
      borderColor: widgetColor,
      color: textColor,
    }"
    target="_blank"
    rel="noopener nofollow noreferrer"
  >
    {{ action.text }}
  </a>
  <button
    v-else
    :key="action.payload"
    class="action-button button !bg-n-background dark:!bg-n-alpha-black1 text-n-brand"
    :style="{ borderColor: widgetColor, color: widgetColor }"
    @click="onClick"
  >
    {{ action.text }}
  </button>
</template>

<style scoped lang="scss">
@import 'widget/assets/scss/_variables.scss';

.action-button {
  align-items: center;
  border-radius: $space-micro;
  display: flex;
  font-weight: $font-weight-bold;
  justify-content: center;
  max-height: 34px;
  padding: 0 24px;
}
</style>
