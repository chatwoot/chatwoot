class RemoveImportCursorFromChannelEmail < ActiveRecord::Migration[7.1]
  # A coluna entrou para um import de uma vez so, que saiu do produto e foi para o
  # repositorio do cliente, onde guarda o cursor num arquivo. Removida por migration e nao
  # apagando a que a criou: quem ja rodou aquela tem a coluna no banco, e apagar o arquivo
  # deixa o schema novo sem ela enquanto todo banco atualizado fica com ela para sempre.
  def change
    remove_column :channel_email, :import_cursor, :jsonb, default: {}, null: false
  end
end
