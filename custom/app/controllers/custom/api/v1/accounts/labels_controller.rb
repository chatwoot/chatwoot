module Custom::Api::V1::Accounts::LabelsController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_labels_quota, only: [:create]
  end

  private

  def check_labels_quota
    check_quota(:labels)
  end
end
