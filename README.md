# LifeUp (AV2 — API REST)

> API de sincronização Offline-First da Avaliação Processual 2B (Shelf + PostgreSQL).  
> O app Flutter correspondente está em `../life_up_av2_app`.  
> A base CLI da AP1B permanece em `../life_up_av1`.

## Descrição

> LifeUp AV2 API é o backend REST do tema Monitoramento Pessoal & Hábitos. Expõe autenticação, CRUD de hábitos/metas/registros e o endpoint de sync em lote usado pelo app Flutter Offline-First, persistindo em PostgreSQL (schema `lifeUpAv2`).

Projeto prático da disciplina **Computação Móvel** (AP2B) — Curso de Sistemas de Informação.

**Grupo 04**

---

## Integrantes

* Allan Scherrer Santos
* Maxuel Peçanha Silva
* Gabriel de Oliveira Palmeiras
* Rafael de Almeida Pereira
* Matheus Anholetti Pessoa de Souza

---

## Tema

```text
Tema 03 — Monitoramento Pessoal & Hábitos Conectados
```

---

## Tecnologias

```text
Dart 3
Shelf + shelf_router
PostgreSQL (package postgres)
dotenv
crypto (hash de senha)
Docker (deploy no Render)
OpenAPI / Swagger UI
```

---

## Arquitetura

O projeto separa HTTP, repositórios e banco:

```text
bin/server.dart
 ↓
api_router (rotas Shelf)
 ↓
Repositories (SQL / regras de persistência)
 ↓
DatabaseConnection
 ↓
PostgreSQL (schema "lifeUpAv2")
```

| Camada | Responsabilidade |
|--------|------------------|
| **bin/server.dart** | Bootstrap, CORS, porta, health |
| **routes** | Endpoints REST + docs Swagger |
| **repositories** | Usuario, Habito, Meta, Registro + sync/backup |
| **database / config** | Conexão PostgreSQL e `search_path` |
| **utils** | Hash/verificação de senha |
| **public** | `openapi.yaml` + Swagger UI |

---

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/swagger` | Swagger UI |
| GET | `/openapi.yaml` | Spec OpenAPI 3 |
| GET | `/docs` | Redireciona para `/swagger` |
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

Documentação interativa (com a API rodando):

* Swagger UI: http://localhost:8080/swagger
* OpenAPI: http://localhost:8080/openapi.yaml

---

## Como configurar

### 1. Instalar Dart

Instale o [Dart SDK](https://dart.dev/get-dart) (versão 3.x).

Verifique:

```bash
dart --version
```

### 2. Instalar PostgreSQL (local)

Instale o [PostgreSQL](https://www.postgresql.org/download/) e garanta que o serviço esteja em execução.  
No Render, use o PostgreSQL gerenciado e a `DATABASE_URL`.

### 3. (Opcional) Executar o schema

```powershell
$env:PGPASSWORD = "sua_senha"
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" "host=SEU_HOST port=5432 dbname=SEU_BANCO user=SEU_USUARIO sslmode=require" -f sql/schema.sql
```

> Em muitos ambientes a API **cria schema/tabelas automaticamente** na subida. O `sql/schema.sql` serve de referência / bootstrap manual.

### 4. Criar o arquivo `.env`

```bash
copy .env.example .env
```

Edite host, usuário, senha e banco. O arquivo `.env` **não** é versionado (está no `.gitignore`).

A API lê o `.env` automaticamente (não é obrigatório exportar `DATABASE_URL` no terminal em desenvolvimento local).

---

## Como instalar dependências

Na pasta `life_up_av2_api`:

```bash
dart pub get
```

---

## Como executar

```bash
cd life_up_av2_api
dart run bin/server.dart
```

Ao subir com sucesso:

```text
Servidor em http://0.0.0.0:8080
Swagger: http://localhost:8080/swagger
Health:  http://localhost:8080/health
```

Teste rápido: abra `http://localhost:8080/health` no navegador.

### Testes

```bash
dart test
```

---

## Deploy no Render

1. New → Web Service → conecte o repositório (root directory: `life_up_av2_api`).
2. Runtime: **Docker** (usa o `Dockerfile` do projeto).
3. Environment:
   - `DATABASE_URL` = Internal/External URL do PostgreSQL do Render.
4. Deploy.

A API cria o schema/tabelas automaticamente na subida.  
No app Flutter, use:

```bash
flutter run --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

---

## Estrutura de pastas

```text
life_up_av2_api/
├── bin/server.dart
├── lib/
│   ├── config/
│   ├── database/
│   ├── docs/
│   ├── http/
│   ├── repositories/
│   ├── routes/
│   └── utils/
├── public/
│   ├── openapi.yaml
│   └── swagger.html
├── sql/
│   └── schema.sql
├── test/
├── Dockerfile
├── render.yaml
├── .env.example
├── README.md
└── pubspec.yaml
```

---

## App Flutter

Cliente Offline-First: [`../life_up_av2_app`](../life_up_av2_app)

No emulador Android, o host da máquina é `10.0.2.2` (ex.: `http://10.0.2.2:8080`).

---

## Declaração de Uso de IA

Ferramentas de Inteligência Artificial foram usadas como apoio durante o desenvolvimento:

**Cursor:** Apoio na estruturação da API Shelf, rotas de sync/backup, schema PostgreSQL, Swagger/OpenAPI e documentação de deploy no Render.

**ChatGPT:** Apoio em dúvidas de HTTP REST, organização de repositórios e revisão da documentação.

O uso foi de suporte à implementação. A configuração do banco, a validação dos endpoints, o deploy e a integração com o app Flutter ficaram a cargo do grupo.

### Exemplos de prompts utilizados

* “Como montar um router Shelf com CORS e health check?”
* “Como modelar um endpoint de sync em lote para app Offline-first?”
* “Como publicar OpenAPI/Swagger estático junto com a API Dart?”
* “Checklist de variáveis de ambiente para deploy Docker no Render.”
* “Revisa se o README da API ficou claro para configurar PostgreSQL e rodar localmente.”

---

## Referências

* Dart Language Tour: https://dart.dev/language
* Package `shelf`: https://pub.dev/packages/shelf
* Package `shelf_router`: https://pub.dev/packages/shelf_router
* Package `postgres`: https://pub.dev/packages/postgres
* Package `dotenv`: https://pub.dev/packages/dotenv
* PostgreSQL Documentation: https://www.postgresql.org/docs/
* OpenAPI Specification: https://swagger.io/specification/
* Render Docs (Web Services): https://render.com/docs/web-services
