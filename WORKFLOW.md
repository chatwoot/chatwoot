# 🧠 Workflow de Desenvolvimento — Agência Nokk

Este projeto é baseado no Chatwoot (open-source) e mantido pela Agência Nokk.

Nosso foco é:
- **simplicidade**
- **velocidade**
- **controle**
- **deploy contínuo via Railway**

## 🌳 Estrutura de Branches

Usamos apenas duas branches fixas:

- `develop` → base do Chatwoot (NÃO CODAR AQUI)
- `nokk` → branch principal da Agência Nokk (PRODUÇÃO)

### Regras:

- ❌ Nunca desenvolver diretamente na `develop`
- ❌ Nunca desenvolver diretamente na `nokk`
- ✅ Toda feature nasce a partir da `nokk`

## 🌱 Criando uma nova feature (OBRIGATÓRIO)

### 1️⃣ Sempre comece pela `nokk`

```bash
git checkout nokk
git pull origin nokk
```

### 2️⃣ Crie uma branch de feature

**Padrão de nome:**
```
feature/nome-curto-da-feature
```

**Exemplos:**
- `feature/uazapi-integration`
- `feature/white-label`
- `feature/ai-routing`

**Comando:**
```bash
git checkout -b feature/nome-da-feature
```

### 3️⃣ Desenvolva normalmente

- commits pequenos e claros
- sem medo de iterar

**Padrão de commit (recomendado):**
- `feat: descrição curta`
- `fix: correção pontual`
- `refactor: melhoria interna`

**Exemplo:**
```bash
git commit -m "feat: integrar UAZAPI com Chatwoot"
```

## 🔁 Finalizando uma feature

### 4️⃣ Atualize a branch `nokk` (se necessário)

Antes de abrir PR:

```bash
git checkout nokk
git pull origin nokk
git checkout feature/nome-da-feature
git merge nokk
```

👉 **Resolva conflitos na branch da feature, nunca na `nokk`.**

### 5️⃣ Merge para `nokk`

1. Abra Pull Request
2. Base: `nokk`
3. Review rápido
4. Merge aprovado

📌 **Todo merge na `nokk` gera deploy automático no Railway.**

## 🚀 Deploy

- A branch `nokk` é ligada ao Railway
- Qualquer merge nela → deploy automático
- Não existe deploy manual

## 🔄 Atualizando o Chatwoot (quando necessário)

Esse passo é raro e consciente.

```bash
git checkout develop
git fetch upstream
git merge upstream/develop
git checkout nokk
git merge develop
```

📌 Resolver conflitos com calma  
📌 Nunca fazer isso no meio de uma feature

## ❌ O que NÃO fazer

- ❌ Commit direto na `nokk`
- ❌ Commit direto na `develop`
- ❌ Forçar merge sem PR
- ❌ Atualizar upstream sem alinhamento
- ❌ Deploy manual fora do Railway

## 🏷️ Identidade do Projeto

Este projeto é mantido pela **Agência Nokk**.

- White-label permitido
- Customizações centralizadas na `nokk`
- Integrações (UAZAPI, WhatsApp API, IA) fazem parte do core do produto

## 🧨 Resumo rápido

- Tudo nasce da `nokk`, tudo volta pra `nokk`.
- `develop` = base
- `nokk` = produto
- `feature/*` = trabalho diário
- Railway = deploy automático

