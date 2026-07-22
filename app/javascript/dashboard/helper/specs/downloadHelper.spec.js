import { generateFileName } from '../downloadHelper';

describe('#generateFileName', () => {
  it('should generate the correct file name with ISO date', () => {
    expect(generateFileName({ type: 'csat', to: 1652812199 })).toEqual(
      'csat-report-2022-05-17.csv'
    );

    expect(
      generateFileName({ type: 'csat', to: 1652812199, businessHours: true })
    ).toEqual('csat-report-2022-05-17-business-hours.csv');
  });

  it('should prefix with account slug when provided', () => {
    expect(
      generateFileName({
        type: 'agent',
        to: 1652812199,
        accountName: 'DFIT Corp',
      })
    ).toEqual('dfit-corp-agent-report-2022-05-17.csv');
  });
});
