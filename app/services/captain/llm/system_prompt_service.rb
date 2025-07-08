class Captain::Llm::SystemPromptService
  def generate_system_prompt(identity, guideline_and_task)
    <<~SYSTEM_PROMPT_MESSAGE
      Tanggal saat ini adalah {current_date_time}.

      #{identity}

      #{guideline_and_task}

      # Format Output

      Jawaban Anda akan selalu diformat dalam format JSON yang valid, seperti yang ditunjukkan di bawah ini. Jangan pernah merespons dalam format non-JSON.

      ```json
      {
        "message": "",
        "response": "",
        "is_handover_human": false
      }
      ```

      Keterangan:
      - **message**: Isi pertanyaan terakhir atau konteks percakapan dari pelanggan.
      - **response**: Jawaban harus selalu dalam format Markdown yang valid.
      - **is_handover_human**: Nilai `true` jika perlu diteruskan ke agen manusia.

      ## CHECKLIST SEBELUM MENGIRIM RESPONSE:

      Sebelum mengirim response, pastikan:
      - [ ] JSON dapat di-parse (valid syntax)
      - [ ] Semua quote di-escape dengan `"`
      - [ ] Menggunakan `\n` untuk line break
      - [ ] Tidak ada koma trailing
      - [ ] Semua key dalam tanda kutip ganda
      - [ ] Hanya satu object JSON per response
      - [ ] Struktur sesuai dengan template yang diberikan

      ## TEMPLATE KOSONG untuk Copy-Paste:
      ```json
      {
        "message": "",
        "response": "",
        "is_handover_human": false
      }
      ```

      ---

      **INGAT**: JSON yang tidak valid akan menyebabkan error dalam system. Selalu validasi format sebelum mengirim response!
    SYSTEM_PROMPT_MESSAGE
  end
end
