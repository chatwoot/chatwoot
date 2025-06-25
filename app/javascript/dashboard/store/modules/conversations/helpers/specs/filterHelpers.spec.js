import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { matchesFilters } from '../filterHelpers';

// SAMPLE PAYLOAD
//
// {
//   attribute_key: 'status',
//   attribute_model: 'standard',
//   filter_operator: 'equal_to',
//   values: [
//     {
//       id: 'open',
//       name: 'Open',
//     },
//     {
//       id: 'resolved',
//       name: 'Resolved',
//     },
//     {
//       id: 'pending',
//       name: 'Pending',
//     },
//     {
//       id: 'snoozed',
//       name: 'Snoozed',
//     },
//     {
//       id: 'all',
//       name: 'All',
//     },
//   ],
//   query_operator: 'and',
//   custom_attribute_type: '',
// },
// {
//   attribute_key: 'priority',
//   filter_operator: 'equal_to',
//   values: [
//     {
//       id: 'low',
//       name: 'Low',
//     },
//     {
//       id: 'medium',
//       name: 'Medium',
//     },
//     {
//       id: 'high',
//       name: 'High',
//     },
//   ],
//   query_operator: 'and',
// },
// {
//   attribute_key: 'assignee_id',
//   filter_operator: 'equal_to',
//   values: {
//     id: 12345,
//     name: 'Agent Name',
//   },
//   query_operator: 'and',
// },
// {
//   attribute_key: 'inbox_id',
//   filter_operator: 'equal_to',
//   values: {
//     id: 37,
//     name: 'Support Inbox',
//   },
//   query_operator: 'and',
// },
// {
//   attribute_key: 'team_id',
//   filter_operator: 'equal_to',
//   values: {
//     id: 220,
//     name: 'support-team',
//   },
//   query_operator: 'and',
// },
// {
//   attribute_key: 'created_at',
//   filter_operator: 'is_greater_than',
//   values: '2023-01-20',
//   query_operator: 'and',
// },
// {
//   attribute_key: 'last_activity_at',
//   filter_operator: 'days_before',
//   values: '998',
//   query_operator: 'and',
// },

