class SetDefaultLocaleToTr < ActiveRecord::Migration[7.0]
  def up
    tr_key = language_key_for('tr')
    en_key = language_key_for('en')

    change_column_default :accounts, :locale, tr_key

    execute <<~SQL.squish
      UPDATE accounts
      SET locale = #{tr_key}
      WHERE locale = #{en_key}
    SQL

    execute <<~SQL.squish
      UPDATE users
      SET ui_settings = jsonb_set(COALESCE(ui_settings, '{}'::jsonb), '{locale}', '"tr"', true)
      WHERE (ui_settings->>'locale' IS NULL OR ui_settings->>'locale' = 'en')
    SQL
  end

  def down
    en_key = language_key_for('en')
    change_column_default :accounts, :locale, en_key
  end

  private

  def language_key_for(code)
    pair = LANGUAGES_CONFIG.find { |_key, lang| lang[:iso_639_1_code] == code }
    pair&.first || raise(KeyError, "Locale code not found: #{code}")
  end
end
