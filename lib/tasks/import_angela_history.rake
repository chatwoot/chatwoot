# CUSTOMIZAÇÃO_SYNAPSEOS
# Importa o histórico legado de conversas da Angela (export JSON do attra-py)
# para o Chatwoot, SEM reenviar nada aos clientes.
#
#   python -m scripts.admin.export_angela_history /tmp/angela_history.json   (attra-py)
#   ...transferir o JSON pra cá...
#   bundle exec rails "angela:import_history[/tmp/angela_history.json,2]"     (aqui)
#
# Por que NÃO reenvia:
#   `Message.insert_all` faz INSERT em lote PULANDO os callbacks do ActiveRecord
#   — não dispara o SendReplyJob (Avisa) nem o webhook `message_created` (logo o
#   listener do attra-py também não reage). E grava `created_at` = data real da
#   mensagem (histórico fiel). Contato/contact_inbox/conversa usam os builders
#   normais (idempotentes por source_id).
#
# Idempotente: re-rodar pula conversas que já têm mensagens `legacy:%`.

namespace :angela do
  desc 'Importa histórico legado da Angela (JSON do attra-py) sem reenviar aos clientes'
  task :import_history, %i[json_path inbox_id] => :environment do |_t, args|
    json_path = args[:json_path].presence || '/tmp/angela_history.json'
    inbox = Inbox.find((args[:inbox_id].presence || 2).to_i)
    account = inbox.account
    data = JSON.parse(File.read(json_path))
    puts "[angela:import_history] inbox=##{inbox.id} (#{inbox.name}) account=##{account.id} conversas no JSON=#{data.size}"

    convs = msgs = skipped = 0

    data.each do |c|
      phone = c['telefone'].to_s
      next if phone.blank?

      source_id = phone.delete_prefix('+')
      contact_inbox = ContactInboxWithContactBuilder.new(
        inbox: inbox,
        source_id: source_id,
        contact_attributes: { name: c['nome'].presence || phone, phone_number: phone }
      ).perform

      # idempotência: pula se já importamos esse contato (msg legacy nessa inbox)
      already = Message.joins(:conversation)
                       .where(conversations: { inbox_id: inbox.id, contact_id: contact_inbox.contact_id })
                       .where("messages.source_id LIKE 'legacy:%'").exists?
      if already
        skipped += 1
        next
      end

      conversation = ConversationBuilder.new(
        params: { status: 'resolved' }, # entra resolvida — não floda a fila de abertas
        contact_inbox: contact_inbox
      ).perform

      rows = (c['mensagens'] || []).filter_map do |m|
        next if m['timestamp'].blank?

        ts = Time.zone.parse(m['timestamp'])
        incoming = m['sentido'] == 'recebida'
        {
          account_id: account.id,
          inbox_id: inbox.id,
          conversation_id: conversation.id,
          message_type: incoming ? 0 : 1, # 0=incoming, 1=outgoing
          content: m['conteudo'].to_s,
          content_type: 0, # text
          private: false,
          status: 0, # sent
          source_id: m['source_id'], # marca origem; insert_all já pula o envio
          sender_type: incoming ? 'Contact' : nil,
          sender_id: incoming ? contact_inbox.contact_id : nil,
          created_at: ts,
          updated_at: ts
        }
      end

      next if rows.empty?

      Message.insert_all(rows)
      last_ts = rows.map { |r| r[:created_at] }.max
      conversation.update_columns(last_activity_at: last_ts)

      convs += 1
      msgs += rows.size
    end

    puts "[angela:import_history] OK conversas=#{convs} mensagens=#{msgs} skipped(já importadas)=#{skipped}"
    puts '[angela:import_history] nota: mensagens via insert_all NÃO entram no índice de busca; rode um reindex se precisar buscar por conteúdo.'
  end
end
