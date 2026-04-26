class BackfillSpinPipelineStages < ActiveRecord::Migration[7.1]
  def up
    # Rename old slugs to new SPIN-based slugs for existing accounts.
    # fechado_ganho and perdido keep their slugs (unchanged).
    slug_map = {
      'novo_lead' => 'entrada_pesquisa',
      'qualificado' => 'conexao_situacao',
      'negociacao' => 'proposta_negociacao'
    }

    name_map = {
      'entrada_pesquisa' => 'Entrada & Pesquisa',
      'conexao_situacao' => 'Conexão & Situação',
      'proposta_negociacao' => 'Proposta & Negociação'
    }

    slug_map.each do |old_slug, new_slug|
      # If new code ran before this migration, the seeder may have already
      # created stages with the target slug. Remove those duplicates first
      # to avoid unique-index violations on (account_id, slug).
      execute <<~SQL.squish
        DELETE FROM synapseos_pipeline_stages
        WHERE slug = '#{new_slug}'
          AND account_id IN (
            SELECT account_id FROM synapseos_pipeline_stages WHERE slug = '#{old_slug}'
          )
      SQL

      execute <<~SQL.squish
        UPDATE synapseos_pipeline_stages
        SET slug = '#{new_slug}', name = '#{name_map[new_slug]}'
        WHERE slug = '#{old_slug}'
      SQL
    end
  end

  def down
    slug_map = {
      'entrada_pesquisa' => 'novo_lead',
      'conexao_situacao' => 'qualificado',
      'proposta_negociacao' => 'negociacao'
    }

    name_map = {
      'novo_lead' => 'Novo Lead',
      'qualificado' => 'Qualificado',
      'negociacao' => 'Negociação'
    }

    slug_map.each do |new_slug, old_slug|
      execute <<~SQL.squish
        UPDATE synapseos_pipeline_stages
        SET slug = '#{old_slug}', name = '#{name_map[old_slug]}'
        WHERE slug = '#{new_slug}'
      SQL
    end
  end
end
