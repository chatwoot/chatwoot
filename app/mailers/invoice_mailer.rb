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

    def mau_send_invoice(email, customer_name, invoice_number, payment_date, amount, product, payment_method, mau_total)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @amount = amount
      @product = product
      @payment_method = payment_method
      @mau_total = mau_total
  
      mail(to: email, subject: "🎉 Top-up MAU kamu berhasil – saldo langsung aktif!")
    end

    def mau_send_invoice_expired(email, customer_name, invoice_number, payment_date, payment_method, amount, mau_total)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @payment_method = payment_method
      @amount = amount
      @mau_total = mau_total
  
      mail(to: email, subject: "⚠️ Top-up MAU kamu gagal – lewat batas waktu pembayaran")
    end

    def ai_send_invoice(email, customer_name, invoice_number, payment_date, amount, product, payment_method, response_total)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @amount = amount
      @product = product
      @payment_method = payment_method
      @response_total = response_total
  
      mail(to: email, subject: "🎉 Top-up MAU kamu berhasil – saldo langsung aktif!")
    end

    def ai_send_invoice_expired(email, customer_name, invoice_number, payment_date, payment_method, amount, response_total)
      @customer_name = customer_name
      @invoice_number = invoice_number
      @payment_date = payment_date
      @payment_method = payment_method
      @amount = amount
      @response_total = response_total
  
      mail(to: email, subject: "⚠️ Top-up MAU kamu gagal – lewat batas waktu pembayaran")
    end
  end
  