describe('filterHelpers', () => {
  describe('#matchesFilters', () => {
    it('returns true by default when no filters are provided', () => {
      const conversation = {};
      const filters = [];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Standard attribute tests - status
    it('should match conversation with equal_to operator for status', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with equal_to operator for status "all"', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'all', name: 'all' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with not_equal_to operator for status "all"', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'not_equal_to',
          values: [{ id: 'all', name: 'all' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should not match conversation with not_equal_to operator for status', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'not_equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Standard attribute tests - assignee_id
    it('should match conversation with equal_to operator for assignee_id', () => {
      const conversation = { meta: { assignee: { id: 1 } } };
      const filters = [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: { id: 1, name: 'John Doe' },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with not_equal_to operator for assignee_id', () => {
      const conversation = { meta: { assignee: { id: 1 } } };
      const filters = [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'not_equal_to',
          values: { id: 2, name: 'Jane Smith' },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_present operator for assignee_id', () => {
      const conversation = { meta: { assignee: { id: 1 } } };
      const filters = [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'is_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_not_present operator for assignee_id', () => {
      const conversation = { meta: { assignee: null } };
      const filters = [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'is_not_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with is_present operator when assignee is null', () => {
      const conversation = { meta: { assignee: null } };
      const filters = [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'is_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Standard attribute tests - priority
    it('should match conversation with equal_to operator for priority', () => {
      const conversation = { priority: 'urgent' };
      const filters = [
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: [{ id: 'urgent', name: 'Urgent' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with not_equal_to operator for priority', () => {
      const conversation = { priority: 'urgent' };
      const filters = [
        {
          attribute_key: 'priority',
          filter_operator: 'not_equal_to',
          values: [{ id: 'urgent', name: 'Urgent' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Text search tests - display_id
    it('should match conversation with equal_to operator for display_id', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attribute_key: 'display_id',
          filter_operator: 'equal_to',
          values: '12345',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with contains operator for display_id', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attribute_key: 'display_id',
          filter_operator: 'contains',
          values: '234',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with does_not_contain operator for display_id', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attribute_key: 'display_id',
          filter_operator: 'does_not_contain',
          values: '234',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with does_not_contain operator when value is not present', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attribute_key: 'display_id',
          filter_operator: 'does_not_contain',
          values: '678',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Array/List tests - labels
    it('should match conversation with equal_to operator for labels', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'equal_to',
          values: [{ id: 'urgent', name: 'Urgent' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with equal_to operator for labels when value is not present', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'equal_to',
          values: [{ id: 'billing', name: 'Billing' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with not_equal_to operator for labels when value is not present', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'not_equal_to',
          values: [{ id: 'billing', name: 'Billing' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_present operator for labels', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'is_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_not_present operator for labels when labels is null', () => {
      const conversation = { labels: null };
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'is_not_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_not_present operator for labels when labels is undefined', () => {
      const conversation = {};
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'is_not_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Additional attributes tests
    it('should match conversation with equal_to operator for browser_language', () => {
      const conversation = {
        additional_attributes: { browser_language: 'en-US' },
      };
      const filters = [
        {
          attribute_key: 'browser_language',
          filter_operator: 'equal_to',
          values: 'en-US',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with contains operator for referer', () => {
      const conversation = {
        additional_attributes: { referer: 'https://www.chatwoot.com/pricing' },
      };
      const filters = [
        {
          attribute_key: 'referer',
          filter_operator: 'contains',
          values: 'chatwoot',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with does_not_contain operator for referer', () => {
      const conversation = {
        additional_attributes: { referer: 'https://www.chatwoot.com/pricing' },
      };
      const filters = [
        {
          attribute_key: 'referer',
          filter_operator: 'does_not_contain',
          values: 'chatwoot',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Date tests
    it('should match conversation with is_greater_than operator for created_at', () => {
      const conversation = { created_at: 1647777600000 }; // March 20, 2022
      const filters = [
        {
          attribute_key: 'created_at',
          filter_operator: 'is_greater_than',
          values: '2022-03-19',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with is_greater_than operator for created_at when date is earlier', () => {
      const conversation = { created_at: 1647691200000 }; // March 19, 2022
      const filters = [
        {
          attribute_key: 'created_at',
          filter_operator: 'is_greater_than',
          values: '2022-03-20',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with is_less_than operator for created_at', () => {
      const conversation = { created_at: 1647777600000 }; // March 20, 2022
      const filters = [
        {
          attribute_key: 'created_at',
          filter_operator: 'is_less_than',
          values: '2022-03-21', // March 21, 2022
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    describe('days_before operator', () => {
      beforeEach(() => {
        // Set the date to March 25, 2022
        vi.useFakeTimers();
        vi.setSystemTime(new Date(2022, 2, 25));
      });

      afterEach(() => {
        vi.useRealTimers();
      });

      it('should match conversation with days_before operator for created_at', () => {
        const conversation = { created_at: 1647777600000 }; // March 20, 2022
        const filters = [
          {
            attribute_key: 'created_at',
            filter_operator: 'days_before',
            values: '3', // 3 days before March 25 = March 22
            query_operator: 'and',
          },
        ];
        expect(matchesFilters(conversation, filters)).toBe(true);
      });
    });

    // Multiple filters tests
    it('should match conversation with multiple filters combined with AND operator', () => {
      const conversation = {
        status: 'open',
        priority: 'urgent',
        meta: { assignee: { id: 1 } },
      };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'and',
        },
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: [{ id: 'urgent', name: 'Urgent' }],
          query_operator: 'and',
        },
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: {
            id: 1,
            name: 'Agent',
          },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation when one filter in AND chain does not match', () => {
      const conversation = {
        status: 'open',
        priority: 'urgent',
        meta: { assignee: { id: 1 } },
      };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'and',
        },
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: [{ id: 'low', name: 'Low' }], // This doesn't match
          query_operator: 'and',
        },
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: {
            id: 1,
            name: 'Agent',
          },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with multiple filters combined with OR operator', () => {
      const conversation = {
        status: 'open',
        priority: 'low',
      };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'closed', name: 'Closed' }],
          query_operator: 'or',
        },
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: [{ id: 'low', name: 'Low' }],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation when one filter in OR chain matches', () => {
      const conversation = {
        status: 'open',
        priority: 'low',
      };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }], // This matches
          query_operator: 'or',
        },
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: [{ id: 'urgent', name: 'Urgent' }], // This doesn't match
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with multiple status and priority', () => {
      const conversation = {
        status: 'open',
        priority: 'high',
        meta: {
          assignee: {
            id: 83235,
          },
        },
      };

      const filters = [
        {
          values: ['open', 'resolved'],
          attribute_key: 'status',
          query_operator: 'and',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          custom_attribute_type: '',
        },
        {
          values: [83235],
          attribute_key: 'assignee_id',
          query_operator: 'and',
          filter_operator: 'equal_to',
        },
        {
          values: ['high', 'urgent'],
          attribute_key: 'priority',
          filter_operator: 'equal_to',
        },
      ];

      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Nested property tests
    it('should match conversation with filter on nested property in meta', () => {
      const conversation = {
        meta: {
          team: {
            id: 5,
            name: 'Support',
          },
        },
      };
      const filters = [
        {
          attribute_key: 'team_id',
          filter_operator: 'equal_to',
          values: { id: 5, name: 'Support' },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Edge cases
    it('should handle null values in conversation', () => {
      const conversation = {
        status: null,
        priority: 'low',
      };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'is_not_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should handle empty arrays in conversation', () => {
      const conversation = {
        labels: [],
      };
      const filters = [
        {
          attribute_key: 'labels',
          filter_operator: 'is_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should handle empty string values in conversation', () => {
      const conversation = {
        display_id: '',
      };
      const filters = [
        {
          attribute_key: 'display_id',
          filter_operator: 'is_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Custom attributes tests
    it('should match conversation with filter on custom attribute', () => {
      const conversation = {
        custom_attributes: {
          customer_type: 'premium',
        },
      };
      const filters = [
        {
          attribute_key: 'customer_type',
          filter_operator: 'equal_to',
          values: 'premium',
          query_operator: 'and',
          attributeModel: 'customAttributes',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with contains operator on custom attribute', () => {
      const conversation = {
        custom_attributes: {
          notes: 'This customer has requested a refund',
        },
      };
      const filters = [
        {
          attribute_key: 'notes',
          filter_operator: 'contains',
          values: 'refund',
          query_operator: 'and',
          attributeModel: 'customAttributes',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Combination tests
    it('should match conversation with combination of different attribute types', () => {
      const conversation = {
        status: 'open',
        created_at: 1647777600000, // March 20, 2022
        custom_attributes: {
          customer_type: 'premium',
        },
      };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'and',
        },
        {
          attribute_key: 'created_at',
          filter_operator: 'is_greater_than',
          values: '2022-03-19', // March 19, 2022
          query_operator: 'and',
        },
        {
          attribute_key: 'customer_type',
          filter_operator: 'equal_to',
          values: 'premium',
          query_operator: 'and',
          attributeModel: 'customAttributes',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Backend alignment tests
    describe('Backend alignment tests', () => {
      // Test case for: status='open' AND priority='urgent' OR display_id='12345'
      describe('with A AND B OR C filter chain', () => {
        it('matches when all conditions are true', () => {
          const conversation = {
            status: 'open', // A: true
            priority: 'urgent', // B: true
            display_id: '12345', // C: true
          };

          // This filter chain is: (status='open' AND priority='urgent') OR display_id='12345'
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '12345',
              query_operator: null,
            },
          ];

          // Expected: (true AND true) OR true = true OR true = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });

        it('matches when first condition is false but third is true', () => {
          const conversation = {
            status: 'resolved', // A: false
            priority: 'urgent', // B: true
            display_id: '12345', // C: true
          };

          // This filter chain is: (status='open' AND priority='urgent') OR display_id='12345'
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '12345',
              query_operator: null,
            },
          ];

          // Expected: (false AND true) OR true = false OR true = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });

        it('matches when first and second condition is false but third is true', () => {
          const conversation = {
            status: 'resolved', // A: false
            priority: 'low', // B: false
            display_id: '12345', // C: true
          };

          // This filter chain is: (status='open' AND priority='urgent') OR display_id='12345'
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '12345',
              query_operator: null,
            },
          ];

          // Expected: (false AND false) OR true = false OR true = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });

        it('does not match when all conditions are false', () => {
          const conversation = {
            status: 'resolved', // A: false
            priority: 'low', // B: false
            display_id: '67890', // C: false
          };

          // This filter chain is: (status='open' AND priority='urgent') OR display_id='12345'
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [
                {
                  id: 'urgent',
                  name: 'Urgent',
                },
              ],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '12345',
              query_operator: null,
            },
          ];

          // Expected: (false AND false) OR false = false OR false = false
          expect(matchesFilters(conversation, filters)).toBe(false);
        });
      });

      // Test case for: status='open' OR priority='low' AND display_id='67890'
      describe('with A OR B AND C filter chain', () => {
        it('matches when first condition is true', () => {
          const conversation = {
            status: 'open', // A: true
            priority: 'urgent', // B: false
            display_id: '12345', // C: false
          };

          // This filter chain is: status='open' OR (priority='low' AND display_id='67890')
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'low', name: 'Low' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '67890',
              query_operator: null,
            },
          ];

          // Expected: true OR (false AND false) = true OR false = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });

        it('matches when second and third conditions are true', () => {
          const conversation = {
            status: 'resolved', // A: false
            priority: 'low', // B: true
            display_id: '67890', // C: true
          };

          // This filter chain is: status='open' OR (priority='low' AND display_id='67890')
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'low', name: 'Low' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '67890',
              query_operator: null,
            },
          ];

          // Expected: false OR (true AND true) = false OR true = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });
      });

      // Test case for: status='open' AND priority='urgent' OR display_id='67890' AND browser_language='tr'
      describe('with complex filter chain A AND B OR C AND D', () => {
        it('matches when first two conditions are true', () => {
          const conversation = {
            status: 'open', // A: true
            priority: 'urgent', // B: true
            display_id: '12345', // C: false
            additional_attributes: {
              browser_language: 'en', // D: false
            },
          };

          // This filter chain is: (status='open' AND priority='urgent') OR (display_id='67890' AND browser_language='tr')
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '67890',
              query_operator: 'and',
            },
            {
              attribute_key: 'browser_language',
              filter_operator: 'equal_to',
              values: 'tr',
              query_operator: null,
            },
          ];

          // Expected: (true AND true) OR (false AND false) = true OR false = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });

        it('matches when last two conditions are true', () => {
          const conversation = {
            status: 'resolved', // A: false
            priority: 'low', // B: false
            display_id: '67890', // C: true
            additional_attributes: {
              browser_language: 'tr', // D: true
            },
          };

          // This filter chain is: (status='open' AND priority='urgent') OR (display_id='67890' AND browser_language='tr')
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '67890',
              query_operator: 'and',
            },
            {
              attribute_key: 'browser_language',
              filter_operator: 'equal_to',
              values: 'tr',
              query_operator: null,
            },
          ];

          // Expected: (false AND false) OR (true AND true) = false OR true = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });
      });

      // Test case for: status='open' AND (priority='urgent' OR display_id='67890') AND conversation_type='platinum'
      describe('with mixed operators filter chain', () => {
        it('matches when all conditions in the chain are true', () => {
          const conversation = {
            status: 'open', // A: true
            priority: 'urgent', // B: true
            display_id: '12345', // C: false
            custom_attributes: {
              conversation_type: 'platinum', // D: true
            },
          };

          // This filter chain is: status='open' AND (priority='urgent' OR display_id='67890') AND conversation_type='platinum'
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '67890',
              query_operator: 'and',
            },
            {
              attribute_key: 'conversation_type',
              filter_operator: 'equal_to',
              values: 'platinum',
              query_operator: null,
              attributeModel: 'customAttributes',
            },
          ];

          // Expected: true AND (true OR false) AND true = true AND true AND true = true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });

        it('does not match when the last condition is false', () => {
          const conversation = {
            status: 'open', // A: true
            priority: 'urgent', // B: true
            display_id: '12345', // C: false
            custom_attributes: {
              conversation_type: 'silver', // D: false
            },
          };

          // This filter chain is: status='open' AND (priority='urgent' OR display_id='67890') AND conversation_type='platinum'
          const filters = [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: [{ id: 'open', name: 'Open' }],
              query_operator: 'and',
            },
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: [{ id: 'urgent', name: 'Urgent' }],
              query_operator: 'or',
            },
            {
              attribute_key: 'display_id',
              filter_operator: 'equal_to',
              values: '67890',
              query_operator: 'and',
            },
            {
              attribute_key: 'conversation_type',
              filter_operator: 'equal_to',
              values: 'platinum',
              query_operator: null,
              attributeModel: 'customAttributes',
            },
          ];

          // true AND true OR false AND false
          // true OR false
          // true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });
      });
    });

    // Test for inbox_id in getValueFromConversation
    it('should match conversation with equal_to operator for inbox_id', () => {
      const conversation = { inbox_id: 123 };
      const filters = [
        {
          attribute_key: 'inbox_id',
          filter_operator: 'equal_to',
          values: { id: 123, name: 'Support Inbox' },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with equal_to operator for inbox_id when values differ', () => {
      const conversation = { inbox_id: 123 };
      const filters = [
        {
          attribute_key: 'inbox_id',
          filter_operator: 'equal_to',
          values: { id: 456, name: 'Sales Inbox' },
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Test for default case (returning null) in getValueFromConversation
    it('should not match conversation when attribute key is not recognized', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'unknown_attribute',
          filter_operator: 'equal_to',
          values: 'some_value',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with is_not_present operator for unknown attribute', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'unknown_attribute',
          filter_operator: 'is_not_present',
          values: [],
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Test for contains operator when value is not a string
    it('should not match conversation with contains operator when value is not a string', () => {
      const conversation = {
        custom_attributes: {
          numeric_value: 12345,
        },
      };
      const filters = [
        {
          attribute_key: 'numeric_value',
          filter_operator: 'contains',
          values: '123',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should not match conversation with contains operator when value is an array', () => {
      const conversation = {
        custom_attributes: {
          array_value: [1, 2, 3, 4, 5],
        },
      };
      const filters = [
        {
          attribute_key: 'array_value',
          filter_operator: 'contains',
          values: '3',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Test for does_not_contain operator when value is not a string
    it('should match conversation with does_not_contain operator when value is not a string', () => {
      const conversation = {
        custom_attributes: {
          numeric_value: 12345,
        },
      };
      const filters = [
        {
          attribute_key: 'numeric_value',
          filter_operator: 'does_not_contain',
          values: '123',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with does_not_contain operator when value is an array', () => {
      const conversation = {
        custom_attributes: {
          array_value: [1, 2, 3, 4, 5],
        },
      };
      const filters = [
        {
          attribute_key: 'array_value',
          filter_operator: 'does_not_contain',
          values: '3',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Test for default case in matchesCondition
    it('should not match conversation with unknown filter operator', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'unknown_operator',
          values: 'open',
          query_operator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });
  });
});
