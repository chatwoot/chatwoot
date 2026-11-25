import axios from 'axios';
import { actions } from '../actions';

global.axios = axios;
vi.mock('axios');

// The order the Articles tab asks for (#811) has to reach the request, or the list keeps
// coming back by last update whatever the menu says.
describe('#index with an order', () => {
  it('asks the API for the order it was given', async () => {
    axios.get.mockResolvedValue({ data: { payload: [], meta: {} } });

    await actions.index(
      { commit: vi.fn() },
      { pageNumber: 2, portalSlug: 'docs', locale: 'en', sort: '-created_at' }
    );

    const url = new URL(axios.get.mock.calls[0][0], 'http://localhost');
    expect(url.searchParams.get('sort')).toBe('-created_at');
    expect(url.searchParams.get('page')).toBe('2');
  });
});
