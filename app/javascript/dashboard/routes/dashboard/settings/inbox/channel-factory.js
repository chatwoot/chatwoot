import Facebook from './channels/Facebook';
import Website from './channels/Website';
import Twitter from './channels/Twitter';

const channelViewList = {
  facebook: Facebook,
  website: Website,
  twitter: Twitter,
};

export default {
  create() {
    return {
      props: {
        channel_name: {
          type: String,
          required: true,
        },
      },
      name: 'new-channel-view',
      render(h) {
        return h(channelViewList[this.channel_name] || null);
      },
    };
  },
};
