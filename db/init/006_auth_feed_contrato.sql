-- 006_auth_feed_contrato.sql
-- Migração para alinhar cadastro/login + feed unificado sem dados mockados.
-- PostgreSQL (idempotente, com IF EXISTS / IF NOT EXISTS quando possível).

BEGIN;

-- -------------------------------------------------------------------
-- Extensões
-- -------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -------------------------------------------------------------------
-- Usuários (cadastro público + login)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_type TEXT NOT NULL CHECK (profile_type IN ('estudante', 'comunidade', 'empresa', 'universidade')),
  role TEXT NOT NULL CHECK (role IN ('padrao', 'comunidade', 'empresa', 'universidade', 'sistema_admin')),
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 13),
  cpf TEXT NOT NULL UNIQUE,
  institution TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,

  -- comunidade
  community_type TEXT,
  community_name TEXT,

  -- empresa
  company_name TEXT,
  company_cnpj TEXT,
  company_description TEXT,

  -- universidade
  institution_name TEXT,
  institution_acronym TEXT,
  institution_type TEXT,
  institution_description TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users (email);
CREATE INDEX IF NOT EXISTS idx_app_users_role ON app_users (role);
CREATE INDEX IF NOT EXISTS idx_app_users_profile_type ON app_users (profile_type);

-- Garantia de consistência de campos por profile_type
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_name = 'app_users'
      AND constraint_name = 'app_users_profile_type_fields_check'
  ) THEN
    ALTER TABLE app_users DROP CONSTRAINT app_users_profile_type_fields_check;
  END IF;

  ALTER TABLE app_users
    ADD CONSTRAINT app_users_profile_type_fields_check CHECK (
      (profile_type = 'estudante') OR
      (profile_type = 'comunidade' AND community_type IN ('atletica', 'ca') AND community_name IS NOT NULL) OR
      (profile_type = 'empresa' AND company_name IS NOT NULL) OR
      (profile_type = 'universidade' AND institution_name IS NOT NULL)
    );
END
$$;

-- -------------------------------------------------------------------
-- Escopo de publicação em recursos publicáveis
-- -------------------------------------------------------------------
-- Recursos esperados no backend:
-- oportunidades, eventos, grupos, leituras semanais, projetos, avisos
-- Todos passam a aceitar:
-- publish_scope: all|group
-- publish_group_id: obrigatório quando publish_scope=group

DO $$
DECLARE
  t TEXT;
  tables_to_update TEXT[] := ARRAY[
    'opportunities',
    'events',
    'groups',
    'weekly_readings',
    'projects',
    'university_notices'
  ];
BEGIN
  FOREACH t IN ARRAY tables_to_update LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_name = t
    ) THEN
      EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS publish_scope TEXT NOT NULL DEFAULT ''all''', t);
      EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS publish_group_id TEXT', t);

      BEGIN
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', t, t || '_publish_scope_check');
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
      EXECUTE format(
        'ALTER TABLE %I ADD CONSTRAINT %I CHECK (publish_scope IN (''all'',''group''))',
        t, t || '_publish_scope_check'
      );

      BEGIN
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', t, t || '_publish_group_consistency_check');
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
      EXECUTE format(
        'ALTER TABLE %I ADD CONSTRAINT %I CHECK (
          (publish_scope = ''all'' AND publish_group_id IS NULL) OR
          (publish_scope = ''group'' AND publish_group_id IS NOT NULL)
        )',
        t, t || '_publish_group_consistency_check'
      );
    END IF;
  END LOOP;
END
$$;

-- -------------------------------------------------------------------
-- Feed unificado (discover)
-- -------------------------------------------------------------------
-- tabela canônica esperada: feed_cartoes
-- kinds oficiais de contrato:
-- internship | event | study_group | project | notice | reading
-- Compatibilidade:
-- se existir "campus_feed", converte para "reading"

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'feed_cartoes'
  ) THEN
    ALTER TABLE feed_cartoes
      ADD COLUMN IF NOT EXISTS publish_scope TEXT NOT NULL DEFAULT 'all',
      ADD COLUMN IF NOT EXISTS publish_group_id TEXT;

    -- compatibilidade com colunas antigas visibility_*
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'feed_cartoes' AND column_name = 'visibility_scope'
    ) THEN
      UPDATE feed_cartoes
      SET publish_scope = COALESCE(NULLIF(visibility_scope, ''), publish_scope)
      WHERE publish_scope IS NULL OR publish_scope = 'all';
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'feed_cartoes' AND column_name = 'visibility_group_id'
    ) THEN
      UPDATE feed_cartoes
      SET publish_group_id = COALESCE(visibility_group_id, publish_group_id)
      WHERE publish_group_id IS NULL;
    END IF;

    -- compatibilidade de kind legado
    UPDATE feed_cartoes
    SET kind = 'reading'
    WHERE kind = 'campus_feed';

    -- remove e recria checks principais
    ALTER TABLE feed_cartoes DROP CONSTRAINT IF EXISTS feed_cartoes_kind_check;
    ALTER TABLE feed_cartoes
      ADD CONSTRAINT feed_cartoes_kind_check
      CHECK (kind IN ('internship', 'event', 'study_group', 'project', 'notice', 'reading'));

    ALTER TABLE feed_cartoes DROP CONSTRAINT IF EXISTS feed_cartoes_publish_scope_check;
    ALTER TABLE feed_cartoes
      ADD CONSTRAINT feed_cartoes_publish_scope_check
      CHECK (publish_scope IN ('all', 'group'));

    ALTER TABLE feed_cartoes DROP CONSTRAINT IF EXISTS feed_cartoes_publish_group_consistency_check;
    ALTER TABLE feed_cartoes
      ADD CONSTRAINT feed_cartoes_publish_group_consistency_check
      CHECK (
        (publish_scope = 'all' AND publish_group_id IS NULL) OR
        (publish_scope = 'group' AND publish_group_id IS NOT NULL)
      );

    CREATE INDEX IF NOT EXISTS idx_feed_cartoes_kind ON feed_cartoes (kind);
    CREATE INDEX IF NOT EXISTS idx_feed_cartoes_publish_scope ON feed_cartoes (publish_scope);
    CREATE INDEX IF NOT EXISTS idx_feed_cartoes_publish_group_id ON feed_cartoes (publish_group_id);
  END IF;
END
$$;

-- View utilitária para /api/discover
-- Mantém shape de contrato:
-- id, kind, title, subtitle, excerpt, meta_primary, meta_secondary, reference_id, publish_scope, publish_group_id
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'feed_cartoes'
  ) THEN
    EXECUTE $view$
      CREATE OR REPLACE VIEW discover_feed_v1 AS
      SELECT
        id,
        kind,
        title,
        subtitle,
        excerpt,
        meta_primary,
        meta_secondary,
        reference_id,
        publish_scope,
        publish_group_id
      FROM feed_cartoes
    $view$;
  END IF;
END
$$;

COMMIT;
