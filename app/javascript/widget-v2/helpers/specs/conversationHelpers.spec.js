import { getAiState } from '../conversationHelpers';

describe('getAiState', () => {
  it('returns ai for pending conversations when an assistant is connected', () => {
    expect(getAiState({ status: 'pending' }, true)).toEqual('ai');
  });

  it('returns human for pending conversations without an assistant', () => {
    expect(getAiState({ status: 'pending' }, false)).toEqual('human');
  });

  it('returns human for open conversations even with an assistant', () => {
    expect(getAiState({ status: 'open' }, true)).toEqual('human');
  });

  it('returns resolved for resolved conversations', () => {
    expect(getAiState({ status: 'resolved' }, true)).toEqual('resolved');
  });

  it('defaults to human when no conversation is given', () => {
    expect(getAiState(null, true)).toEqual('human');
  });
});
