<template>
  <div
    class="chat-bubble user"
    :style="{ background: widgetColor }"
    v-html="formatMessage(message)"
  ></div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { mapGetters } from 'vuex';

export default {
  name: 'UserMessageBubble',
  mixins: [messageFormatterMixin],
  props: {
    message: String,
    status: {
      type: String,
      default: '',
    },
    computed: {
      ...mapGetters({
        widgetColor: 'appConfig/getWidgetColor',
      }),
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.chat-bubble {
  @include light-shadow;
  background: $color-woot;
  border-radius: $space-two;
  color: $color-white;
  display: inline-block;
  font-size: $font-size-default;
  line-height: 1.5;
  padding: $space-slab $space-normal $space-slab $space-normal;
  text-align: left;

  > a {
    color: $color-primary;
    word-break: break-all;
  }

  &.user {
    border-bottom-right-radius: $space-smaller;

    > a {
      color: $color-white;
    }
  }
}
</style>
