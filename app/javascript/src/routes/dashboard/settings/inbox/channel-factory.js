import CONSTANTS from '../../../../constants';
import FacebookView from './Facebook';
import EmailChannel from './EmailChannel';

export default {
  create() {
    return {
      name: 'new-channel-view',
      render(h) {
        if (this.channel_name === CONSTANTS.CHANNELS.FACEBOOK) {
          return h(FacebookView);
        }
        if (this.channel_name === CONSTANTS.CHANNELS.EMAIL) {
          return h(EmailChannel);
        }
        return null;
      },
      props: {
        channel_name: String,
      },
    };
  },
};
