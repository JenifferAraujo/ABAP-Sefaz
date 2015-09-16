# ABAP-Sefaz
Verificação de status de contribuinte na SEFAZ RS com programa ABAP

## Funcionamento
Este programa em ABAP consome um *WebService* da Secretaria da Fazenda do Rio Grande do Sul (SEFAZ - RS) para verificar o status de um contribuinte a partir de sua Inscrição Estadual, CPF ou CNPJ.

Para isso, é necessário que o usuário que realizará a consulta esteja cadastrado na SEFAZ-RS e possua um login (neste caso é utilizado CPF e Senha), pois o *WebService* exige autenticação para seu funcionamento.
