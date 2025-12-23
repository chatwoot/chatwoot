-- Função helper para gerar embed tokens via SQL
-- NOTA: Esta função apenas cria o registro no banco.
-- O JWT token ainda precisa ser gerado externamente usando a chave secreta.

CREATE OR REPLACE FUNCTION generate_embed_token_data(
  p_user_id BIGINT,
  p_account_id BIGINT,
  p_inbox_id BIGINT DEFAULT NULL,
  p_note TEXT DEFAULT NULL
) RETURNS TABLE(
  token_id BIGINT,
  jti TEXT,
  token_digest TEXT,
  user_id BIGINT,
  account_id BIGINT,
  inbox_id BIGINT
) AS $$
DECLARE
  v_jti TEXT;
  v_token_digest TEXT;
  v_token_id BIGINT;
  v_user_exists BOOLEAN;
  v_account_exists BOOLEAN;
  v_account_user_exists BOOLEAN;
BEGIN
  -- Validar que usuário existe e está confirmado
  SELECT EXISTS(
    SELECT 1 FROM users 
    WHERE id = p_user_id AND confirmed_at IS NOT NULL
  ) INTO v_user_exists;
  
  IF NOT v_user_exists THEN
    RAISE EXCEPTION 'Usuário não encontrado ou não confirmado: %', p_user_id;
  END IF;
  
  -- Validar que conta existe
  SELECT EXISTS(
    SELECT 1 FROM accounts WHERE id = p_account_id
  ) INTO v_account_exists;
  
  IF NOT v_account_exists THEN
    RAISE EXCEPTION 'Conta não encontrada: %', p_account_id;
  END IF;
  
  -- Validar que usuário tem acesso à conta
  SELECT EXISTS(
    SELECT 1 FROM account_users 
    WHERE user_id = p_user_id AND account_id = p_account_id
  ) INTO v_account_user_exists;
  
  IF NOT v_account_user_exists THEN
    RAISE EXCEPTION 'Usuário % não tem acesso à conta %', p_user_id, p_account_id;
  END IF;
  
  -- Validar inbox se fornecido
  IF p_inbox_id IS NOT NULL THEN
    IF NOT EXISTS(
      SELECT 1 FROM inboxes 
      WHERE id = p_inbox_id AND account_id = p_account_id
    ) THEN
      RAISE EXCEPTION 'Inbox % não encontrada ou não pertence à conta %', p_inbox_id, p_account_id;
    END IF;
  END IF;
  
  -- Gerar UUID
  v_jti := gen_random_uuid()::TEXT;
  
  -- Calcular SHA256
  v_token_digest := encode(digest(v_jti, 'sha256'), 'hex');
  
  -- Inserir no banco
  INSERT INTO embed_tokens (
    jti, token_digest, user_id, account_id, inbox_id,
    note, created_at, updated_at
  ) VALUES (
    v_jti, v_token_digest, p_user_id, p_account_id, p_inbox_id,
    p_note, NOW(), NOW()
  ) RETURNING id INTO v_token_id;
  
  RETURN QUERY SELECT 
    v_token_id,
    v_jti,
    v_token_digest,
    p_user_id,
    p_account_id,
    p_inbox_id;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
-- SELECT * FROM generate_embed_token_data(1, 1, NULL, 'Embed gerado via SQL');
-- Retorna: token_id, jti, token_digest, user_id, account_id, inbox_id
-- Use o jti retornado para gerar o JWT externamente
