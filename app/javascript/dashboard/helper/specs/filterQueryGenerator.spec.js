import filterQueryGenerator from '../filterQueryGenerator';

const testData = [
  {
    attribute_key: 'status',
    filter_operator: 'equal_to',
    values: [
      { id: 'pending', name: 'Pending' },
      { id: 'resolved', name: 'Resolved' },
    ],
    query_operator: 'and',
  },
  {
    attribute_key: 'assignee',
    filter_operator: 'equal_to',
    values: {
      id: 3,
      account_id: 1,
      auto_offline: true,
      confirmed: true,
      email: 'fayaz@test.com',
      available_name: 'Fayaz',
      name: 'Fayaz',
      role: 'agent',
      thumbnail:
        'https://www.gravatar.com/avatar/a35bf18a632f734c8d0c883dcc9fa0ef?d=404',
    },
    query_operator: 'and',
  },
  {
    attribute_key: 'id',
    filter_operator: 'equal_to',
    values: 'This is a test',
    query_operator: 'or',
  },
];

const finalResult = {
  payload: [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: ['pending', 'resolved'],
      query_operator: 'and',
    },
    {
      attribute_key: 'assignee',
      filter_operator: 'equal_to',
      values: [3],
      query_operator: 'and',
    },
    {
      attribute_key: 'id',
      filter_operator: 'equal_to',
      values: ['This is a test'],
    },
  ],
};

describe('#filterQueryGenerator', () => {
  it.each([0, false])('preserves scalar value %s in the request', values => {
    expect(
      filterQueryGenerator([{ attribute_key: 'custom_value', values }])
        .payload[0].values
    ).toEqual([values]);
  });
  it('returns the correct format of filter query', () => {
    expect(filterQueryGenerator(testData)).toMatchObject(finalResult);
    expect(
      filterQueryGenerator(testData).payload.every(i => Array.isArray(i.values))
    ).toBe(true);
  });

  it('does not split content values on commas', () => {
    const input = [
      {
        attribute_key: 'content',
        filter_operator: 'contains',
        values: 'hello, world',
        query_operator: null,
      },
    ];
    const result = filterQueryGenerator(input);
    expect(result.payload[0].values).toEqual(['hello, world']);
  });

  it('adds the browser timezone to timestamp filters', () => {
    const result = filterQueryGenerator([
      {
        attribute_key: 'created_at',
        filter_operator: 'is_less_than',
        values: '2026-09-08',
        query_operator: null,
      },
    ]);

    expect(result.payload[0].timezone).toBe(
      Intl.DateTimeFormat().resolvedOptions().timeZone
    );
  });

  it('preserves a saved timezone and removes it from non-timestamp filters', () => {
    const result = filterQueryGenerator([
      {
        attribute_key: 'last_activity_at',
        filter_operator: 'days_before',
        values: 2,
        timezone: 'America/Sao_Paulo',
        query_operator: 'and',
      },
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: 'open',
        timezone: 'America/Sao_Paulo',
        query_operator: null,
      },
    ]);

    expect(result.payload[0].timezone).toBe('America/Sao_Paulo');
    expect(result.payload[1]).not.toHaveProperty('timezone');
  });

  it('passes content values through unchanged when already an array', () => {
    const input = [
      {
        attribute_key: 'content',
        filter_operator: 'contains',
        values: ['hello, world'],
        query_operator: null,
      },
    ];
    const result = filterQueryGenerator(input);
    expect(result.payload[0].values).toEqual(['hello, world']);
  });

  it('serializes a selected contact object to contact id', () => {
    const result = filterQueryGenerator([
      {
        attribute_key: 'contact_id',
        filter_operator: 'equal_to',
        values: { id: 123, name: 'Jane Doe' },
        query_operator: 'and',
      },
    ]);

    expect(result).toMatchObject({
      payload: [
        {
          attribute_key: 'contact_id',
          filter_operator: 'equal_to',
          values: [123],
        },
      ],
    });
  });
});
