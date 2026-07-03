class Api::V1::Accounts::Autonomia::Agents::BuilderImagesController < Api::V1::Accounts::Autonomia::BaseController
  # MULTIMODAL (Construtor/Ajustar — async): upload de UMA imagem do builder. Espelha o
  # EmailCampaigns::AssetsController, mas valida SÓ imagem (sem vídeo/PDF) e NÃO cria Source/conhecimento
  # — a imagem é DADO efêmero lida inline pelo modelo no turno em que for anexada. Detecta o content-type
  # do conteúdo (Marcel) e não confia no header do cliente. Retorna o signed_id para o turno referenciar;
  # o Builder resolve o blob (revalidando tipo/tamanho) no job. NUNCA loga o conteúdo da imagem.
  def create
    file = params[:file]
    return render_unprocessable(I18n.t('autonomia.image_required')) if file.blank?

    content_type = detected_content_type(file)
    return render_unprocessable(I18n.t('autonomia.image_invalid_type')) unless image_type?(content_type)
    return render_unprocessable(I18n.t('autonomia.image_too_large')) if file.size > Autonomia::Agents::Config::MAX_IMAGE_BYTES

    file.tempfile.rewind
    # TENANCY: grava a conta dona no metadata do blob — o Builder só resolve signed_ids cujo blob
    # foi criado no contexto da MESMA conta (Builder#image_part), mesmo com signed_id válido.
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file.tempfile, filename: file.original_filename, content_type: content_type, identify: false,
      metadata: { autonomia_account_id: Current.account.id }
    )
    # signed_id PURPOSE-BOUND + expirável: só resolvível pelo builder (mesmo purpose) e por tempo
    # limitado — um signed_id vazado de outra feature/contexto não vira imagem do builder.
    render json: {
      signed_id: blob.signed_id(purpose: :autonomia_builder_image, expires_in: 1.day),
      content_type: content_type
    }
  end

  private

  def detected_content_type(file)
    file.tempfile.rewind
    Marcel::MimeType.for(file.tempfile).to_s
  ensure
    file.tempfile.rewind if file.respond_to?(:tempfile) && file.tempfile
  end

  def image_type?(content_type)
    Autonomia::Agents::Config::IMAGE_CONTENT_TYPES.include?(content_type)
  end
end
