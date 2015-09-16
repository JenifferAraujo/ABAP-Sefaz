# ABAP-Sefaz
Verificação de status de contribuinte na SEFAZ RS com programa ABAP

## Funcionamento
Este programa em ABAP consome um *WebService* da Secretaria da Fazenda do Rio Grande do Sul (SEFAZ - RS) para verificar o status de um contribuinte a partir de sua Inscrição Estadual, CPF ou CNPJ.

Para isso, é necessário que o usuário que realizará a consulta esteja cadastrado na SEFAZ-RS e possua um login (neste caso é utilizado CPF e Senha), pois o *WebService* exige autenticação para seu funcionamento.

### Observação
Note que para o cenário em questão, os parâmetros de entrada *p_stcd1*, *p_stcd2* e *p_stcd3* são usados respectivamente para representar CNPJ, CPF e Inscrição estadual dos fornecedores cadastrados na tabela *LFA1*.

Portanto, caso em seu cenário essas informações (CNPJ, CPF e Inscrição Estadual) estejam representadas em outros campos da tabela *LFA1*, ou ainda em outra tabela, ajuste o programa em questão para o seu cenário.
