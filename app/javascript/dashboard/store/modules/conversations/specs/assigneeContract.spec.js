import getters from '../getters';
import contract from './contracts/assigneeContract.json';

// The other half of `spec/contracts/conversation_assignee_contract_spec.rb`. That spec asks the real
// endpoint what each tab holds and writes it to the fixture below; this one replays the same payload
// through the store getters that build the list on screen. When the two definitions of "unassigned"
// drift apart, this is what fails.
//
// It reproduces the shape of the bug it exists for (#416): the store holds every conversation the
// "All" tab loaded, and the "Unassigned" tab filters that locally. A tab that disagrees with the
// count the server sent is a tab whose badge disagrees with its own list.
describe('assignee contract', () => {
  const { conversations, server, current_user_id: currentUserId } = contract;
  const state = { allConversations: conversations, chatSortFilter: '' };
  const filters = { status: 'open' };

  it('lists in Unassigned exactly what the server calls unassigned', () => {
    const chats = getters.getUnAssignedChats(state, {}, {}, {})(filters);

    expect(chats.map(chat => chat.id)).toEqual(server.unassigned_ids);
    expect(chats).toHaveLength(server.counts.unassigned_count);
  });

  it('lists in Mine exactly what the server calls mine', () => {
    const chats = getters.getMineChats(
      state,
      {},
      {},
      {
        getCurrentUser: { id: currentUserId },
      }
    )(filters);

    expect(chats.map(chat => chat.id)).toEqual(server.mine_ids);
    expect(chats).toHaveLength(server.counts.mine_count);
  });

  it('loads the whole All tab into the store, which is where the tabs filter from', () => {
    expect(conversations).toHaveLength(server.counts.all_count);
  });
});
