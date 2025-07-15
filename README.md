# ValidadorCNPJ_SQL (com parâmetros dinâmicos)

Script modular Spark SQL que valida CNPJs alfanuméricos com base nos dígitos verificadores DV1/DV2 conforme regras da Receita Federal.

---
## 🚀 Funcionalidades

- ✅ Limpeza e normalização do campo CNPJ
- 🔢 Cálculo de DV1 e DV2 com pesos corretos
- 🔍 Diagnóstico linha a linha com identificação de válidos/inválidos
- 📋 Geração opcional de tabela de log com registros inválidos
- 📦 Estrutura modular pronta para notebooks, jobs e pipelines agendados

---

## 🧰 Requisitos

- Databricks (ou ambiente com suporte a Spark SQL)
- Tabela de entrada com campo de CNPJ contendo valores mistos alfanuméricos
- Coluna contendo o CNPJ com até 14 caracteres (sem formatação)

---

## ⚙️ Parâmetros de entrada

Os placeholders são mantidos no script e substituídos **via notebook que chama este notebook**, utilizando `dbutils.notebook.run()`:

| Parâmetro       | Tipo     | Obrigatório | Exemplo           |
|----------------|----------|-------------|-------------------|
| `tabela_origem` | texto    | ✅           | `empresas_delta`  |
| `coluna_cnpj`   | texto    | ✅           | `cnpj`            |
| `tabela_log`    | texto    | ❌ (opcional) | `log_invalidos`   |

---

## 🧭 Como usar

1. Crie um notebook de execução (chamador):

### python
dbutils.widgets.text("tabela_origem", "empresas_delta")
dbutils.widgets.text("coluna_cnpj", "cnpj")
dbutils.widgets.text("tabela_log", "")  # pode deixar vazio

dbutils.notebook.run(
  "/Caminho/para/ValidadorCNPJ_SQL",
  timeout_seconds=300,
  arguments={
    "tabela_origem": dbutils.widgets.get("tabela_origem"),
    "coluna_cnpj": dbutils.widgets.get("coluna_cnpj"),
    "tabela_log": dbutils.widgets.get("tabela_log")
  }
)

📋 Diagnóstico Produzido
A view resultado_validacao retorna:

cnpj: campo original

cnpj_limpo: versão tratada

dv1, dv2: dígitos calculados

dv1_original, dv2_original: extraídos do CNPJ

valido: TRUE se bate com os dígitos; FALSE caso contrário

🛡️ Regras de Validação
- O CNPJ deve ter **14 caracteres alfanuméricos**
- Os dois últimos caracteres devem corresponder aos **dígitos verificadores calculados**
- A conversão é feita com base na fórmula:
  - `ord(caractere) - 48` → valor usado no módulo 11

📦 Organização Sugerida

ValidadorCNPJ_SQL/
├── validador_cnpj.sql        # script SQL com placeholders
├── README.md                 # instruções de uso

---

## 🤝 Contribuição

Sugestões, melhorias e adaptações são muito bem-vindas. Fique à vontade para adaptar o script ao seu contexto específico, incluir novos critérios ou automatizar sua execução em pipelines SQL.

---

📄 Licença
Distribuído sob licença MIT.





