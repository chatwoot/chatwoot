import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({ messageId, email, values }) => {
    const urlData = authEndPoint.updateMessage(messageId);
    return API.patch(urlData.url, {
      contact: { email },
      message: { submitted_values: values },
    });
  },
  personaliseMessageVariables: (payload, accessToken) => {
    console.log(accessToken, 'access token here, testing here.')
    return API.post('/api/v1/personalise_variables', payload, {
      headers: {
        'api_access_token': accessToken,
      },
    });
  },
};
