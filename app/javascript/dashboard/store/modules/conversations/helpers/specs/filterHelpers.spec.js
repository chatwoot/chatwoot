import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { matchesFilters } from '../filterHelpers';

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
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: ['open'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with not_equal_to operator for status', () => {
      const conversation = { status: 'open' };
      const filters = [
        {
          attributeKey: 'status',
          filterOperator: 'not_equal_to',
          values: ['open'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Standard attribute tests - assignee_id
    it('should match conversation with equal_to operator for assignee_id', () => {
      const conversation = { meta: { assignee: { id: 1 } } };
      const filters = [
        {
          attributeKey: 'assignee_id',
          filterOperator: 'equal_to',
          values: [1],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with not_equal_to operator for assignee_id', () => {
      const conversation = { meta: { assignee: { id: 1 } } };
      const filters = [
        {
          attributeKey: 'assignee_id',
          filterOperator: 'not_equal_to',
          values: [2],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_present operator for assignee_id', () => {
      const conversation = { meta: { assignee: { id: 1 } } };
      const filters = [
        {
          attributeKey: 'assignee_id',
          filterOperator: 'is_present',
          values: [],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_not_present operator for assignee_id', () => {
      const conversation = { meta: { assignee: null } };
      const filters = [
        {
          attributeKey: 'assignee_id',
          filterOperator: 'is_not_present',
          values: [],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with is_present operator when assignee is null', () => {
      const conversation = { meta: { assignee: null } };
      const filters = [
        {
          attributeKey: 'assignee_id',
          filterOperator: 'is_present',
          values: [],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Standard attribute tests - priority
    it('should match conversation with equal_to operator for priority', () => {
      const conversation = { priority: 'urgent' };
      const filters = [
        {
          attributeKey: 'priority',
          filterOperator: 'equal_to',
          values: ['urgent'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with not_equal_to operator for priority', () => {
      const conversation = { priority: 'urgent' };
      const filters = [
        {
          attributeKey: 'priority',
          filterOperator: 'not_equal_to',
          values: ['urgent'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Text search tests - display_id
    it('should match conversation with equal_to operator for display_id', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attributeKey: 'display_id',
          filterOperator: 'equal_to',
          values: ['12345'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with contains operator for display_id', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attributeKey: 'display_id',
          filterOperator: 'contains',
          values: ['234'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with does_not_contain operator for display_id', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attributeKey: 'display_id',
          filterOperator: 'does_not_contain',
          values: ['234'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with does_not_contain operator when value is not present', () => {
      const conversation = { display_id: '12345' };
      const filters = [
        {
          attributeKey: 'display_id',
          filterOperator: 'does_not_contain',
          values: ['678'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    // Array/List tests - labels
    it('should match conversation with equal_to operator for labels', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attributeKey: 'labels',
          filterOperator: 'equal_to',
          values: ['urgent'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with equal_to operator for labels when value is not present', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attributeKey: 'labels',
          filterOperator: 'equal_to',
          values: ['billing'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with not_equal_to operator for labels when value is not present', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attributeKey: 'labels',
          filterOperator: 'not_equal_to',
          values: ['billing'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_present operator for labels', () => {
      const conversation = { labels: ['support', 'urgent', 'new'] };
      const filters = [
        {
          attributeKey: 'labels',
          filterOperator: 'is_present',
          values: [],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_not_present operator for labels when labels is null', () => {
      const conversation = { labels: null };
      const filters = [
        {
          attributeKey: 'labels',
          filterOperator: 'is_not_present',
          values: [],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should match conversation with is_not_present operator for labels when labels is undefined', () => {
      const conversation = {};
      const filters = [
        {
          attributeKey: 'labels',
          filterOperator: 'is_not_present',
          values: [],
          queryOperator: 'and',
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
          attributeKey: 'browser_language',
          filterOperator: 'equal_to',
          values: ['en-US'],
          queryOperator: 'and',
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
          attributeKey: 'referer',
          filterOperator: 'contains',
          values: ['chatwoot'],
          queryOperator: 'and',
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
          attributeKey: 'referer',
          filterOperator: 'does_not_contain',
          values: ['chatwoot'],
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    // Date tests
    it('should match conversation with is_greater_than operator for created_at', () => {
      const conversation = { created_at: 1647777600000 }; // March 20, 2022
      const filters = [
        {
          attributeKey: 'created_at',
          filterOperator: 'is_greater_than',
          values: [1647691200000], // March 19, 2022
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(true);
    });

    it('should not match conversation with is_greater_than operator for created_at when date is earlier', () => {
      const conversation = { created_at: 1647691200000 }; // March 19, 2022
      const filters = [
        {
          attributeKey: 'created_at',
          filterOperator: 'is_greater_than',
          values: [1647777600000], // March 20, 2022
          queryOperator: 'and',
        },
      ];
      expect(matchesFilters(conversation, filters)).toBe(false);
    });

    it('should match conversation with is_less_than operator for created_at', () => {
      const conversation = { created_at: 1647777600000 }; // March 20, 2022
      const filters = [
        {
          attributeKey: 'created_at',
          filterOperator: 'is_less_than',
          values: [1647864000000], // March 21, 2022
          queryOperator: 'and',
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
            attributeKey: 'created_at',
            filterOperator: 'days_before',
            values: [3], // 3 days before March 25 = March 22
            queryOperator: 'and',
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
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: ['open'],
          queryOperator: 'and',
        },
        {
          attributeKey: 'priority',
          filterOperator: 'equal_to',
          values: ['urgent'],
          queryOperator: 'and',
        },
        {
          attributeKey: 'assignee_id',
          filterOperator: 'equal_to',
          values: [1],
          queryOperator: 'and',
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
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: ['open'],
          queryOperator: 'and',
        },
        {
          attributeKey: 'priority',
          filterOperator: 'equal_to',
          values: ['low'], // This doesn't match
          queryOperator: 'and',
        },
        {
          attributeKey: 'assignee_id',
          filterOperator: 'equal_to',
          values: [1],
          queryOperator: 'and',
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
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: ['closed'],
          queryOperator: 'or',
        },
        {
          attributeKey: 'priority',
          filterOperator: 'equal_to',
          values: ['low'],
          queryOperator: 'and',
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
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: ['open'], // This matches
          queryOperator: 'or',
        },
        {
          attributeKey: 'priority',
          filterOperator: 'equal_to',
          values: ['urgent'], // This doesn't match
          queryOperator: 'and',
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
          attributeKey: 'team_id',
          filterOperator: 'equal_to',
          values: [5],
          queryOperator: 'and',
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
          attributeKey: 'status',
          filterOperator: 'is_not_present',
          values: [],
          queryOperator: 'and',
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
          attributeKey: 'labels',
          filterOperator: 'is_present',
          values: [],
          queryOperator: 'and',
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
          attributeKey: 'display_id',
          filterOperator: 'is_present',
          values: [],
          queryOperator: 'and',
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
          attributeKey: 'customer_type',
          filterOperator: 'equal_to',
          values: ['premium'],
          queryOperator: 'and',
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
          attributeKey: 'notes',
          filterOperator: 'contains',
          values: ['refund'],
          queryOperator: 'and',
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
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: ['open'],
          queryOperator: 'and',
        },
        {
          attributeKey: 'created_at',
          filterOperator: 'is_greater_than',
          values: [1647691200000], // March 19, 2022
          queryOperator: 'and',
        },
        {
          attributeKey: 'customer_type',
          filterOperator: 'equal_to',
          values: ['premium'],
          queryOperator: 'and',
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['12345'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['12345'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['12345'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['12345'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['low'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['67890'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['low'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['67890'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['67890'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'browser_language',
              filterOperator: 'equal_to',
              values: ['tr'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['67890'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'browser_language',
              filterOperator: 'equal_to',
              values: ['tr'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['67890'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'conversation_type',
              filterOperator: 'equal_to',
              values: ['platinum'],
              queryOperator: null,
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
              attributeKey: 'status',
              filterOperator: 'equal_to',
              values: ['open'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'priority',
              filterOperator: 'equal_to',
              values: ['urgent'],
              queryOperator: 'or',
            },
            {
              attributeKey: 'display_id',
              filterOperator: 'equal_to',
              values: ['67890'],
              queryOperator: 'and',
            },
            {
              attributeKey: 'conversation_type',
              filterOperator: 'equal_to',
              values: ['platinum'],
              queryOperator: null,
            },
          ];

          // true AND true OR false AND false
          // true OR false
          // true
          expect(matchesFilters(conversation, filters)).toBe(true);
        });
      });
    });
  });
});
