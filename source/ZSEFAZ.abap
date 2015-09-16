REPORT ZSEFAZ.

DATA: l_url               TYPE string,
      l_params_string     TYPE string,
      l_http_client       TYPE REF TO if_http_client,
      l_params_xstring    TYPE xstring,
      l_xstring           TYPE xstring,
      l_message           TYPE string,
      l_subrc             TYPE sy-subrc,
      v_msg(50)           TYPE c,
      t_xml_info          TYPE TABLE OF smum_xmltb INITIAL SIZE 0,
      wa_xml_info         LIKE LINE OF t_xml_info,
      t_return            TYPE STANDARD TABLE OF bapiret2,
      wa_return           LIKE LINE OF t_return,
      v_status(40)		    TYPE c.

SELECTION-SCREEN BEGIN OF BLOCK b1.
  PARAMETERS: p_stcd1     LIKE lfa1-stcd1,
              p_stcd2     LIKE lfa1-stcd2,
              p_stcd3     LIKE lfa1-stcd3,
              p_cpf(11)   TYPE c,
              p_senha(10) TYPE c.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

MOVE 'http://webservices.sefaz.rs.gov.br/CadastroContribuintesRSGeral_XML.asp' TO l_url.

CLEAR: l_params_string, v_status.
TRANSLATE p_stcd3 USING '/ - . '.
CONDENSE p_stcd3 NO-GAPS.

CONCATENATE '<PARAMETROS><CPF>'
            p_cpf
            '</CPF><SENHA>'
            p_senha
            '</SENHA><IE>'
            p_stcd3
            '</IE><CNPJ>'
            p_stcd1'</CNPJ><CPFTITULAR>'
            p_stcd2
            '</CPFTITULAR></PARAMETROS>'
            INTO l_params_string.

"Cria um cliente HTTP

CALL METHOD cl_http_client=>create_by_url
  EXPORTING
    url                = l_url
  IMPORTING
    client             = l_http_client
  EXCEPTIONS
    argument_not_found = 1
    plugin_not_active  = 2
    internal_error     = 3
    OTHERS             = 4.

IF sy-subrc IS INITIAL.

  "Seta os parâmetros do cabeçalho HTTP
  CALL METHOD l_http_client->request->set_header_field
    EXPORTING
      name  = 'Accept'
      value = 'text/xml'.

  CALL METHOD l_http_client->request->set_header_field
    EXPORTING
      name  = '~request_method'
      value = 'POST'.

  CALL METHOD l_http_client->request->set_header_field
    EXPORTING
      name  = '~server_protocol'
      value = 'HTTP/1.1'.

  CALL METHOD l_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'text/xml; charset=utf-8'.

  CALL METHOD l_http_client->request->set_content_type
    EXPORTING
      content_type  = 'text/xml'.

  "Prepara o XML a ser enviado pela requisição
  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = l_params_string
    IMPORTING
      buffer = l_params_xstring
    EXCEPTIONS
      failed = 1
      OTHERS = 2.

  IF sy-subrc IS INITIAL.

    CALL METHOD l_http_client->request->set_data
      EXPORTING
        data  = l_params_xstring.

    "Envia a requisição HTTP
    CALL METHOD l_http_client->send
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2.

    IF sy-subrc IS INITIAL.

      "Recebe a resposta da requisição anterior
      CALL METHOD l_http_client->receive
        EXCEPTIONS
          http_communication_failure = 1
          http_invalid_state         = 2
          http_processing_failed     = 3.

      IF sy-subrc IS INITIAL.

        "Recebe os dados do retorno HTTP
        CALL METHOD l_http_client->response->get_data
          RECEIVING
            data = l_xstring.

        "Encerra a conexão do cliente
        CALL METHOD l_http_client->close
          EXCEPTIONS
            http_invalid_state = 1
            OTHERS             = 2.

        CLEAR: t_xml_info, t_xml_info[], t_return, t_return[].

        CALL FUNCTION 'SMUM_XML_PARSE'
          EXPORTING
            xml_input = l_xstring
          TABLES
            xml_table = t_xml_info
            return    = t_return
          EXCEPTIONS
            OTHERS    = 1.

        READ TABLE t_xml_info INTO wa_xml_info WITH KEY cname = 'STATUS'
                                                        cvalue = '00'.
        IF sy-subrc IS INITIAL.

          READ TABLE t_xml_info INTO wa_xml_info WITH KEY cname = 'SITUACAO'
                                                          cvalue = 'A'.
          IF sy-subrc IS INITIAL.

            MESSAGE s000 WITH 'Inscrição e CPF/CNPJ OK'.

          ELSE.

            MESSAGE w000 WITH 'Situação não ok. Verificar'.

          ENDIF.

        ELSE.

          MESSAGE e000 WITH 'Erro na leitura dos dados. Verificar...'.

        ENDIF.

      ELSE.

        CLEAR v_msg.

        "Recupera a mensagem de erro, caso haja.
        CALL METHOD l_http_client->get_last_error
          IMPORTING
            code    = l_subrc
            message = l_message.

        CASE sy-subrc.
          WHEN '1'.
            v_msg = 'HTTP_COMMUNICATION_FAILURE'.

          WHEN '2'.
            v_msg = 'HTTP_INVALID_STATE'.

          WHEN '3'.
            v_msg = 'HTTP_PROCESSING_FAILED'.

          WHEN OTHERS.
            v_msg = 'Erro desconhecido'.
            
        ENDCASE.

        MESSAGE e000 WITH 'Falha ao receber retorno HTTP' v_msg l_message.

      ENDIF.

    ELSE.

      CLEAR v_msg.

      "Recupera a mensagem de erro, caso haja.
      CALL METHOD l_http_client->get_last_error
        IMPORTING
          code    = l_subrc
          message = l_message.

      CASE sy-subrc.
        WHEN '1'.
          v_msg = 'HTTP_COMMUNICATION_FAILURE'.

        WHEN '2'.
          v_msg = 'HTTP_INVALID_STATE'.

        WHEN OTHERS.
          v_msg = 'Erro desconhecido'.

      ENDCASE.

      MESSAGE e000 WITH 'Falha ao enviar requisição HTTP' v_msg l_message.

    ENDIF.

  ELSE.

    MESSAGE e000 WITH 'Falha ao converter string para XML'.

  ENDIF.

ELSE.

  CLEAR v_msg.

  CASE sy-subrc.
    WHEN '1'.
      v_msg = 'ARGUMENT_NOT_FOUND'.

    WHEN '2'.
      v_msg = 'PLUGIN_NOT_ACTIVE'.

    WHEN '3'.
      v_msg = 'INTERNAL_ERROR'.

    WHEN OTHERS.
      v_msg = 'Erro desconhecido'.

  ENDCASE.

  MESSAGE e000 WITH 'Falha ao criar cliente HTTP: ' v_msg.

ENDIF.
