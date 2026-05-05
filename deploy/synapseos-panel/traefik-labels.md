# Painel Synapseos atrás do Traefik

Hoje o service `synapseos_panel` publica a porta 8000 direto no host
(`*:8000->8000/tcp`), sem HTTPS. Vamos colocá-lo atrás do Traefik em
`painel.dexidigital.com.br`.

## Pré-requisitos

1. DNS A: `painel.dexidigital.com.br` → `158.69.63.140`
2. Cert resolver `letsencryptresolver` configurado no Traefik
3. Network overlay do Traefik (assumindo `traefik`)

## Caminho 1 — via `docker service update` (rápido, sem editar manifesto)

```bash
docker service update \
  --publish-rm 8000 \
  --network-add dexinet \
  --label-add traefik.enable=true \
  --label-add traefik.docker.network=dexinet \
  --label-add 'traefik.http.routers.synapseos-panel.rule=Host(`painel.dexidigital.com.br`)' \
  --label-add traefik.http.routers.synapseos-panel.entrypoints=websecure \
  --label-add traefik.http.routers.synapseos-panel.tls=true \
  --label-add traefik.http.routers.synapseos-panel.tls.certresolver=letsencryptresolver \
  --label-add traefik.http.services.synapseos-panel.loadbalancer.server.port=8000 \
  synapseos_panel
```

> Atenção: `--publish-rm 8000` vai recrear o container. Faça em janela de baixa demanda.

## Caminho 2 — via manifesto da stack (recomendado)

Se a stack `synapseos` foi feita por manifesto, edite o YAML adicionando estas
labels ao service `panel` e remova qualquer `ports:` que publique a 8000:

```yaml
services:
  panel:
    image: natalia-panel:latest
    networks:
      - dexinet
    # NÃO publicar a 8000 no host — deixa o Traefik rotear
    deploy:
      labels:
        - traefik.enable=true
        - traefik.docker.network=dexinet
        - traefik.http.routers.synapseos-panel.rule=Host(`painel.dexidigital.com.br`)
        - traefik.http.routers.synapseos-panel.entrypoints=websecure
        - traefik.http.routers.synapseos-panel.tls=true
        - traefik.http.routers.synapseos-panel.tls.certresolver=letsencryptresolver
        - traefik.http.services.synapseos-panel.loadbalancer.server.port=8000

networks:
  dexinet:
    external: true
    name: dexinet
```

Aí redeploy:

```bash
docker stack deploy -c synapseos-stack.yml synapseos
```

## Validação

```bash
# DNS resolvendo:
dig +short painel.dexidigital.com.br

# Traefik reconheceu o router:
curl -s https://traefik.dexidigital.com.br/api/http/routers 2>/dev/null \
  | jq '.[] | select(.name | contains("synapseos-panel"))'

# Painel respondendo via HTTPS:
curl -sS -o /dev/null -w "%{http_code}\n" https://painel.dexidigital.com.br/
```
