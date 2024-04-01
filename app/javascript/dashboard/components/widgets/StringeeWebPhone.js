import Cookies from 'js-cookie';
import agents from '../../api/agents';
/* eslint-disable no-undef */
/* eslint-disable no-console */
export default function initStringeeWebPhone(user_id, access_token) {
  var config = {
    showMode: 'full', // full | min | none
    top: '50%',
    left: '50%',
    arrowLeft: 0,
    arrowDisplay: 'none', // top | bottom | none
    fromNumbers: [
      { alias: 'Number-1', number: '+842873018880' },
      { alias: 'Number-2', number: '+842871065445' },
    ],
  };
  StringeeSoftPhone.init(config);

  StringeeSoftPhone.on('displayModeChange', event => {
    console.log('displayModeChange', event);
    if (event === 'min') {
      StringeeSoftPhone.config({ arrowLeft: 75 });
    } else if (event === 'full') {
      StringeeSoftPhone.config({ arrowLeft: 155 });
    }
  });

  StringeeSoftPhone.on('requestNewToken', async () => {
    console.log('requestNewToken+++++++');

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
