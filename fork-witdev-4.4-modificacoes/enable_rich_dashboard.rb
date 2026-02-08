#!/usr/bin/env ruby
# frozen_string_literal: true

# Script para habilitar a feature flag SOCIALWISE_RICH_DASHBOARD
# Execute no Rails console ou como script

puts "🔧 Habilitando SOCIALWISE_RICH_DASHBOARD para todas as contas..."

# Método 1: Habilitar para conta específica (ID 3 baseado no log)
account = Account.find(3)
account.enable_features('SOCIALWISE_RICH_DASHBOARD')
puts "✅ Feature habilitada para conta #{account.id} (#{account.name})"

# Método 2: Habilitar para todas as contas (opcional)
# Account.find_each do |account|
#   account.enable_features('SOCIALWISE_RICH_DASHBOARD')
#   puts "✅ Feature habilitada para conta #{account.id} (#{account.name})"
# end

# Verificar se foi habilitada
if account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
  puts "🎉 SOCIALWISE_RICH_DASHBOARD está HABILITADA para conta #{account.id}"
else
  puts "❌ SOCIALWISE_RICH_DASHBOARD ainda está DESABILITADA para conta #{account.id}"
end

puts "\n📋 Features habilitadas para esta conta:"
puts account.enabled_features.inspect