# frozen_string_literal: true

module BrazilCustomizations
  # Service para validação de documentos brasileiros
  class DocumentValidatorService
    # Valida CPF brasileiro
    def self.valid_cpf?(cpf)
      return false unless cpf
      
      # Remove caracteres não numéricos
      cpf = cpf.gsub(/\D/, '')
      
      # Verifica se tem 11 dígitos
      return false unless cpf.length == 11
      
      # Verifica se não são todos os dígitos iguais
      return false if cpf.chars.uniq.length == 1
      
      # Calcula primeiro dígito verificador
      sum = 0
      10.times { |i| sum += cpf[i].to_i * (10 - i) }
      first_digit = 11 - (sum % 11)
      first_digit = 0 if first_digit >= 10
      
      return false unless cpf[9].to_i == first_digit
      
      # Calcula segundo dígito verificador
      sum = 0
      11.times { |i| sum += cpf[i].to_i * (11 - i) }
      second_digit = 11 - (sum % 11)
      second_digit = 0 if second_digit >= 10
      
      cpf[10].to_i == second_digit
    end
    
    # Valida CNPJ brasileiro
    def self.valid_cnpj?(cnpj)
      return false unless cnpj
      
      # Remove caracteres não numéricos
      cnpj = cnpj.gsub(/\D/, '')
      
      # Verifica se tem 14 dígitos
      return false unless cnpj.length == 14
      
      # Verifica se não são todos os dígitos iguais
      return false if cnpj.chars.uniq.length == 1
      
      # Pesos para primeiro dígito
      weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      
      # Calcula primeiro dígito verificador
      sum = 0
      12.times { |i| sum += cnpj[i].to_i * weights1[i] }
      first_digit = sum % 11
      first_digit = first_digit < 2 ? 0 : 11 - first_digit
      
      return false unless cnpj[12].to_i == first_digit
      
      # Pesos para segundo dígito
      weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      
      # Calcula segundo dígito verificador
      sum = 0
      13.times { |i| sum += cnpj[i].to_i * weights2[i] }
      second_digit = sum % 11
      second_digit = second_digit < 2 ? 0 : 11 - second_digit
      
      cnpj[13].to_i == second_digit
    end
    
    # Formata CPF para exibição
    def self.format_cpf(cpf)
      return cpf unless cpf
      
      clean = cpf.gsub(/\D/, '')
      return cpf unless clean.length == 11
      
      "#{clean[0..2]}.#{clean[3..5]}.#{clean[6..8]}-#{clean[9..10]}"
    end
    
    # Formata CNPJ para exibição
    def self.format_cnpj(cnpj)
      return cnpj unless cnpj
      
      clean = cnpj.gsub(/\D/, '')
      return cnpj unless clean.length == 14
      
      "#{clean[0..1]}.#{clean[2..4]}.#{clean[5..7]}/#{clean[8..11]}-#{clean[12..13]}"
    end
    
    # Detecta e formata automaticamente CPF ou CNPJ
    def self.format_document(document)
      return document unless document
      
      clean = document.gsub(/\D/, '')
      
      case clean.length
      when 11
        format_cpf(clean)
      when 14
        format_cnpj(clean)
      else
        document
      end
    end
    
    # Valida qualquer documento brasileiro
    def self.valid_document?(document)
      return false unless document
      
      clean = document.gsub(/\D/, '')
      
      case clean.length
      when 11
        valid_cpf?(clean)
      when 14
        valid_cnpj?(clean)
      else
        false
      end
    end
    
    # Retorna tipo do documento
    def self.document_type(document)
      return nil unless document
      
      clean = document.gsub(/\D/, '')
      
      case clean.length
      when 11
        'CPF'
      when 14
        'CNPJ'
      else
        nil
      end
    end
  end
end 