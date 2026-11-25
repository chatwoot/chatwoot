import { generateFileName } from '../downloadHelper';

describe('#generateFileName', () => {
  it('should generate the correct file name', () => {
    expect(generateFileName({ type: 'csat', to: 1652812199 })).toEqual(
      'csat-report-17-05-2022.csv'
    );

    expect(
      generateFileName({ type: 'csat', to: 1652812199, businessHours: true })
    ).toEqual('csat-report-17-05-2022-business-hours.csv');
  });

  it('should append the filter it was narrowed to', () => {
    expect(
      generateFileName({
        type: 'agent',
        to: 1652812199,
        filteredBy: 'SAC - WhatsApp Cobrança',
        filterId: 7,
      })
    ).toEqual('agent-report-17-05-2022-sac-whatsapp-cobranca-7.csv');

    expect(
      generateFileName({
        type: 'agent',
        to: 1652812199,
        businessHours: true,
        filteredBy: 'SAC Email',
        filterId: 8,
      })
    ).toEqual('agent-report-17-05-2022-sac-email-8-business-hours.csv');
  });

  it('should tell two filters with the same name apart', () => {
    const first = generateFileName({
      type: 'agent',
      to: 1652812199,
      filteredBy: 'Ana',
      filterId: 3,
    });
    const second = generateFileName({
      type: 'agent',
      to: 1652812199,
      filteredBy: 'Ana',
      filterId: 4,
    });

    expect(first).toEqual('agent-report-17-05-2022-ana-3.csv');
    expect(second).toEqual('agent-report-17-05-2022-ana-4.csv');
  });

  it('should fall back to the id when the name leaves no slug', () => {
    expect(
      generateFileName({
        type: 'inbox',
        to: 1652812199,
        filteredBy: 'サポート',
        filterId: 12,
      })
    ).toEqual('inbox-report-17-05-2022-12.csv');
  });

  it('should stay unfiltered when no filter is given', () => {
    expect(generateFileName({ type: 'agent', to: 1652812199 })).toEqual(
      'agent-report-17-05-2022.csv'
    );
  });
});
