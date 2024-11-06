import Cookies from 'js-cookie';
import agents from '../../api/agents';
import conversations from '../../api/conversations';
import {
  hasPushPermissions,
  requestPushPermissions,
} from '../../helper/pushHelper';

/* eslint-disable no-undef */
/* eslint-disable no-console */
export default function initStringeeWebPhone(
  vueInstance,
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

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.onmessage = event => {
      const { action } = event.data;
      if (action === 'answerCall') {
        StringeeSoftPhone.answerCall();
      } else if (action === 'declineCall') {
        StringeeSoftPhone.hangupCall();
      }
    };
  }

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

  function sendNotification(contactName, avatar, url) {
    const notificationOptions = {
      body: `Bạn có cuộc gọi đến từ ${contactName}`,
      actions: [
        { action: 'answerCall', title: 'Trả lời' },
        { action: 'declineCall', title: 'Từ chối' },
      ],
      data: {
        url: url,
      },
      icon: avatar || '/assets/images/dashboard/channels/phone_calling.png',
    };

    navigator.serviceWorker.ready.then(registration => {
      registration.showNotification('Cuộc gọi đến', notificationOptions);
    });
  }

  StringeeSoftPhone.on('incomingCall', async incomingcall => {
    window.onbeforeunload = () => {
      // Do nothing to bypass the default confirmation to leave site in browser
    };
    try {
      const params = {
        from: { number: incomingcall.fromNumber },
        to: { number: incomingcall.toAlias },
        call_id: incomingcall.callId,
        callCreatedReason: 'EXTERNAL_CALL_IN',
      };

      const response = await conversations.findByMessage(params);
      const displayId = response.data.display_id;
      const accountId = window.location.pathname.split('/')[3];
      const path = `/app/accounts/${accountId}/conversations/${displayId}`;
      if (vueInstance.$route.path !== path) {
        vueInstance.$router.push({ path });
      }

      const url = `${window.location.origin}${path}`;
      if (hasPushPermissions()) {
        sendNotification(response.data.contact_name, response.data.avatar, url);
      } else {
        requestPushPermissions({
          onSuccess: () =>
            sendNotification(
              response.data.contact_name,
              response.data.avatar,
              url
            ),
        });
      }
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
