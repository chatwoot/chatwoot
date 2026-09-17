module Wootql::Contracts
  STAGES = {
    'where' => { signature: 'where status = "open" and id in $ids',
                 description: 'Compare compatible fields or scalar values. Use in $ids for an array or in (1, $id) for scalars. ' \
                              'Also supports contains, null/empty tests, and boolean operators. Quoted strings are values, not fields.' },
    'return' => { signature: 'return id, inbox.name as inbox_name',
                  description: 'Keep or rename fields. Unselected fields are no longer available. This does not terminate the pipeline. ' \
                               'Keep identity and sorting keys needed downstream. To-one paths use authorized left joins.' },
    'join' => { signature: 'join contacts as contact on contact_id = contact.id',
                description: 'Equality join to an authorized resource. Use join left to retain unmatched rows.' },
    'summarize' => { signature: 'summarize count() as total by inbox_id',
                     description: 'Aggregate with count, count_distinct, sum, avg, min, or max. Only count() omits its field.' },
    'sort' => { signature: 'sort total desc, inbox_id asc',
                description: 'Order retained fields with nulls last. Keep unique ordering keys for pagination.' },
    'take' => { signature: 'take 10', description: 'Limit the current pipeline stage, not the final result implicitly.' },
    'labels' => { signature: 'conversations | where labels is empty',
                  description: 'Labels are non-null string lists. is empty matches []; contains tests exact label membership. ' \
                               'is null means absent, not empty. A missing right-side conversation in a left join can be null.' },
    'values' => { signature: 'where created_at >= now() - 7d | where contact_id in $ids',
                  description: 'Double-quoted strings, numbers, true/false, null, $parameters, now() minus ms/s/m/h/d/w. ' \
                               'now() is fixed across pages of a prepared query. Null and empty are distinct; whitespace is not empty.' }
  }.freeze
end
