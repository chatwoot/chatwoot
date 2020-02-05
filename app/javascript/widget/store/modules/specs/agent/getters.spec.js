import { getters } from '../../agent';
import { agents } from './data';

describe('#getters', () => {
  it('availableAgents', () => {
    const state = {
      records: agents,
    };
    expect(getters.availableAgents(state)).toEqual([
      {
        id: 1,
        name: 'John',
        avatar_url: '',
        availability_status: 'online',
      },
      {
        id: 3,
        name: 'Pranav',
        avatar_url: '',
        availability_status: 'online',
      },
      {
        id: 4,
        name: 'Nithin',
        avatar_url: '',
        availability_status: 'online',
      },
    ]);
  });
});
