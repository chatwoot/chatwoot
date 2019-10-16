import CONSTANTS from '../../../../constants';
import FacebookView from './Facebook';

export default {
  create() {
    return {
      name: 'new-channel-view',

      render(h) {
        if (this.channel_name === CONSTANTS.CHANNELS.FACEBOOK) {
          return h(FacebookView);
        }
        return null;
      },
      props: {
        channel_name: String,
      },
    };
  },
};
