import ApiModel from './ApiModel';

import MessageMeta from './MessageMeta';

export default class Message extends ApiModel {
  static entity = 'messages';

  static fields() {
    return {
      id: this.attr(null),
      content: this.attr(''),
      content_type: this.attr(''),
      conversation_id: this.attr(null),
      created_at: this.attr(() => Date.now()),
      message_type: this.number(0),
      content_attributes: this.attr({}),
      meta: this.hasOne(MessageMeta, 'message_id'),
    };
  }
}
