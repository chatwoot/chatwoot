class InvoiceMailer < ApplicationMailer
    def send_invoice(email, customer_name, invoice_number, payment_date, amount, product, payment_method, subscription_expiry)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @amount = amount
      @product = product
      @payment_method = payment_method
      @subscription_expiry = subscription_expiry
  
      mail(to: email, subject: "Invoice ##{@invoice_number} Telah Dibayar")
    end
  end
  