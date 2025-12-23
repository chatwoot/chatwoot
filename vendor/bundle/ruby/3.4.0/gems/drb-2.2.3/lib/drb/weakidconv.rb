# frozen_string_literal: false
require_relative 'drb'

module DRb

  # DRb::WeakIdConv is deprecated since 2.2.1. You don't need to use
  # DRb::WeakIdConv instead of DRb::DRbIdConv. It's the same class.
  #
  # This file still exists for backward compatibility.
  #
  # To use WeakIdConv:
  #
  #  DRb.start_service(nil, nil, {:idconv => DRb::WeakIdConv.new})

  def self.const_missing(name) # :nodoc:
    case name
    when :WeakIdConv
      warn("DRb::WeakIdConv is deprecated. " +
           "You can use the DRb::DRbIdConv. " +
           "You don't need to use this.",
           uplevel: 1)
      const_set(:WeakIdConv, DRbIdConv)
      singleton_class.remove_method(:const_missing)
      DRbIdConv
    else
      super
    end
  end
end

# DRb.install_id_conv(WeakIdConv.new)
