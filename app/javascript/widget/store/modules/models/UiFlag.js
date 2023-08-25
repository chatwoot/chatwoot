import ApiModel from './ApiModel';

export default class UiFlag extends ApiModel {
  static entity = 'ui_flags';

  static fields() {
    return {
      allFetched: this.boolean(false),
      isFetching: this.boolean(false),
      isAgentTyping: this.boolean(false),
    };
  }
}
