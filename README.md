# ValidadorCNPJ_SQL (com parâmetros dinâmicos)

Script modular Spark SQL que valida CNPJs alfanuméricos com base nos dígitos verificadores DV1/DV2 conforme regras da Receita Federal.

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
O CNPJ precisa ter 14 caracteres alfanuméricos

Os DV1 e DV2 são calculados com pesos definidos pela Receita

Os valores alfanuméricos são convertidos com a fórmula ASCII - 48

📦 Organização Sugerida

ValidadorCNPJ_SQL/
├── validador_cnpj.sql        # script SQL com placeholders
├── README.md                 # instruções de uso


📄 Licença
Distribuído sob licença MIT.





