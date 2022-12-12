import { STORIES_COLLAPSE_ALL, STORIES_EXPAND_ALL } from '@storybook/core-events';
export const init = ({
  provider
}) => {
  const api = {
    getChannel: () => provider.channel,
    on: (type, cb) => {
      provider.channel.addListener(type, cb);
      return () => provider.channel.removeListener(type, cb);
    },
    off: (type, cb) => provider.channel.removeListener(type, cb),
    once: (type, cb) => provider.channel.once(type, cb),
    emit: (type, ...args) => provider.channel.emit(type, ...args),
    collapseAll: () => {
      provider.channel.emit(STORIES_COLLAPSE_ALL, {});
    },
    expandAll: () => {
      api.emit(STORIES_EXPAND_ALL);
    }
  };
  return {
    api
  };
};