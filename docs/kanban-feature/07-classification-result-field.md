# Fase 7 — Campo "Resultado" no formulário de classificações

## Objetivo
Expor o `classification_type` (já existente no banco como enum `standard / won / lost`) no formulário de criação/edição de `ConversationClassification`. O backend está pronto e o `CardSyncService` já consome esse campo — a feature de "classificações com destino" funciona hoje, só falta a UI deixar configurar.

Esta é a fase mais simples e rápida do conjunto.

---

## Mudanças de schema

**Nenhuma.** O enum `classification_type` em `conversation_classifications` já existe (`standard: 0`, `won: 1`, `lost: 2`).

---

## Novas classes / serviços e responsabilidades

**Nenhuma.** Apenas extensões.

### Backend

#### Strong params do controller
Verificar [app/controllers/api/v1/accounts/conversation_classifications_controller.rb](app/controllers/api/v1/accounts/conversation_classifications_controller.rb) (ou nome similar) e garantir que `classification_type` está em `permit(...)`. Adicionar se faltar.

#### Serializer / jbuilder
Garantir que `classification_type` é retornado no JSON da classificação.

#### Validação
Já existe enum no model — Rails valida automaticamente. Adicionar validação adicional:
- Se classificação está em uso por conversas (cards) e tenta-se mudar `classification_type` de `won/lost` para `standard`, **permitir mas com cautela**: cards já movidos pra coluna won/lost não retornam (movimentação histórica). Aceitável; documentar comportamento.

---

## Pontos de integração com código existente

| Arquivo | Mudança |
|---|---|
| [app/controllers/api/v1/accounts/conversation_classifications_controller.rb](app/controllers/api/v1/accounts/conversation_classifications_controller.rb) | Garantir `classification_type` em strong params |
| Serializer/jbuilder de classification | Garantir campo no payload |
| Frontend: form de classificação (caminho a confirmar) | Adicionar campo "Resultado" |
| `config/locales/en.json` | Strings i18n |

**Descobrir o caminho do form ANTES de codar:**
```bash
grep -rn 'conversation.*classification\|ConversationClassification' app/javascript/dashboard/routes/dashboard/settings/
```
**Documentar o caminho encontrado na descrição do PR3.**

---

## Endpoints novos ou modificados

Nenhum endpoint novo. Endpoints existentes de classification ganham/expõem o campo `classification_type` (provavelmente já expõem; verificar).

---

## Mudanças no frontend

### Form de criação/edição

Adicionar um `<select>` (ou radio group) com 3 opções:

| Valor backend | Label UI (en.json) |
|---|---|
| `standard` | `Default` |
| `won` | `Won deal` |
| `lost` | `Closed without sale` |

**Label "Closed without sale" — decisão fixa:**
- Justificativa do brief: classificações como "Apenas informações" não são derrotas comerciais.
- O `enum` no banco continua `lost` — só o label da UI muda.
- Não é decisão pendente; aplicado direto.

**Posicionamento no form:**
- Logo abaixo do campo "Nome", antes do campo "Posição" (se existir).
- Default ao criar: `standard`.
- Edit: pré-selecionado conforme `classification_type` retornado.

### I18n

```json
{
  "CONVERSATION_CLASSIFICATIONS": {
    "FORM": {
      "RESULT_LABEL": "Result",
      "RESULT_HELP": "Defines what this classification represents in the kanban: a won deal, a closure without sale, or just a label.",
      "RESULT_OPTIONS": {
        "STANDARD": "Default",
        "WON": "Won deal",
        "LOST": "Closed without sale"
      }
    }
  }
}
```

(Apenas en.json conforme CLAUDE.md.)

### Tooltip / help text

Abaixo do select:
> Move o card para a coluna correspondente quando a conversa for resolvida com essa classificação.

---

## Trade-offs e decisões não óbvias

### 1. Não validar mudança de `won/lost → standard` em classificações em uso
- Histórico de cards movidos não retroage.
- Adiciona complexidade desnecessária. Aceitar comportamento natural.

### 2. Label "Closed without sale" vs. "Lost deal"
- Manter abertura para alteração durante review (single-line change na i18n).
- Não há impacto técnico — apenas posicionamento de produto.

### 3. Não introduzir tipo `paused` ou outros agora
- Brief lista apenas 2 (won/lost), o enum suporta mais se futuro pedir.
- Engine de macros (Fase 4) pode ler `classification_type` em conditions futuras (ex: "se classificação é won, aplicar tag X").

### 4. Form simples, sem wizard
- Classification é entidade pequena; wizard seria overkill.

### 5. Não auto-criar coluna won/lost ao mudar tipo de classificação
- O modelo já tem `KanbanColumn` com enum `column_type` (`standard/won/lost`) e `KanbanBoard` cria as 3 colunas padrão automaticamente na criação do board.
- Se uma conta deletou a coluna won, a classificação `won` fica órfã (CardSyncService falha silenciosamente). Não é preocupação desta fase.
- **Follow-up registrado:** abrir issue no PR3 para validação de coexistência (classificação `won` exige coluna `won`). UI alerta admin.

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Frontend antigo cacheado não envia `classification_type` | Backend default é `standard` (enum 0); compatibilidade preservada |
| Backend não tinha o campo em strong params (rejection silenciosa) | Auditar e adicionar antes de FE |
| Usuário cria classificação `lost` mas board não tem coluna `lost` | CardSyncService falha em mover; log mas não bloqueia resolução. Polish: alerta na UI |

---

## Critérios de aceite (validação manual)
1. Admin abre form de criação de classificação → vê campo "Result" com 3 opções.
2. Cria classificação "Cliente fechou contrato" com Result = "Won deal" → persiste com `classification_type: won`.
3. Edit pré-seleciona o valor correto.
4. Resolver conversa escolhendo essa classificação → card move pra coluna `won`. (Comportamento já existente; valida que UI não quebrou nada.)
5. Classificações antigas sem mudança → continuam funcionando como `standard`.
6. Strings em UI vêm de i18n (sem hardcoded).
