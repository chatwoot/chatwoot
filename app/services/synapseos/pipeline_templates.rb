module Synapseos
  # Catálogo de templates de pipeline pré-configurados por segmento.
  # Cada template define stages com nome, cor, tipo e descrição (tooltip).
  # O DEFAULT_STAGES do model PipelineStage é o template :spin_generico.
  class PipelineTemplates
    TEMPLATES = {
      spin_generico: {
        name: 'SPIN + Próximo Passo (Genérico)',
        description: 'Funil universal baseado em SPIN Selling com a regra do Próximo Passo Obrigatório. Aplicável a qualquer operação B2B ou B2C consultiva.',
        stages: ::Synapseos::PipelineStage::DEFAULT_STAGES
      },

      concessionaria_online: {
        name: 'Concessionária — Atendimento Online',
        description: 'Funil para venda digital de veículos com foco em confiança remota, transparência (laudos/vídeos) e aprovação de crédito ágil.',
        stages: [
          { slug: 'triagem_resposta', name: 'Triagem & Resposta Rápida', color: '#6B7280', position: 1, stage_type: 'inbound',
            description: 'O lead caiu via portal (Webmotors, site, Instagram). Meta: responder em menos de 5 minutos. Qualifique rapidamente: que carro busca? Tem troca? Precisa financiar? Próximo passo obrigatório: agendar primeira ligação/vídeo-chamada ou envio do material no WhatsApp.' },
          { slug: 'investigacao_cenario', name: 'Investigação de Cenário', color: '#3B82F6', position: 2, stage_type: 'open',
            description: 'Entenda o motivo da troca (SPIN: Situação e Problema). O carro atual está pequeno? Dá muita manutenção? Próximo passo obrigatório: agendar envio do "Kit de Transparência" (vídeo detalhado, laudo cautelar, histórico).' },
          { slug: 'demonstracao_digital', name: 'Demonstração Digital & Prova Social', color: '#8B5CF6', position: 3, stage_type: 'working',
            description: 'Tour virtual (vídeo-chamada ou vídeo gravado personalizado). Mostre detalhes e comprove qualidade, matando a objeção de comprar sem ver (SPIN: Implicação/Necessidade). Próximo passo obrigatório: cobrar feedback e agendar simulação de financiamento ou avaliação do usado.' },
          { slug: 'simulacao_avaliacao', name: 'Simulação & Avaliação Prévia', color: '#F59E0B', position: 4, stage_type: 'working',
            description: 'Coleta de CPF para rodar ficha no banco e avaliação prévia do carro de troca por fotos/vídeos. Próximo passo obrigatório: acompanhar status do banco. Tarefa: retornar com a aprovação de crédito.' },
          { slug: 'documentacao_pagamento', name: 'Documentação & Pagamento', color: '#F97316', position: 5, stage_type: 'working',
            description: 'Negócio fechado comercialmente. Envio de contrato digital, PIX para sinal ou pagamento integral. Próximo passo obrigatório: confirmar pagamento e agendar logística de entrega.' },
          { slug: 'logistica_delivery', name: 'Logística & Delivery', color: '#10B981', position: 6, stage_type: 'won',
            description: 'Carro preparado e enviado ou retirada agendada. Próximo passo obrigatório: contato de Customer Success 48h após entrega para garantir satisfação.' },
          { slug: 'perdido', name: 'Perdido', color: '#EF4444', position: 7, stage_type: 'lost',
            description: 'Registre o motivo de perda. Adicione a cadência de nutrição para resgate em 3–6 meses.' }
        ]
      },

      audi_sdr: {
        name: 'Audi Center Uberlândia — SDR Outbound',
        description: 'Funil SDR pra cold outreach Audi: A Contatar → Tentativa → Em Relacionamento → Qualificação SPIN → Alerta/Transbordo. Lost reasons calibrados pra outbound.',
        loss_reasons: [
          'Sem Resposta (Unresponsive)',
          'Desqualificado (No Fit)',
          'Sem Interesse no Momento (Timing errado)'
        ],
        stages: [
          { slug: 'a_contatar', name: 'A Contatar', color: '#6B7280', position: 1, stage_type: 'inbound',
            description: 'Status inicial para leads importados da lista fria. Aguardando primeiro disparo da Elisa.' },
          { slug: 'tentativa_contato', name: 'Tentativa de Contato', color: '#3B82F6', position: 2, stage_type: 'inbound',
            description: 'Lead em fluxo de cadência (follow-up). Disparo enviado pela Elisa, aguardando resposta. Se ficar sem resposta por N tentativas, mover para "Perdido" com motivo "Sem Resposta".' },
          { slug: 'em_relacionamento', name: 'Em Relacionamento', color: '#8B5CF6', position: 3, stage_type: 'open',
            description: 'Lead respondeu. Fase de quebra-gelo e rapport. Elisa entende momento de vida (radar da marca, intenção de troca) sem qualificação comercial ainda.' },
          { slug: 'qualificacao_spin', name: 'Qualificação (SPIN)', color: '#F59E0B', position: 4, stage_type: 'working',
            description: 'Lead sinalizou intenção. Aplicação das perguntas SPIN: Situação (carro atual, uso), Problema (incômodos), Implicação (impacto) e Necessidade (modelo Audi que resolve). Elisa captura modelo de interesse e perfil.' },
          { slug: 'alerta_transbordo', name: 'Alerta / Transbordo', color: '#10B981', position: 5, stage_type: 'won',
            description: 'Lead qualificado. Passagem de bastão para o Closer humano via alerta Slack (sales_alert_dispatched). A partir daqui o time de vendas assume a conversa no Chatwoot.' },
          { slug: 'perdido', name: 'Perdido', color: '#EF4444', position: 6, stage_type: 'lost',
            description: 'Registre o motivo de perda usando uma das opções configuradas. Resgate em 3-6 meses pode ser tentado conforme o caso (cadência de nutrição).' }
        ]
      },

      premium_luxo: {
        name: 'Concessionária — Padrão Premium / Luxo',
        description: 'Funil para marcas premium com foco em experiência (CX), Test Drive obrigatório e cerimônia de entrega conforme padrões de montadora.',
        stages: [
          { slug: 'recepcao_premium', name: 'Recepção Premium', color: '#6B7280', position: 1, stage_type: 'inbound',
            description: 'Primeiro contato focado em hospitalidade. Tom consultivo e exclusivo. Sondagem leve sobre perfil e interesse. Próximo passo obrigatório: convite formalizado para visita ao showroom ou agendamento de Test Drive em domicílio.' },
          { slug: 'consultoria_lifestyle', name: 'Consultoria de Lifestyle', color: '#3B82F6', position: 2, stage_type: 'open',
            description: 'SPIN profundo: entenda perfil de uso — esportividade, conforto para viagens, blindagem. Ex: "Você viaja muito? O isolamento acústico do seu carro atual te deixa fadigado?" Próximo passo obrigatório: preparar Walkaround (apresentação 360°) e carro de Test Drive.' },
          { slug: 'experiencia_test_drive', name: 'Experiência & Test Drive', color: '#8B5CF6', position: 3, stage_type: 'working',
            description: 'Apresentação detalhada do design, interior e realização do Test Drive em rota pré-definida. Durante o test drive aplique SPIN: "Sentiu como o motor responde em ultrapassagens?" Próximo passo obrigatório: convidar para mesa de negociação ou agendar envio da proposta.' },
          { slug: 'avaliacao_financial', name: 'Avaliação & Financial Services', color: '#F59E0B', position: 4, stage_type: 'working',
            description: 'Avaliação física e minuciosa do seminovo na troca. Apresentação das taxas subsidiadas e condições especiais da montadora. Próximo passo obrigatório: follow-up da proposta com data definida.' },
          { slug: 'aprovacao_faturamento', name: 'Aprovação & Faturamento', color: '#F97316', position: 5, stage_type: 'working',
            description: 'Contrato assinado. Veículo pode ser encomendado sob medida ou está em trânsito. Próximo passo obrigatório: atualizar o cliente periodicamente sobre status do veículo.' },
          { slug: 'cerimonia_entrega', name: 'Cerimônia de Entrega', color: '#10B981', position: 6, stage_type: 'won',
            description: 'Entrega hiper-regulada: carro coberto na sala de entregas, kit de boas-vindas, fotos e Entrega Técnica (pareamento de app, configurações). Próximo passo obrigatório: ligar em 3–5 dias para dúvidas de tecnologia e acionar pesquisa NPS.' },
          { slug: 'perdido', name: 'Perdido', color: '#EF4444', position: 7, stage_type: 'lost',
            description: 'Registre o motivo de perda. Adicione a cadência de nutrição para resgate em 3–6 meses.' }
        ]
      },

      hospital: {
        name: 'Hospital — Cirurgias e Alta Complexidade',
        description: 'Jornada do paciente para procedimentos cirúrgicos, internações e exames de alto ticket. Foco em conversão entre diagnóstico e autorização.',
        stages: [
          { slug: 'triagem_acolhimento', name: 'Triagem & Acolhimento', color: '#6B7280', position: 1, stage_type: 'inbound',
            description: 'O paciente (ou médico parceiro) busca informações sobre procedimento, bloco cirúrgico ou internação. Entenda a via de acesso (convênio premium ou particular). Próximo passo obrigatório: agendar avaliação pré-anestésica ou consulta com o cirurgião especialista.' },
          { slug: 'avaliacao_diagnostico', name: 'Avaliação Médica & Diagnóstico', color: '#3B82F6', position: 2, stage_type: 'open',
            description: 'Médico avalia quadro clínico, risco cirúrgico e necessidade de intervenção. Investigue não só o corpo, mas o cenário logístico. Próximo passo obrigatório: solicitar exames pré-operatórios com data de retorno estipulada.' },
          { slug: 'proposta_terapeutica', name: 'Proposta Terapêutica', color: '#8B5CF6', position: 3, stage_type: 'working',
            description: 'Médico apresenta a solução (ex: cirurgia robótica). Venda o valor da infraestrutura (UTI humanizada, tecnologia, baixos índices de infecção). Próximo passo obrigatório: encaminhar para setor de Orçamentos/Autorização.' },
          { slug: 'orcamento_autorizacao', name: 'Orçamento & Autorização de Guias', color: '#F59E0B', position: 4, stage_type: 'working',
            description: 'Gargalo burocrático: aprovação de OPME junto ao convênio ou negociação do pacote particular. Próximo passo obrigatório: follow-up rigoroso — cobrar convênio com data e hora definidas. Nunca deixar o paciente sem posição.' },
          { slug: 'agendamento_bloco', name: 'Agendamento de Bloco & Pré-Operatório', color: '#F97316', position: 5, stage_type: 'working',
            description: 'Procedimento autorizado e pago/liberado. Agendamento no centro cirúrgico e reserva de leito. Próximo passo obrigatório: ligar 48h antes para orientações de jejum e checagem de documentos.' },
          { slug: 'procedimento_alta', name: 'Procedimento & Alta', color: '#10B981', position: 6, stage_type: 'won',
            description: 'Cirurgia realizada e paciente de alta. Próximo passo obrigatório: Concierge/Enfermagem liga 7 dias após alta para checar recuperação e confirmar consulta de revisão.' },
          { slug: 'perdido', name: 'Desistência / Não-Autorizado', color: '#EF4444', position: 7, stage_type: 'lost',
            description: 'Registre o motivo (convênio negou, paciente desistiu, complicação). Mantenha acompanhamento para possível retomada.' }
        ]
      },

      oncologia: {
        name: 'Clínica Oncológica — Jornada de Cuidado',
        description: 'Jornada oncológica com foco em velocidade de início de tratamento e acolhimento extremo. O CRM é pilotado por equipe multidisciplinar.',
        stages: [
          { slug: 'recepcao_diagnostico', name: 'Recepção do Diagnóstico & Navegação', color: '#6B7280', position: 1, stage_type: 'inbound',
            description: 'Paciente chega com biópsia positiva ou encaminhamento. Foco em acolhimento e redução de ansiedade. Entenda rapidamente tipo de tumor e estágio. Próximo passo obrigatório: encaixe de urgência (até 48h) com oncologista especializado.' },
          { slug: 'consulta_estadiamento', name: 'Primeira Consulta & Estadiamento', color: '#3B82F6', position: 2, stage_type: 'open',
            description: 'Oncologista avalia extensão da doença. Investigue o cenário logístico da família (acompanhante para quimio, distância da cidade). Próximo passo obrigatório: agendar exames de imagem (PET-Scan, Ressonância) ou análise molecular.' },
          { slug: 'tumor_board', name: 'Tumor Board & Plano Terapêutico', color: '#8B5CF6', position: 3, stage_type: 'working',
            description: 'Caso discutido por equipe multidisciplinar. Médico apresenta protocolo (quimio, imunoterapia, rádio). Mostre como a infraestrutura mitiga temores sobre efeitos colaterais. Próximo passo obrigatório: acionar time de autorizações de alto custo.' },
          { slug: 'liberacao_alto_custo', name: 'Liberação de Terapias de Alto Custo', color: '#F59E0B', position: 4, stage_type: 'working',
            description: 'Etapa mais crítica. Medicamentos oncológicos são caríssimos. Time de acesso negocia com operadoras para liberar protocolos. Próximo passo obrigatório: atualização proativa ao paciente a cada 2 dias úteis. Silêncio nesta fase gera desespero.' },
          { slug: 'tratamento_ativo', name: 'Ciclos de Tratamento Ativo', color: '#F97316', position: 5, stage_type: 'working',
            description: 'Paciente em rotina de infusões (quimioterapia) ou radioterapia. Próximo passo obrigatório: a cada sessão, farmácia/recepção já agenda próxima sessão e consulta de revisão de ciclo.' },
          { slug: 'followup_controle', name: 'Follow-up de Controle', color: '#10B981', position: 6, stage_type: 'won',
            description: 'Término do protocolo ativo. Paciente em fase de controle (remissão/manutenção). Próximo passo obrigatório: agendar retorno trimestral ou semestral. Paciente oncológico nunca fica sem próximo retorno.' },
          { slug: 'obito_desistencia', name: 'Óbito / Desistência', color: '#EF4444', position: 7, stage_type: 'lost',
            description: 'Registre o desfecho e motivo. Para desistências, mantenha acompanhamento ativo para possível retomada do tratamento.' }
        ]
      }
    }.freeze

    def self.list
      TEMPLATES.map do |key, tmpl|
        {
          key: key,
          name: tmpl[:name],
          description: tmpl[:description],
          stage_count: tmpl[:stages].size,
          loss_reasons: tmpl[:loss_reasons] || []
        }
      end
    end

    def self.find(key)
      TEMPLATES[key.to_sym]
    end

    # Detecta qual template está aplicado na account comparando os slugs
    # das stages atuais com cada template. Match exato (set de slugs).
    # Retorna a key do template (Symbol) ou nil se não bate com nenhum.
    def self.detect_applied(account)
      column_supported = ::Synapseos::PipelineStage.column_names.include?('slug')
      return nil unless column_supported

      current_slugs = ::Synapseos::PipelineStage
                        .where(account_id: account.id)
                        .pluck(:slug)
                        .compact
                        .sort
      return nil if current_slugs.empty?

      TEMPLATES.find do |_, tmpl|
        template_slugs = tmpl[:stages].map { |s| s[:slug] }.sort
        template_slugs == current_slugs
      end&.first
    end

    # Retorna loss_reasons do template aplicado na account. Defaults pra
    # array vazio se não detectar (fallback evita crash no frontend).
    def self.loss_reasons_for(account)
      applied = detect_applied(account)
      return [] unless applied

      TEMPLATES.dig(applied, :loss_reasons) || []
    end

    def self.apply(account, template_key)
      tmpl = find(template_key)
      raise ArgumentError, "Template '#{template_key}' not found" unless tmpl

      ActiveRecord::Base.transaction do
        ::Synapseos::PipelineStage.where(account_id: account.id).destroy_all
        tmpl[:stages].each do |attrs|
          payload = attrs.merge(account_id: account.id)
          payload = payload.except(:slug) unless ::Synapseos::PipelineStage.column_names.include?('slug')
          payload = payload.except(:description) unless ::Synapseos::PipelineStage.column_names.include?('description')
          ::Synapseos::PipelineStage.create!(payload)
        end
      end
    end
  end
end
