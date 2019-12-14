import DateSeparator from '../DateSeparator';

describe('#DateSeparator', () => {
  it('should format correctly without dateFormat', () => {
    expect(new DateSeparator(1576340626).format()).toEqual('Dec 14, 2019');
  });

  it('should format correctly without dateFormat', () => {
    expect(new DateSeparator(1576340626).format('DD-MM-YYYY')).toEqual(
      '14-12-2019'
    );
  });
});
