import "core-js/modules/es.function.name.js";
import { addons } from '@storybook/addons';
import EVENTS, { ADDON_ID } from './constants';
addons.register(ADDON_ID, function (api) {
  var channel = addons.getChannel();
  channel.on(EVENTS.REQUEST, function (_ref) {
    var kind = _ref.kind,
        name = _ref.name;
    var id = api.storyId(kind, name);
    api.emit(EVENTS.RECEIVE, id);
  });
});