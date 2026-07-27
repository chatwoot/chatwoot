import { client } from './client';

export const fetchWidgetConfig = () =>
  client.get('/api/v2/widget/config').then(response => response.data);
