-- ╔════════════════════════════════════════════╗
-- ║      Módulo: Validador de CNPJ Alfanumérico ║
-- ║      Versão: 1.0                             ║
-- ║      Autora: Lilian Kotvan                  ║
-- ║      Finalidade: Limpar, validar e diagnosticar CNPJs alfanuméricos com base nos dígitos verificadores DV1 e DV2. ║
-- ╚════════════════════════════════════════════╝


-- Parâmetros recebidos via notebook de execução:
-- {{tabela_origem}}, {{coluna_cnpj}}, {{tabela_log}} (opcional)


-- ──────────────────────────────────────────────────────────────
-- 1️⃣ Criação da Tabela ASCII - 48 (referência para cálculo dos DVs)
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE TEMP VIEW ascii_map AS
SELECT * FROM VALUES
  ('0', 0), ('1', 1), ('2', 2), ('3', 3), ('4', 4), ('5', 5),
  ('6', 6), ('7', 7), ('8', 8), ('9', 9),
  ('A', 17), ('B', 18), ('C', 19), ('D', 20), ('E', 21), ('F', 22),
  ('G', 23), ('H', 24), ('I', 25), ('J', 26), ('K', 27), ('L', 28),
  ('M', 29), ('N', 30), ('O', 31), ('P', 32), ('Q', 33), ('R', 34),
  ('S', 35), ('T', 36), ('U', 37), ('V', 38), ('W', 39), ('X', 40),
  ('Y', 41), ('Z', 42)
AS ascii_map(caractere, valor_ascii);

-- ──────────────────────────────────────────────────────────────
-- 2️⃣ Limpeza do CNPJ e formatação alfanumérica
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE TEMP VIEW cnpj_formatado AS
SELECT UPPER(REGEXP_REPLACE({{coluna_cnpj}}, '[^A-Z0-9]', '')) AS cnpj_limpo, *
FROM {{tabela_origem}}
WHERE LENGTH(REGEXP_REPLACE({{coluna_cnpj}}, '[^A-Z0-9]', '')) = 14;

-- ──────────────────────────────────────────────────────────────
-- 3️⃣ Cálculo do primeiro dígito verificador (DV1)
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE TEMP VIEW dv1_calculo AS
SELECT base.*, 
       SUM(am.valor_ascii * peso) AS soma_dv1,
       CASE WHEN SUM(am.valor_ascii * peso) % 11 < 2 THEN 0 ELSE 11 - (SUM(am.valor_ascii * peso) % 11) END AS dv1
FROM (
  SELECT cnpj_limpo, {{coluna_cnpj}}, pos+1 AS posicao,
         SUBSTRING(cnpj_limpo, pos+1, 1) AS caractere,
         CASE pos+1 WHEN 1 THEN 5 WHEN 2 THEN 4 WHEN 3 THEN 3 WHEN 4 THEN 2
                    WHEN 5 THEN 9 WHEN 6 THEN 8 WHEN 7 THEN 7 WHEN 8 THEN 6
                    WHEN 9 THEN 5 WHEN 10 THEN 4 WHEN 11 THEN 3 WHEN 12 THEN 2
         END AS peso
  FROM cnpj_formatado
  LATERAL VIEW posexplode(split(cnpj_limpo, '')) AS pos, char
  WHERE pos < 12
) base
JOIN ascii_map am ON base.caractere = am.caractere
GROUP BY base.cnpj_limpo, base.{{coluna_cnpj}};

-- ──────────────────────────────────────────────────────────────
-- 4️⃣ Cálculo do segundo dígito verificador (DV2)
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE TEMP VIEW dv2_calculo AS
SELECT etapa1.*, 
       SUM(am.valor_ascii * peso) AS soma_dv2,
       CASE WHEN SUM(am.valor_ascii * peso) % 11 < 2 THEN 0 ELSE 11 - (SUM(am.valor_ascii * peso) % 11) END AS dv2
FROM (
  SELECT cnpj_limpo, {{coluna_cnpj}}, dv1,
         CONCAT(SUBSTRING(cnpj_limpo, 1, 12), CAST(dv1 AS STRING)) AS base_dv2,
         pos+1 AS posicao,
         SUBSTRING(CONCAT(SUBSTRING(cnpj_limpo, 1, 12), CAST(dv1 AS STRING)), pos+1, 1) AS caractere,
         CASE pos+1 WHEN 1 THEN 6 WHEN 2 THEN 5 WHEN 3 THEN 4 WHEN 4 THEN 3
                    WHEN 5 THEN 2 WHEN 6 THEN 9 WHEN 7 THEN 8 WHEN 8 THEN 7
                    WHEN 9 THEN 6 WHEN 10 THEN 5 WHEN 11 THEN 4 WHEN 12 THEN 3 WHEN 13 THEN 2
         END AS peso
  FROM dv1_calculo
  LATERAL VIEW posexplode(split(CONCAT(SUBSTRING(cnpj_limpo, 1, 12), CAST(dv1 AS STRING)), '')) AS pos, char
  WHERE pos < 13
) etapa1
JOIN ascii_map am ON etapa1.caractere = am.caractere
GROUP BY etapa1.cnpj_limpo, etapa1.{{coluna_cnpj}}, etapa1.dv1;

-- ──────────────────────────────────────────────────────────────
-- 5️⃣ Validação final e geração de diagnóstico
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE TEMP VIEW resultado_validacao AS
SELECT 
  {{coluna_cnpj}} AS cnpj,
  cnpj_limpo,
  dv1,
  dv2,
  SUBSTRING(cnpj_limpo, 13, 1) AS dv1_original,
  SUBSTRING(cnpj_limpo, 14, 1) AS dv2_original,
  CASE
    WHEN dv1_original = CAST(dv1 AS STRING)
     AND dv2_original = CAST(dv2 AS STRING)
    THEN TRUE ELSE FALSE
  END AS valido
FROM dv2_calculo;

-- ──────────────────────────────────────────────────────────────
-- 6️⃣ (Opcional) Criação da tabela de log para registros inválidos
-- ──────────────────────────────────────────────────────────────
-- Execute esta etapa apenas se {{tabela_log}} for informado e existir
-- Caso contrário, ignore ou comente este bloco

-- CREATE OR REPLACE TABLE {{tabela_log}}
-- AS SELECT cnpj, valido FROM resultado_validacao WHERE valido = FALSE;

