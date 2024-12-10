# Delete migration and spec after 2 consecutive releases.
class Migration::ResendFailedMessagesJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    resend_failed_messages
  end

  private

  def resend_failed_messages
    messages.each(&:resend_message)
  end

  def messages
    Message.outgoing
           .where.not(inbox_id: 31)
           .where(private: false)
           .where.not('messages.content LIKE ?', '%Dessvärre är tolken för detta uppdrag sen på grund av%')
           .where(id: message_ids)
           .order(created_at: :asc)
  end

  def message_ids
    %w[
      611015
      611017
      611022
      611042
      611062
      611066
      611067
      611068
      611069
      611070
      611074
      611075
      611076
      611077
      611080
      611081
      611082
      611083
      611086
      611093
      611094
      611098
      611103
      611104
      611105
      611112
      611120
      611121
      611123
      611124
      611130
      611134
      611135
      611136
      611137
      611143
      611145
      611153
      611159
      611169
      611170
      611171
      611173
      611174
      611178
      611179
      611180
      611181
      611185
      611190
      611191
      611192
      611194
      611195
      611196
      611197
      611198
      611199
      611200
      611201
      611202
      611203
      611204
      611206
      611207
      611208
      611209
      611210
      611213
      611214
      611215
      611216
      611217
      611220
      611221
      611222
      611225
      611226
    ]
  end
end
