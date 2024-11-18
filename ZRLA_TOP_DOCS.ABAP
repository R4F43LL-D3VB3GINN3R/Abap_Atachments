*&---------------------------------------------------------------------*
*& Report ZRLA_TEST_DOCS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zrla_test_docs.

include zrla_alv_docs.
include zrla_top_docs.
include zrla_rot_docs.

*&---------------------------------------------------------------------*
*& Include          ZRLA_TOP_DOCS
*&---------------------------------------------------------------------*

"base de dados
data: it_data type zrla_table_tt.

"documentos
data: it_txt type table of string.

"instancias alv
data: lo_alv           type ref to cl_salv_table,
      lo_alv_functions type ref to cl_salv_functions,
      lo_alv_columns   type ref to cl_salv_columns,
      lo_alv_column    type ref to cl_salv_column,
      lo_alv_display   type ref to cl_salv_display_settings.

"classe de eventos
data: lo_events type ref to cl_salv_events_table.

"---------------------------------------------------------------

"tela de selecao
selection-screen: begin of block z1 with frame.
selection-screen: begin of block a1 with frame title text-001.
parameters: p_path type ibipparms-path.
selection-screen: end of block a1.
selection-screen: begin of block b1 with frame.
selection-screen begin of line.
selection-screen position 30.
parameters p_act001 radiobutton group grp1 default 'X'.
selection-screen comment 32(10) text-040.
selection-screen position 51.
parameters p_act002 radiobutton group grp1.
selection-screen comment 53(10) text-041.
selection-screen position 70.
parameters p_act003 radiobutton group grp1.
selection-screen comment 72(10) text-042.
selection-screen end of line.
selection-screen: end of block b1.
selection-screen: end of block z1.

"-----------------------------------------------------------------------------

"pesquisador para diretorio
at selection-screen on value-request for p_path. "insere o icone de procura
  " chama a funcao para abrir a caixa de selecao do arquivo.
  call function 'F4_FILENAME'
    exporting
      program_name  = syst-cprog
      dynpro_number = syst-dynnr
      field_name    = 'P_PATH'
    importing
      file_name     = p_path.

*&---------------------------------------------------------------------*
*& Include          ZRLA_ROT_DOCS
*&---------------------------------------------------------------------*

start-of-selection.

  perform get_data.
  perform display_data.

form get_data.

  select *
    from zrla_table
    into corresponding fields of table it_data.

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


