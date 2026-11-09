# LifeUp AV2 — API REST

API de sincronização do tema **Monitoramento Pessoal & Hábitos** (AP2B).

## Integrantes (Grupo 04)

- Allan Scherrer Santos
- Maxuel Peçanha Silva
- Gabriel de Oliveira Palmeiras
- Rafael de Almeida Pereira
- Matheus Anholetti Pessoa de Souza

## Stack

- Dart 3 + Shelf
- PostgreSQL (schema `lifeUpAv2`)
- Docker (deploy no Render)

## Documentação (Swagger)

Com a API rodando:

- Swagger UI: http://localhost:8080/swagger
- OpenAPI: http://localhost:8080/openapi.yaml
- Atalho: http://localhost:8080/docs → redireciona para `/swagger`

No Swagger você consegue ver e testar os endpoints (Try it out).

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/swagger` | Swagger UI |
| GET | `/openapi.yaml` | Spec OpenAPI 3 |
| GET | `/health` | Health check |
| POST | `/auth/register` | Cadastro `{nome, nome_usuario, senha}` |
| POST | `/auth/login` | Login `{nome_usuario, senha}` |
| GET/POST | `/usuarios/:id/habitos` | Listar / upsert hábito |
| PUT/DELETE | `/usuarios/:id/habitos/:habitoId` | Atualizar / remover |
| GET/POST | `/usuarios/:id/metas` | Listar / upsert meta |
| PUT/DELETE | `/usuarios/:id/metas/:metaId` | Atualizar / remover |
| GET/POST | `/usuarios/:id/registros` | Listar / upsert registro |
| PUT/DELETE | `/usuarios/:id/registros/:registroId` | Atualizar / remover |
| POST | `/usuarios/:id/sync` | Sync Offline-First (lote) |
| GET | `/usuarios/:id/backup` | Backup consolidado |

Body do sync:

```json
{
  "habitos": [],
  "metas": [],
  "registros": []
}
```

## Local

```bash
cd life_up_av2_api
copy .env.example .env
# edite o .env com host/usuário/senha do PostgreSQL

dart pub get
dart run bin/server.dart
```

A API lê automaticamente o arquivo `.env` (não precisa exportar `DATABASE_URL` no terminal).

Teste: `http://localhost:8080/health`

## Deploy no Render

1. New → Web Service → conecte o repositório (root: `life_up_av2_api`)
2. Runtime: **Docker** (usa o `Dockerfile` do projeto)
3. Environment:
   - `DATABASE_URL` = Internal/External URL do PostgreSQL do Render
4. Deploy

A API cria o schema/tabelas automaticamente na subida.

## Declaração de Uso de IA

Cursor foi usado como apoio na estruturação da API Shelf, rotas de sync e documentação de deploy.
