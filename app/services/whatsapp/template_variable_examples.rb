class Whatsapp::TemplateVariableExamples
  VALUES = {
    'contact_name' => 'Maria Silva',
    'contact_phone' => '+5511999887766',
    'contact_email' => 'maria@email.com',
    'company_name' => 'Empresa ABC',
    'lista_processos' => <<~TEXT.strip
      📄 Processo 0008838-62.2026.4.05.8400 15 novas movimentações encontradas:

      26/04/2026 00:14:37 - publicado citacao e intimacao em 22/04/2026.
      26/04/2026 00:14:37 - disponibilizado no dj eletronico em 21/04/2026
      26/04/2026 00:14:36 - publicado intimacao em 22/04/2026.
      26/04/2026 00:14:36 - disponibilizado no dj eletronico em 21/04/2026
      (mais 11 movimentações)

      📌 Acesse: https://jusmonitoria.witdev.com.br/processos?caso=8280d983-5b78-4460-8b78-6b7388385d44

      📄 Processo 0001234-00.2025.8.06.0001 2 novas movimentações encontradas:
      17/04/2026 10:36:10 - conclusos para decisao
      09/04/2026 14:38:48 - juntada de peticao de contestacao

      📌 Acesse: https://jusmonitoria.witdev.com.br/processos?caso=8280d983-5b78-4460-8b78-xxxxxxxxxx
    TEXT
  }.freeze

  def self.fetch(variable_name)
    VALUES[variable_name]
  end
end
