import ApiModel from './ApiModel';

export default class MessageMeta extends ApiModel {
  static entity = 'message_metas';

  static fields() {
    return {
      id: this.attr(null),
      message_id: this.attr(null),
      isCreating: this.boolean(false),
      isPending: this.boolean(false),
      isDeleting: this.boolean(false),
      isUpdating: this.boolean(false),
      isFailed: this.boolean(false),
    };
  }
}
