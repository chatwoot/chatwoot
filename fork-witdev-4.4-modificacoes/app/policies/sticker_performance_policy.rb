# frozen_string_literal: true

class StickerPerformancePolicy < ApplicationPolicy
  def show?
    # Allow administrators and account owners to view performance metrics
    user.administrator? || user.account_owner?
  end

  def index?
    show?
  end

  def usage_stats?
    show?
  end

  def cache_performance?
    show?
  end

  def api_performance?
    show?
  end

  def benchmark_image_processing?
    # Only administrators can run benchmarks
    user.administrator?
  end

  def system_health?
    # Only administrators can view system health
    user.administrator?
  end
end