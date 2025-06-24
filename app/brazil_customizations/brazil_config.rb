# frozen_string_literal: true

# Configuração central para customizações brasileiras do Chatwoot
module BrazilCustomizations
  class Config
    # Configurações de localização
    TIMEZONE = 'America/Sao_Paulo'
    LOCALE = 'pt-BR'
    CURRENCY = 'BRL'
    
    # Configurações de horário comercial brasileiro
    BUSINESS_HOURS = {
      weekdays: { start: '08:00', end: '18:00' },
      saturday: { start: '08:00', end: '12:00' },
      sunday: :closed,
      timezone: TIMEZONE
    }.freeze
    
    # Templates padrão em português brasileiro
    AUTO_RESPONSES = {
      greeting: 'Olá! 👋 Bem-vindo(a) ao nosso atendimento!',
      business_hours: '📍 Nosso horário de atendimento é de segunda a sexta, das 8h às 18h.',
      weekend: 'Recebemos sua mensagem! Nossa equipe retornará na segunda-feira.',
      outside_hours: 'Obrigado pelo contato! Retornaremos no próximo horário comercial.',
      queue_notification: '🕐 No momento temos {{queue_size}} pessoas à sua frente. Aguarde alguns minutos.',
      first_contact: 'Olá! Seja bem-vindo(a). Em que posso ajudá-lo(a) hoje?'
    }.freeze
    
    # Configurações do WhatsApp Brasil
    WHATSAPP_CONFIG = {
      country_code: '+55',
      number_validation: /\A\+55\d{2}9?\d{8}\z/,
      formatting: lambda { |number|
        # Formatar número brasileiro: +55 (11) 99999-9999
        clean = number.gsub(/\D/, '')
        return number unless clean.match?(/\A55\d{10,11}\z/)
        
        area_code = clean[2..3]
        if clean.length == 13 # Celular com 9
          "#{clean[0..1]} (#{area_code}) #{clean[4]}#{clean[5..8]}-#{clean[9..12]}"
        else # Fixo ou celular antigo
          "#{clean[0..1]} (#{area_code}) #{clean[4..7]}-#{clean[8..11]}"
        end
      }
    }.freeze
    
    # Cores do tema brasileiro
    THEME_COLORS = {
      primary: '#00875F',      # Verde brasileiro
      secondary: '#FFD700',    # Amarelo brasileiro
      accent: '#1E40AF',       # Azul confiança
      success: '#059669',      # Verde sucesso
      warning: '#D97706',      # Laranja atenção
      danger: '#DC2626',       # Vermelho perigo
      text_primary: '#1F2937', # Cinza escuro
      text_secondary: '#6B7280', # Cinza médio
      bg_light: '#F8FAFC',     # Fundo claro
      bg_white: '#FFFFFF'      # Branco puro
    }.freeze
    
    # Features enterprise ativadas no fork brasileiro
    ENTERPRISE_FEATURES = %w[
      disable_branding
      audit_logs
      sla
      custom_roles
      captain_integration
      help_center_embedding_search
    ].freeze
    
    # Integrações brasileiras disponíveis
    BRAZILIAN_INTEGRATIONS = {
      viacep: {
        enabled: true,
        url: 'https://viacep.com.br/ws',
        description: 'Busca de endereço por CEP'
      },
      correios: {
        enabled: true,
        description: 'Integração com Correios para rastreamento'
      },
      pix: {
        enabled: true,
        description: 'Geração de links de pagamento PIX'
      },
      cpf_cnpj: {
        enabled: true,
        description: 'Validação de CPF e CNPJ'
      }
    }.freeze
    
    # Configurações de acessibilidade
    ACCESSIBILITY_CONFIG = {
      min_contrast_ratio: 4.5, # WCAG AA
      focus_indicators: true,
      screen_reader_support: true,
      keyboard_navigation: true,
      high_contrast_mode: true
    }.freeze
    
    # Métricas e KPIs brasileiros
    BRAZILIAN_METRICS = {
      response_time_target: 120, # 2 minutos em segundos
      resolution_rate_target: 0.7, # 70%
      csat_target: 4.5, # 4.5/5
      mobile_usage_target: 0.6 # 60%
    }.freeze
    
    class << self
      # Verifica se uma feature enterprise está ativada
      def enterprise_feature_enabled?(feature_name)
        ENTERPRISE_FEATURES.include?(feature_name.to_s)
      end
      
      # Retorna configuração de horário comercial para um dia específico
      def business_hours_for(day)
        case day.downcase.to_sym
        when :sunday
          nil
        when :saturday
          BUSINESS_HOURS[:saturday]
        else
          BUSINESS_HOURS[:weekdays]
        end
      end
      
      # Verifica se está dentro do horário comercial
      def within_business_hours?(time = Time.current)
        return false unless time
        
        time = time.in_time_zone(TIMEZONE)
        day_config = business_hours_for(time.strftime('%A'))
        
        return false if day_config.nil? || day_config == :closed
        
        start_time = Time.zone.parse("#{time.to_date} #{day_config[:start]}")
        end_time = Time.zone.parse("#{time.to_date} #{day_config[:end]}")
        
        time.between?(start_time, end_time)
      end
      
      # Formata número de telefone brasileiro
      def format_brazilian_phone(number)
        return number unless number
        
        WHATSAPP_CONFIG[:formatting].call(number)
      end
      
      # Valida se o número é brasileiro válido
      def valid_brazilian_phone?(number)
        return false unless number
        
        WHATSAPP_CONFIG[:number_validation].match?(number)
      end
      
      # Retorna saudação adequada baseada no horário
      def greeting_for_time(time = Time.current)
        time = time.in_time_zone(TIMEZONE)
        hour = time.hour
        
        case hour
        when 5..11
          'Bom dia! ☀️'
        when 12..17
          'Boa tarde! ⛅'
        when 18..23, 0..4
          'Boa noite! 🌙'
        else
          'Olá! 👋'
        end
      end
    end
  end
end 