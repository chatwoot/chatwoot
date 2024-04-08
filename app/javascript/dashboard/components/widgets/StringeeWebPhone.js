import Cookies from 'js-cookie';
import agents from '../../api/agents';
import conversations from '../../api/conversations';

/* eslint-disable no-undef */
/* eslint-disable no-console */
export default function initStringeeWebPhone(
  user_id,
  access_token,
  fromNumbers
) {
  var config = {
    showMode: 'none', // full | min | none
    top: '50%',
    left: '50%',
    arrowLeft: 0,
    arrowDisplay: 'none', // top | bottom | none
    fromNumbers: fromNumbers,
  };
  StringeeSoftPhone.init(config);

  StringeeSoftPhone.on('displayModeChange', event => {
    if (event === 'min') {
      StringeeSoftPhone.config({ arrowLeft: 75 });
    } else if (event === 'full') {
      StringeeSoftPhone.config({ arrowLeft: 155 });
    }
  });

  StringeeSoftPhone.on('declineIncomingCallBtnClick', () => {
    console.log('declineIncomingCallBtnClick');
    StringeeSoftPhone.config({ showMode: 'none' });
  });

  StringeeSoftPhone.on('endCallBtnClick', () => {
    console.log('endCallBtnClick');
    StringeeSoftPhone.config({ showMode: 'none' });
  });

  StringeeSoftPhone.on('signalingstate', state => {
    console.log('signalingstate', state);
    if (state.code === 5 || state.code === 6)
      StringeeSoftPhone.config({ showMode: 'none' });
  });

  StringeeSoftPhone.on('incomingCall', async incomingcall => {
    window.onbeforeunload = () => {
      // Do nothing to bypass the default confirmation to leave site in browser
    };
    try {
      const response = await conversations.findByMessage(incomingcall.callId);
      const displayId = response.data.display_id;
      const accountId = window.location.pathname.split('/')[3];

      const url = `/app/accounts/${accountId}/conversations/${displayId}`;
      if (!window.location.href.endsWith(url)) window.location.href = url;
    } catch (error) {
      console.error('Error opening contact page:', error);
    }
  });

  StringeeSoftPhone.on('requestNewToken', async () => {
    try {
      const response = await agents.newStringeeToken(user_id);
      const newToken = response.data.token;

      Cookies.set('stringee_access_token', newToken);

      StringeeSoftPhone.connect(newToken);
    } catch (error) {
      console.error('Error requesting new token:', error);
    }
  });

  StringeeSoftPhone.connect(access_token);
}
