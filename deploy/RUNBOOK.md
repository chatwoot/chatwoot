# Runbook — Deploy Chatwoot Pro na VPS em 3 comandos

Fabricio, eu já preparei **tudo** que dá para preparar antes do servidor. O que
falta é coisa que **só você pode fazer** (acesso à VPS, decisão sobre domínio).
Abaixo o caminho mais curto possível.

---

## O que está pronto

Em `C:\Users\Fabricio\chatwootPro\release\`:

- **`chatwoot-pro-overlay.tar.gz`** (1.1 MB) — contém só o que é seu:
  - `engines/chatwoot_kanban/` — engine completo
  - `engines/chatwoot_glpi_integration/` — engine GLPI (para depois)
  - `app/javascript/dashboard/modules/kanban/` — frontend pronto
  - `deploy/` — scripts e configs:
    - `bootstrap-vps.sh` — instala tudo na VPS
    - `apply-host-edits.sh` — patches no fork (se vier de outro caminho)
    - `docker-compose.yml`
    - `Caddyfile`
    - `VPS_DEPLOY.md`, `SMOKE_TESTS.md`

A ideia: você sobrepõe esse overlay sobre um clone fresco do seu fork no VPS,
e o `bootstrap-vps.sh` faz o resto.

---

## Pré-requisitos (você precisa ter)

- [ ] VPS Ubuntu 22.04 ou Debian 12 (mínimo 2 vCPU / 4 GB RAM)
- [ ] Acesso SSH root ou sudo
- [ ] Domínio com registro **A** apontando para o IP da VPS
  - Ex: `chatwoot.minhaempresa.com` → `203.0.113.42`
  - **Confirme antes** com: `dig chatwoot.minhaempresa.com +short`

---

## Os 3 comandos

Substitua `SEU_IP_VPS`, `chatwoot.exemplo.com`, `admin@exemplo.com` pelos seus valores reais.

### Comando 1 — do seu PC, enviar o overlay para a VPS

```sh
scp C:\Users\Fabricio\chatwootPro\release\chatwoot-pro-overlay.tar.gz root@SEU_IP_VPS:/root/
```

> No Windows, use Git Bash, WSL ou PowerShell.

### Comando 2 — entrar na VPS, clonar seu fork, aplicar overlay

```sh
ssh root@SEU_IP_VPS

# (já dentro da VPS)
apt-get update && apt-get install -y git curl
cd /opt
git clone https://github.com/fabriciomuaca1989/chatwoot-pro.git
cd chatwoot-pro
tar xzf /root/chatwoot-pro-overlay.tar.gz
bash deploy/apply-host-edits.sh .
```

Você verá:
```
[1/5] Gemfile... added.
[2/5] config/routes.rb... mounted.
[3/5] app/javascript/dashboard/store/index.js... registered.
[4/5] app/javascript/dashboard/routes/dashboard/dashboard.routes.js... registered.
[5/5] Symlinking frontend... already exists, skipping.
DONE.
```

### Comando 3 — rodar o bootstrap (faz TUDO o resto)

```sh
./deploy/bootstrap-vps.sh chatwoot.exemplo.com admin@exemplo.com
```

O script vai:

1. Instalar Docker (se não tiver)
2. Gerar todos os secrets (SECRET_KEY_BASE, senhas Postgres/Redis, chaves de criptografia Rails)
3. Escrever `.env` e `Caddyfile`
4. Abrir portas 80/443 no firewall
5. **Buildar a imagem Docker do seu fork** (10–25 min na primeira vez)
6. Subir Postgres + Redis e esperar ficarem prontos
7. Rodar **TODAS** as migrations (Chatwoot + 9 do Kanban engine)
8. Subir Rails + Sidekiq + Caddy
9. **Criar usuário admin** com senha aleatória forte
10. Criar um Kanban board padrão com auto-create de cards a partir de conversas
11. Imprimir credenciais finais

Ao final você vê algo como:

```
========================================================================
  Chatwoot Pro is UP at  https://chatwoot.exemplo.com
========================================================================

  Admin email:    admin@exemplo.com
  Admin password: Kj7nQp8sLm2vXr9wB1AAa1!

  Kanban board:   https://chatwoot.exemplo.com/app/accounts/1/kanban

