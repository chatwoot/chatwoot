module Wootql::Contracts
  STAGES = {
    'where' => { signature: 'where status = "open" and id in $ids',
                 description: 'Compare compatible fields or scalar values. Use in $ids for an array or in (1, $id) for scalars. ' \
                              'Also supports contains, null/empty tests, and boolean operators. Quoted strings are values, not fields.' },
    'return' => { signature: 'return id, inbox.name as inbox_name',
                  description: 'Keep or rename fields. Unselected fields are no longer available.' },
    'join' => { signature: 'join contacts as contact on contact_id = contact.id',
                description: 'Equality join to an authorized resource. Use join left to retain unmatched rows.' },
    'summarize' => { signature: 'summarize count() as total by inbox_id',
                     description: 'Aggregate with count, count_distinct, sum, avg, min, or max. Only count() omits its field.' },
    'sort' => { signature: 'sort total desc, inbox_id asc',
                description: 'Order retained fields with nulls last. Keep unique ordering keys for pagination.' },
    'take' => { signature: 'take 10', description: 'Limit the current pipeline stage, not the final result implicitly.' }
  }.freeze
end
