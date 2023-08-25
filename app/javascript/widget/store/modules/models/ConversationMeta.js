import ApiModel from './ApiModel';

export default class ConversationMeta extends ApiModel {
  static entity = 'conversation_metas';

  static fields() {
    return {
      id: this.attr(null),
      conversation_id: this.attr(null),
      allFetched: this.boolean(false),
      isFetching: this.boolean(false),
      isAgentTyping: this.boolean(false),
      isUserTyping: this.boolean(false),
    };
  }
}
