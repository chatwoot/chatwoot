Rails.application.config.to_prepare do
  if defined?(Api::V1::Widget::MessagesController) &&
     defined?(Api::V1::Widget::MessagesControllerProxy)
    Api::V1::Widget::MessagesController.prepend(
      Api::V1::Widget::MessagesControllerProxy
    )
  end
end
