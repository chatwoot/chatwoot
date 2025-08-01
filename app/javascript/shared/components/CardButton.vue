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
    index: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      // Use a fallback color if widgetColor is undefined
      const color = this.widgetColor || '#1f2937'; // fallback to a dark gray
      return getContrastingTextColor(color);
    },
    buttonText() {
      // Use provided action.text if available. Otherwise, default to 'Explore' for the first button and 'Buy now' for the second.
      if (this.action.text) return this.action.text;
      // index 0: first button, index 1: second button
      return this.index === 1 ? 'Buy now' : 'Explore';
    },
    isLink() {
      return this.action.type === 'url';
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
    {{ buttonText }}
  </a>
  <button
    v-else
    :key="action.payload"
    class="action-button button !bg-n-background dark:!bg-n-alpha-black1 text-n-brand"
    :style="{ borderColor: widgetColor, color: widgetColor }"
    @click="onClick"
  >
    {{ buttonText }}
  </button>
</template>

<style scoped lang="scss">
.action-button {
  @apply items-center rounded-lg flex font-medium justify-center mt-1 p-0 w-full;
}
.action-button.button {
  background: #1976d2 !important; /* Modern blue */
  color: #fff !important;          /* White text */
  border: none !important;
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: 600;
  font-size: 1rem;
  transition: background 0.2s;
  white-space: nowrap;
}
.action-button.button:hover {
  background: #1565c0 !important;
}
</style>
