import { getAvailableAgentsText } from '../utils';

describe('#getAvailableAgentsText', () => {
  it('returns the correct text is there is only one online agent', () => {
    expect(getAvailableAgentsText([{ name: 'Pranav' }])).toEqual(
      'Pranav is available'
    );
  });

  it('returns the correct text is there are two online agents', () => {
    expect(
      getAvailableAgentsText([{ name: 'Pranav' }, { name: 'Nithin' }])
    ).toEqual('Pranav and Nithin is available');
  });

  it('returns the correct text is there are more than two online agents', () => {
    expect(
      getAvailableAgentsText([
        { name: 'Pranav' },
        { name: 'Nithin' },
        { name: 'Subin' },
        { name: 'Sojan' },
      ])
    ).toEqual('Pranav and 3 others are available');
  });
});
