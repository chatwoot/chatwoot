# rubocop:disable Metrics/MethodLength
class Api::V1::Accounts::BootstrapsController < Api::V1::Accounts::BaseController
  def conversations # rubocop:disable Metrics/AbcSize
    results = ActiveRecord::Base.connection.execute("SELECT * FROM conversations WHERE account_id = #{Current.account.id} ORDER BY id DESC LIMIT 2000")
    if results.present?
      json_results = results.map do |row|
        additional_attributes = row['additional_attributes'] ? JSON.parse(row['additional_attributes']) : {}
        custom_attributes = row['custom_attributes'] ? JSON.parse(row['custom_attributes']) : {}
        {
          id: row['display_id'],
          account_id: row['account_id'],
          inbox_id: row['inbox_id'],
          status: row['status'],
          assignee_id: row['assignee_id'],
          created_at: row['created_at'],
          updated_at: row['updated_at'],
          contact_id: row['contact_id'],
          agent_last_seen_at: row['agent_last_seen_at'],
          additional_attributes: additional_attributes,
          last_activity_at: row['last_activity_at'],
          team_id: row['team_id'],
          snoozed_until: row['snoozed_until'],
          custom_attributes: custom_attributes,
          first_reply_created_at: row['first_reply_created_at'],
          priority: row['priority'],
          waiting_since: row['waiting_since']
        }
      end
      render json: json_results.to_a.to_json
      return
    end

    res.json([])
  end

  def conversation_labels
    results = ActiveRecord::Base.connection.execute(
      " SELECT
        c.display_id,
        json_agg(t.name) AS labels
      FROM
          conversations c
      JOIN
          taggings tg ON c.id = tg.taggable_id
      JOIN
          tags t ON tg.tag_id = t.id
      WHERE tg.taggable_type = 'Conversation' AND c.account_id = #{Current.account.id}
      GROUP BY
        c.display_id;
    "
    )

    if results.present?
      json_results = results.map do |row|
        {
          id: row['display_id'],
          labels: JSON.parse(row['labels'])
        }
      end
      render json: json_results.to_json
      return
    end

    res.json([])
  end

  def contacts
    results = ActiveRecord::Base.connection.execute(
      " SELECT
        c1.display_id as id,
        c2.name,
        c2.email,
        c2.phone_number,
        c2.identifier
      FROM
          conversations c1
      JOIN
          contacts c2 ON c1.contact_id = c2.id
      WHERE c1.account_id = #{Current.account.id};
    "
    )

    if results.present?
      render json: results.to_a.to_json
      return
    end

    res.json([])
  end
end
# rubocop:enable Metrics/MethodLength
