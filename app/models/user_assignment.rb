# == Schema Information
#
# Table name: user_assignments
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  advanced_email_template_id :bigint           not null
#  user_id                    :bigint           not null
#
# Indexes
#
#  index_user_assignments_on_advanced_email_template_id  (advanced_email_template_id)
#  index_user_assignments_on_template_and_user           (advanced_email_template_id,user_id) UNIQUE
#  index_user_assignments_on_user_id                     (user_id)
#  index_user_assignments_on_user_id_and_active          (user_id,active)
#
# Foreign Keys
#
#  fk_rails_...  (advanced_email_template_id => advanced_email_templates.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class UserAssignment < ApplicationRecord
  belongs_to :advanced_email_template
  belongs_to :user

  has_one :account, through: :advanced_email_template

  validates :advanced_email_template_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :advanced_email_template_id }
  validate :user_belongs_to_template_account

  before_save :deactivate_other_templates, if: :will_save_change_to_active?

  private

  def user_belongs_to_template_account
    return unless user && advanced_email_template

    return if user.account_users.exists?(account_id: advanced_email_template.account_id)

    errors.add(:user, 'must belong to the same account as the template')
  end

  def deactivate_other_templates
    return unless active?

    template_name = advanced_email_template.name
    template_account_id = advanced_email_template.account_id

    UserAssignment.joins(:advanced_email_template)
                  .where(user_id: user_id, active: true)
                  .where(advanced_email_templates: {
                           name: template_name,
                           account_id: template_account_id
                         })
                  .where.not(id: id)
                  .update_all(active: false) # rubocop:disable Rails/SkipsModelValidations
  end
end
