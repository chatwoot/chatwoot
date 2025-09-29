import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({
    messageId,
    email,
    values,
    phone,
    orderId,
    selectedReply,
    productId,
    previousSelectedReplies,
    conversationResolved,
    assignToAgent,
    productIdForMoreInfo,
    preChatFormResponse,
    shouldShowMessageOnChat,
    isAiNudge,
  }) => {
    const urlData = authEndPoint.updateMessage(messageId);
    return API.patch(urlData.url, {
      contact: { email },
      message: {
        submitted_values: values,
        user_phone_number: phone,
        selected_reply: selectedReply,
        previous_selected_replies: previousSelectedReplies,
        user_order_id: orderId,
        product_id: productId,
        conversation_resolved: conversationResolved,
        assign_to_agent: assignToAgent,
        product_id_for_more_info: productIdForMoreInfo,
        pre_chat_form_response: preChatFormResponse,
        should_show_message_on_chat: shouldShowMessageOnChat,
        is_ai_nudge: isAiNudge,
      },
    });
  },
  personaliseMessageVariables: (payload, accessToken) => {
    return API.post('/api/v1/personalise_variables', payload, {
      headers: {
        api_access_token: accessToken,
      },
    });
  },
};
