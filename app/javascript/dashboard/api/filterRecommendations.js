/* global axios */
import ApiClient from './ApiClient';

class FilterRecommendationsApi extends ApiClient {
  constructor() {
    super('filter_recommendations', { accountScoped: true });
  }

  /**
   * @param {Object} request
   * @param {string} request.query - The description to build filters from
   * @param {'conversation'|'contact'|'automation'} request.filterType - What the filters apply to
   * @param {string[]} [request.attributeKeys] - For automations, the condition keys the rule's event offers
   * @param {Object<string, string[]>} [request.events] - For an automation without an event, each event it can
   *   have with that event's condition keys. The response then names the event in `event_name`.
   * @param {string[]} [request.actionNames] - For automations, the actions the form offers. The response then
   *   recommends actions in `actions`.
   */
  create(
    { query, filterType, attributeKeys, events, actionNames },
    { signal } = {}
  ) {
    return axios.post(
      this.url,
      {
        query,
        filter_type: filterType,
        attribute_keys: attributeKeys,
        events,
        action_names: actionNames,
      },
      { signal }
    );
  }
}

export default new FilterRecommendationsApi();
