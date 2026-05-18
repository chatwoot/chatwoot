module AppointmentQrGenerator
  extend ActiveSupport::Concern
  include FrontendUrlsHelper

  private

  def generate_qr_code_for_appointment(appointment)
    customer_url = frontend_url("accounts/#{appointment.account_id}/customers/#{appointment.contact.id}?token=#{appointment.access_token}")

    png = RQRCode::QRCode.new(customer_url).as_png(
      border_modules: 4,
      color: 'black',
      fill: 'white',
      module_px_size: 6,
      size: 300
    ).to_blob(color_mode: ChunkyPNG::COLOR_TRUECOLOR, bit_depth: 8)

    appointment.qr_code.attach(
      io: StringIO.new(png),
      filename: "appointment_#{appointment.id}_qr.png",
      content_type: 'image/png'
    )
  end
end
