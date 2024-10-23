<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import ChatbotAPIClient from 'widget/api/chatbot';

import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  components: {
    FluentIcon,
  },
  mixins: [darkModeMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return { isLoading: false };
  },
  computed: {
    ...mapGetters({ widgetColor: 'appConfig/getWidgetColor' }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
  methods: {
    async onSubmit() {
      this.isLoading = true;
      try {
        await ChatbotAPIClient.connectWithTeam(this.messageId);
      } catch (error) {
        // Ignore Error for now
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <button
      class="button connect-button"
      color-scheme="secondary"
      :is-loading="isLoading"
      :style="{
        background: widgetColor,
        borderColor: widgetColor,
        color: textColor,
      }"
      @click="onSubmit"
    >
      <FluentIcon icon="arrow-right" class="mr-2" />
      {{ $t('INTEGRATIONS.DYTE.CLICK_HERE_TO_JOIN') }}
    </button>
  </div>
</template>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.connect-button {
  margin: $space-small 0;
  border-radius: 4px;
  display: flex;
  align-items: center;
}
</style>
