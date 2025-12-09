export const getters = {
  getFunnels($state) {
    return Object.values($state.records).sort((a, b) => {
      if (a.is_default) return -1;
      if (b.is_default) return 1;
      return a.position - b.position;
    });
  },
  getFunnelById: $state => id => {
    return (
      Object.values($state.records).find(record => record.id === Number(id)) ||
      {}
    );
  },
  getDefaultFunnel($state) {
    return Object.values($state.records).find(f => f.is_default) || null;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getFunnelContacts: $state => funnelId => {
    const funnel = $state.records[funnelId];
    return funnel?.contacts || [];
  },
  getContactsByColumn: $state => (funnelId, columnId) => {
    const funnel = $state.records[funnelId];
    if (!funnel?.contacts || !Array.isArray(funnel.contacts)) return [];
    return funnel.contacts
      .filter(c => c && c.column_id === columnId)
      .sort((a, b) => (a.position || 0) - (b.position || 0));
  },
};
