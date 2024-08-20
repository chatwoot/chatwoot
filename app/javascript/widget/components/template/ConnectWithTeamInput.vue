<template>
  <div class="connect-with-team-input">
    <button
      v-if="!hasSubmitted"
      class="button small"
      :style="{
        background: widgetColor,
        borderColor: widgetColor,
        color: textColor,
      }"
      @click="connectWithTeam"
    >
      Yes
    </button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  mixins: [darkModeMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    messageContentAttributes: {
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
    hasSubmitted() {
      return (
        this.messageContentAttributes &&
        this.messageContentAttributes.connect_with_team
      );
    },
  },
  methods: {
    async connectWithTeam() {
      try {
        await this.$store.dispatch('message/connect_with_team', {
          connect: 'connect with team',
          messageId: this.messageId,
        });
      } catch (error) {
        // Ignore error
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.connect-with-team-input {
  display: flex;
  margin: $space-small 0;
  min-width: 100px;

  .button {
    padding: $space-one;
    width: 100%;
    font-size: $font-size-small;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 5px;
    margin-right: 2px;
  }
}
</style>
