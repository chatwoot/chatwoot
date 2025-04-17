class InvoiceMailer < ApplicationMailer
    def send_invoice(email, customer_name, invoice_number, payment_date, amount, product)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @amount = amount
      @product = product
  
      mail(to: email, subject: "Invoice ##{@invoice_number} Telah Dibayar")
    end
  end
  