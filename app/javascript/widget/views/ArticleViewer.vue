<template>
  <div class="bg-white h-full">
    <iframe-loader :url="link" />
  </div>
</template>

<script>
import { IFrameHelper } from 'widget/helpers/utils';
import IframeLoader from 'shared/components/IframeLoader';

export default {
  name: 'Campaigns',
  components: {
    IframeLoader,
  },
  props: {
    link: {
      type: String,
      default: '',
    },
  },
  methods: {
    closeFullView() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'setCampaignReadOn',
        });
        IFrameHelper.sendMessage({ event: 'toggleBubble' });
        bus.$emit('snooze-campaigns');
      }
    },
  },
};
</script>
