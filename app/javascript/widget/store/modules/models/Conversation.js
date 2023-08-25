import ApiModel from './ApiModel';
import Message from './Message';
import ConversationMeta from './ConversationMeta';

export default class Conversation extends ApiModel {
  static entity = 'conversations';

  static fields() {
    return {
      id: this.attr(null),
      status: this.attr(''),
      inbox_id: this.attr(null),
      contact_last_seen_at: this.attr(null),
      messages: this.hasMany(Message, 'conversation_id'),
      meta: this.hasOne(ConversationMeta, 'conversation_id'),
    };
  }
}
