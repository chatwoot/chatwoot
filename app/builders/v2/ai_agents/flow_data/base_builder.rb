class V2::AiAgents::FlowData::BaseBuilder
  attr_reader :account, :templates, :params

  def initialize(account, templates, params)
    @account = account
    @templates = templates
    @params = params
  end

  def perform(collection_name = 'default_collection')
    tpl = base_template
    tpl[:type] = @params[:agent_type]
    if @params[:agent_type] == AiAgent.agent_types[:multi_agent]
      @templates.each do |template|
        tpl[:enabled_agents] << template.name_id
        tpl[:supervisor][:system_prompt] = supervisor_prompt
        tpl[:supervisor][:routing_system] << {
          name: template.name_id,
          description: template.description
        }
      end
    end
    tpl[:agents_config] = @templates.map { |template| agent_object(template, collection_name) }
    tpl
  end

  private

  def agent_object(template, collection_name = 'default_collection')
    {
      type: template.name_id,
      name: template.name,
      description: template.description,
      bot_prompt: template.system_prompt,
      configurations: {},
      collection_name: collection_name,
      tools: [
        {
          name: 'default_tool'
        }
      ]
    }
  end

  def base_template
    raise NotImplementedError, 'Subclass must implement base_template'
  end

  def supervisor_prompt
    <<~PROMPT
      Anda adalah Supervisor AI yang bertugas untuk mengarahkan setiap pertanyaan pengguna ke agen yang paling relevan berdasarkan aturan berikut:\n\n- customer_service: Menangani pertanyaan terkait layanan pelanggan seperti keluhan, bantuan akun, pengembalian dana, status pesanan, atau pertanyaan umum seputar produk dan layanan.\n- booking: Menangani permintaan pemesanan seperti membuat, mengubah, atau membatalkan reservasi; pengecekan ketersediaan jadwal; serta pertanyaan terkait konfirmasi dan detail pemesanan.\n\nJangan memberikan jawaban langsung kepada pengguna. Tugas Anda adalah menganalisis maksud pertanyaan dan memilih agen yang sesuai.
    PROMPT
  end
end
