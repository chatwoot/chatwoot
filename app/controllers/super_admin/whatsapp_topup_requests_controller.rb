class SuperAdmin::WhatsappTopupRequestsController < SuperAdmin::ApplicationController
  def approve
    requested_resource.update!(status: :approved)
    redirect_back(fallback_location: [namespace, :whatsapp_topup_requests])
  end

  def reject
    requested_resource.update!(status: :rejected)
    redirect_back(fallback_location: [namespace, :whatsapp_topup_requests])
  end
end
