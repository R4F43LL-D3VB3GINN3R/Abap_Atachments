*&---------------------------------------------------------------------*
*& Include          ZRLA_TOP_DOCS
*&---------------------------------------------------------------------*

"base de dados
data it_data type zrla_table_tt.

"documentos txt
data: it_txt type table of string,
      ls_txt type string.

"documentos excel
data: it_excel    type ref to data,
      lt_fieldcat type lvc_t_fcat.

"instancias alv
data: lo_alv           type ref to cl_salv_table,
      lo_alv_functions type ref to cl_salv_functions,
      lo_alv_columns   type ref to cl_salv_columns,
      lo_alv_column    type ref to cl_salv_column,
      lo_alv_display   type ref to cl_salv_display_settings.

"classe de eventos
data lo_events type ref to cl_salv_events_table.

"outros
constants lv_server_path type string value '/tmp'.

"---------------------------------------------------------------

"tela de selecao
selection-screen: begin of block z1 with frame.
selection-screen: begin of block a1 with frame.
parameters: p_namefl type string.
selection-screen: end of block a1.
selection-screen: begin of block b1 with frame.
selection-screen begin of line.
selection-screen position 30.
parameters p_act001 radiobutton group grp1 default 'X'. "Submeter
selection-screen comment 32(10) text-040.
selection-screen position 51.
parameters p_act002 radiobutton group grp1.             "Visualizar
selection-screen comment 53(10) text-041.
selection-screen position 70.
parameters p_act003 radiobutton group grp1.             "Ver Todos
selection-screen comment 72(10) text-042.
selection-screen end of line.
selection-screen: end of block b1.
selection-screen: begin of block c1 with frame.
selection-screen begin of line.
selection-screen position 30.
parameters p_act004 radiobutton group grp2.              "TxT
selection-screen comment 32(10) text-043.
selection-screen position 51.
parameters p_act005 radiobutton group grp2.              "Excel
selection-screen comment 53(10) text-044.
selection-screen position 70.
parameters p_act006 radiobutton group grp2.              "Pdf
selection-screen comment 72(10) text-045.
selection-screen end of line.
selection-screen: end of block c1.
selection-screen: end of block z1.

"-----------------------------------------------------------------------------

*&---------------------------------------------------------------------*
*& Include          ZRLA_ROT_DOCS
*&---------------------------------------------------------------------*

start-of-selection.

  if p_act001 eq 'X'.
    perform get_data.
  elseif p_act002 eq 'X'.
    perform load_data.
  endif.


*  perform display_doc.

  "-----------------------------------------------------------------------------------
  "-----------------------------------------------------------------------------------
  "-----------------------------------------------------------------------------------

form get_data.

  "consulta para obter os dados

  select *
    from zrla_table
    into corresponding fields of table it_data.

  if p_act004 eq 'X'. "se txt...
    perform set_txt.
  elseif p_act005 eq 'X'.
    perform set_excel.
  endif.

endform.

form load_data.

  "carregamento de dados do servidor.

  if p_act005 eq 'X'.
    perform load_txt.
  endif.

endform.

form load_txt.

endform.

form set_txt.

  "passa o resultado da consulta para a tabela de string

  refresh it_txt.

  data new_line type string.

  loop at it_data into data(ls_data).
    new_line = ls_data-campo1.
    concatenate new_line ls_data-campo2 into ls_txt.
    append ls_txt to it_txt.
    clear ls_txt.
  endloop.

  refresh it_data.

  perform insert_server.

endform.

form set_excel.

  "passa o resultado da consulta para o arquivo excel.

  "cria uma tabela usando como referencia a tabela principal
  get reference of it_data into it_excel.

  "cria um catalogo de campos
  data(lt_fieldcat) = value lvc_t_fcat( ( col_pos = 1 fieldname = 'CAMPO1' coltext = 'Campo1' )
                                        ( col_pos = 2 fieldname = 'CAMPO2' coltext = 'Campo2' ) ).

  "cria um modelo de dados com o catalogo de campos e a tabela
  data(lo_result_data) = cl_salv_ex_util=>factory_result_data_table( r_data         = it_excel
                                                                     t_fieldcatalog = lt_fieldcat ).

  "verifica versao do writer xlsx
  case cl_salv_bs_a_xml_base=>get_version( ).
    when if_salv_bs_xml=>version_25.
      data(lv_version) = if_salv_bs_xml=>version_25.
    when if_salv_bs_xml=>version_26.
      lv_version = if_salv_bs_xml=>version_26.
  endcase.

  "transforma a tabela em xstring
  call method cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform
    exporting
      xml_type      = if_salv_bs_xml=>c_type_xlsx
      xml_version   = lv_version
      r_result_data = lo_result_data
      xml_flavour   = if_salv_bs_c_tt=>c_tt_xml_flavour_export
      gui_type      = if_salv_bs_xml=>c_gui_type_gui
    importing
      xml           = data(lv_xstring).

  "verifica se há nome de arquivo
  if p_namefl is initial.
    message | Escolha um nome para o arquivo. | type 'S' display like 'E'.
    return.
  endif.

  "trata o caminho para o servidor
  data new_path type string.
  concatenate lv_server_path '/' p_namefl '.xlsx' into new_path.

  "se o arquivo for excel...
  if p_act005 eq 'X'.
    "se houver conteúdo...
    if it_excel is not initial.
      "insere no servidor
      open dataset new_path for output in binary mode.
        transfer lv_xstring to new_path.
      close dataset new_path.
    endif.
  endif.

  "resultado da operacao
  if sy-subrc eq 0.
    message | Arquivo { p_namefl } submetido com sucesso | type 'S'.
  else.
    message | Não foi possível submeter o arquivo { p_namefl } | type 'S' display like 'E'.
  endif.

