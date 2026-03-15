<script>
import { defineComponent, h } from 'vue';
import Facebook from './channels/Facebook.vue';
import Website from './channels/Website.vue';
import Twitter from './channels/Twitter.vue';
import Api from './channels/Api.vue';
import Email from './channels/Email.vue';
import Whatsapp from './channels/Whatsapp.vue';
import Telegram from './channels/Telegram.vue';
import Instagram from './channels/Instagram.vue';
import Tiktok from './channels/Tiktok.vue';

const channelViewList = {
  facebook: Facebook,
  website: Website,
  twitter: Twitter,
  api: Api,
  email: Email,
  whatsapp: Whatsapp,
  telegram: Telegram,
  instagram: Instagram,
  tiktok: Tiktok,
};

export default defineComponent({
  name: 'NewChannelView',
  props: {
    channelName: {
      type: String,
      required: true,
    },
  },
  render() {
    const ChannelComponent = channelViewList[this.channelName];
    return ChannelComponent ? h(ChannelComponent) : null;
  },
});
</script>