STORE THE ADMIN PASSWORD NOW — it will not be shown again.
```

**Anote a senha imediatamente.**

---

## Validação rápida (5 min)

1. Abra `https://chatwoot.exemplo.com` no navegador
2. Faça login com `admin@exemplo.com` + a senha gerada
3. No menu lateral, abra `https://chatwoot.exemplo.com/app/accounts/1/kanban` direto pela URL
4. Você deve ver um board "Inbox principal" com 3 colunas (Backlog / Doing / Done)
5. Crie um card, arraste entre colunas — deve funcionar
6. Abra a mesma URL em outra aba, mova um card — a outra aba **atualiza sozinha** (real-time funcionando)

Se algo falhar, consulte `deploy/SMOKE_TESTS.md` no VPS — tem 16 testes diagnósticos.

---

## O que eu **não** posso fazer por você

| Tarefa | Por quê | Onde clicar |
|---|---|---|
| Comprar a VPS | Precisa do seu cartão | Hetzner, DigitalOcean, Vultr, Contabo |
| Configurar DNS | Precisa do seu painel do registrador | Registro.br, Cloudflare, Namecheap |
| SSH na VPS | Precisa da sua senha/chave SSH | seu terminal |
| Push para o GitHub | Precisa das suas credenciais | `git push origin feat/kanban-engine` |
| Decidir o domínio final | Decisão sua | — |

Tudo o resto está automatizado.

---

## Item no sidebar (manual, 1 min)

O Chatwoot mudou a estrutura do `Sidebar.vue` recentemente, então o script não
mexe nele. Para adicionar o item de menu Kanban no UI:

```sh
# Na VPS, dentro de /opt/chatwoot-pro:
docker compose exec rails sh -c 'cat app/javascript/dashboard/components/layout/Sidebar.vue' | head -50
```

Identifique a estrutura da navegação principal e adicione um item apontando
para `/app/accounts/:accountId/kanban`. Depois rebuilde o frontend:

```sh
docker compose build rails
docker compose up -d rails
```

Por enquanto, acesso direto pela URL funciona perfeitamente.

---

## Para depois — adicionar GLPI

Quando o Kanban estiver rodando e estável (1 ou 2 dias):

```sh
cd /opt/chatwoot-pro

# Adicionar gem no Gemfile
echo "gem 'chatwoot_glpi_integration', path: 'engines/chatwoot_glpi_integration'" >> Gemfile

# Adicionar mount no routes.rb (antes do último 'end')
sed -i "/^end$/i\\  mount ChatwootGlpiIntegration::Engine => '/'" config/routes.rb

# Rebuild e migrate
docker compose build
docker compose run --rm rails bundle exec rails db:migrate
docker compose up -d
```

Depois configure a conexão GLPI em `Settings → Integrations → GLPI` no UI
(ou via `rails console` se preferir).

---

## Troubleshooting rápido

**O bootstrap travou no build do Docker.**
- Veja a mensagem exata. Se for OOM (out of memory), aumente o swap:
  ```sh
  fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  ```

**HTTPS não funciona, vejo "connection refused" ou erro de certificado.**
- DNS ainda não propagou. Aguarde 5–60 min. Veja com `dig +short SEU_DOMINIO`.
- Cheque os logs do Caddy: `docker compose logs caddy | tail -50`

**Login falha com "invalid credentials" mesmo com a senha certa.**
- Reset via console:
  ```sh
  docker compose exec rails bundle exec rails c
  # User.find_by(email: 'admin@exemplo.com').update!(password: 'NovaSenha123!')
  ```

**Kanban não aparece (página em branco em /kanban).**
- Rebuilde o frontend: `docker compose build rails && docker compose up -d rails`

**WebSocket não conecta, vejo "Couldn't open connection on Cable" no console do navegador.**
- Caddy precisa de upgrade. Já está configurado. Verifique se `wss://` funciona com:
  ```sh
  curl -i https://SEU_DOMINIO/cable -H "Upgrade: websocket" -H "Connection: Upgrade"
  ```
  Esperado: HTTP/1.1 426 Upgrade Required.

---

Boa sorte. Quando estiver no ar, me avisa o domínio e eu te ajudo com os
próximos passos (sidebar Vue, integração GLPI, métricas).