endform.

form insert_server.

  "passa o arquivo para o servidor.

  "verifica se há nome do arquivo
  if p_namefl is initial.
    message | Escolha um nome para o arquivo. | type 'S' display like 'E'.
    return.
  endif.

  "trata o caminho para o servidor
  data new_path type string.
  concatenate lv_server_path '/' p_namefl '.txt' into new_path.

  data(new_line) = ''.

  "se o arquivo for txt...
  if p_act004 eq 'X'.
    "se houver conteúdo...
    if it_txt is not initial.
      "insere no servidor
      open dataset new_path for output in text mode encoding default.
      loop at it_txt into ls_txt.
        transfer ls_txt to new_path.
        clear: ls_txt.
      endloop.
      close dataset new_path.
    endif.
  endif.

  "resultado da operacao
  if sy-subrc eq 0.
    message | Arquivo { p_namefl } submetido com sucesso | type 'S'.
  else.
    message | Não foi possível submeter o arquivo { p_namefl } | type 'S' display like 'E'.
  endif.

endform.

form display_data.

  try.
      cl_salv_table=>factory(
      importing
        r_salv_table   = lo_alv
      changing
        t_table        = it_data
      ).
    catch cx_salv_msg.
  endtry.

  perform build_alv_columns. "formata as colunas do alv

  lo_alv->set_screen_status(
    exporting
      report        = sy-repid
      pfstatus      = 'STATUS_DOCS'
      set_functions = cl_salv_table=>c_functions_all
  ).

  lo_events = lo_alv->get_event( ). "objeto de evento recebe o evento da classe

  set handler zcl_event_handler=>added_function for lo_events. "envia o evento para o metodo estático da classe

  lo_alv->display( ). "renderiza o alv

endform.

form build_alv_columns.

  try.
      "funcoes
      lo_alv_functions = lo_alv->get_functions( ).
      lo_alv_functions->set_all( abap_true ).

      "opcoes de display
      lo_alv_display = lo_alv->get_display_settings( ).
      lo_alv_display->set_striped_pattern( cl_salv_display_settings=>true ).
      lo_alv_display->set_list_header( 'Listagem Default' ).

      "configurando os nomes das colunas
      lo_alv_columns = lo_alv->get_columns( ).

      "por preferencia, os nomes serao alterados, centralizados e sempre
      "lidos na forma mais extensa possivel e com medidas de largura fixas

      lo_alv_column = lo_alv_columns->get_column( 'CAMPO1' ).
      lo_alv_column->set_long_text( 'Chave' ).
      lo_alv_column->set_fixed_header_text( 'L' ).
      lo_alv_column->set_medium_text( '' ).
      lo_alv_column->set_short_text( '' ).
      lo_alv_column->set_output_length('5').
      lo_alv_column->set_optimized( 'X' ).
      lo_alv_column->set_alignment(
      value = if_salv_c_alignment=>centered
      ).

      lo_alv_column = lo_alv_columns->get_column( 'CAMPO2 ' ).
      lo_alv_column->set_long_text( 'Campo' ).
      lo_alv_column->set_medium_text( '' ).
      lo_alv_column->set_short_text( '' ).
      lo_alv_column->set_output_length('20').
      lo_alv_column->set_optimized( 'X' ).
      lo_alv_column->set_alignment(
      value = if_salv_c_alignment=>centered
      ).


    catch cx_root into data(lx_not_found).
      message lx_not_found->get_text( ) type 'E' display like 'E'.
  endtry.

endform.

*&---------------------------------------------------------------------*
*& Include          ZRLA_ALV_DOCS
*&---------------------------------------------------------------------*

CLASS zcl_event_handler DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS:
      "método para implementar botoes na toolbar do alv
      added_function FOR EVENT added_function OF cl_salv_events_table
        IMPORTING
          e_salv_function.

ENDCLASS.

CLASS zcl_event_handler IMPLEMENTATION.

  METHOD added_function.

*    CASE sy-ucomm.
*      WHEN 'EXPORT'.
*        "download do arquivo excel
*        ol_excel->download_xls( ).
*    ENDCASE.

  ENDMETHOD.

ENDCLASS.
