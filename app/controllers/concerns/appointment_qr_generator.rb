module AppointmentQrGenerator
  extend ActiveSupport::Concern
  include FrontendUrlsHelper

  private

  def generate_qr_code_for_appointment(appointment)
    customer_url = frontend_url("accounts/#{appointment.account_id}/customers/#{appointment.contact.id}?token=#{appointment.access_token}")

    qr_code = RQRCode::QRCode.new(customer_url)
    png = qr_code.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 300
    )

    appointment.qr_code.attach(
      io: StringIO.new(png.to_s),
      filename: "appointment_#{appointment.id}_qr.png",
      content_type: 'image/png'
    )
  end
end
