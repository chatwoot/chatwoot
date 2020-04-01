class ContactIdentifyAction
  pattr_initialize [:contact!, :params!]

  def perform
    ActiveRecord::Base.transaction do
      return true
    end
  end
end
