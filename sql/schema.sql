-- LifeUp AV2 — schema PostgreSQL (Render / local)
CREATE SCHEMA IF NOT EXISTS "lifeUpAv2";
SET search_path TO "lifeUpAv2";

CREATE TABLE IF NOT EXISTS usuarios (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    nome_usuario    VARCHAR(80) NOT NULL UNIQUE,
    senha_hash      VARCHAR(255) NOT NULL,
    data_cadastro   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS habitos (
    id              VARCHAR(64) PRIMARY KEY,
    usuario_id      INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nome            VARCHAR(120) NOT NULL,
    descricao       TEXT,
    tipo            VARCHAR(40) NOT NULL,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    data_criacao    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS metas (
    id              VARCHAR(64) PRIMARY KEY,
    usuario_id      INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo            VARCHAR(20) NOT NULL,
    titulo          VARCHAR(160) NOT NULL,
    descricao       TEXT,
    valor_objetivo  NUMERIC(12, 2) NOT NULL,
    valor_atual     NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente',
    data_criacao    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_meta_usuario_tipo UNIQUE (usuario_id, tipo)
);

CREATE TABLE IF NOT EXISTS registros (
    id              VARCHAR(64) PRIMARY KEY,
    usuario_id      INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    habito_id       VARCHAR(64) REFERENCES habitos(id) ON DELETE SET NULL,
    valor           NUMERIC(12, 2) NOT NULL,
    observacao      TEXT,
    data_registro   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_habitos_usuario ON habitos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_metas_usuario ON metas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_registros_usuario ON registros(usuario_id);
