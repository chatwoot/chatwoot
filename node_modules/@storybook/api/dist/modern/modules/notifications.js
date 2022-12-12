export const init = ({
  store
}) => {
  const api = {
    addNotification: notification => {
      // Get rid of it if already exists
      api.clearNotification(notification.id);
      const {
        notifications
      } = store.getState();
      store.setState({
        notifications: [...notifications, notification]
      });
    },
    clearNotification: id => {
      const {
        notifications
      } = store.getState();
      store.setState({
        notifications: notifications.filter(n => n.id !== id)
      });
      const notification = notifications.find(n => n.id === id);

      if (notification && notification.onClear) {
        notification.onClear();
      }
    }
  };
  const state = {
    notifications: []
  };
  return {
    api,
    state
  };
};