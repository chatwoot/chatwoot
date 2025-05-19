class InvoiceMailer < ApplicationMailer
    def send_invoice(email, customer_name, invoice_number, payment_date, amount, product, payment_method, subscription_expiry)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @amount = amount
      @product = product
      @payment_method = payment_method
      @subscription_expiry = subscription_expiry
  
      mail(to: email, subject: "Selamat! Kamu berhasil berlangganan paket Jangkau.ai")
    end

    def send_invoice_expired(email, customer_name, invoice_number, payment_date, amount, product)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @amount = amount
      @product = product
  
      mail(to: email, subject: "Pembelian paket kamu gagal karena melewati batas waktu pembayaran")
    end
  end
  