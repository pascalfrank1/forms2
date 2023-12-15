CLASS zcl_form_inbox_data_provider DEFINITION
  PUBLIC
  INHERITING FROM /iwpgw/cl_tgw_facade_bwf_v2
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS: /iwpgw/if_tgw_task_facade~query_tasks REDEFINITION,
      /iwpgw/if_tgw_task_facade~read_task REDEFINITION,
      /iwpgw/if_tgw_task_facade~confirm_task REDEFINITION,
      /iwpgw/if_tgw_task_facade~apply_decision_on_task REDEFINITION,
      /iwpgw/if_tgw_task_facade~get_task_reason_options REDEFINITION,
      /iwpgw/if_tgw_task_facade~get_task_decision_options REDEFINITION,
      /iwpgw/if_tgw_task_facade~read_task_description REDEFINITION,
      /iwpgw/if_tgw_task_facade~create_task_comment REDEFINITION,
      /iwpgw/if_tgw_task_facade~read_task_object REDEFINITION,
      /iwpgw/if_tgw_task_facade~read_task_definition REDEFINITION,
      /iwpgw/if_tgw_task_facade~query_task_comments REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.


ENDCLASS.



CLASS zcl_form_inbox_data_provider IMPLEMENTATION.

  METHOD /iwpgw/if_tgw_task_facade~query_tasks.
    super->/iwpgw/if_tgw_task_facade~query_tasks(
      IMPORTING
        et_tasks       = et_tasks
        ev_inlinecount = ev_inlinecount
        ev_count       = ev_count
    ).

    DATA(employee_api) = cl_hcmfab_employee_api=>get_instance( ).
    DATA(current_employee) = employee_api->get_employeenumber_from_user( ).

    DATA(requests) = zcl_form_request=>for_approver( current_employee ).

    DATA(entries) = VALUE /iwpgw/if_tgw_types=>tt_tasks( FOR request IN requests (

        inst_id               = 'FORM_' && request->id( )
        task_def_name         = 'Genehmigung von Mobilem Arbeiten'
        task_title            = 'Antrag auf mobiles Arbeiten'
        priority              = 5
        status                = 'READY'
        status_text           = 'Gesendet'
        created_on            = request->created_on( )
        created_by            = request->created_by( )
        has_comments          = abap_true
        supports_comments     = abap_true
        prioritynumber        = 5
        task_supports         = VALUE #( addcomments = abap_true comments = abap_true uiexecutionlink = abap_true )
        uid                   = 'FORM_' && request->id( )
        gui_link              = '#ZFORM-approveMobileWork'
    ) ).


    DATA(custom_entry_count) = lines( entries ).
    APPEND LINES OF entries TO et_tasks.
    ADD custom_entry_count TO ev_count.
    ADD custom_entry_count TO ev_inlinecount.

  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~read_task.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~read_task(
        EXPORTING
          iv_instance_id = iv_instance_id
        IMPORTING
          es_task        = es_task
      ).
      RETURN.
    ENDIF.

    DATA(request_id) = CONV raw16( iv_instance_id+5 ).

    DATA(request) = zcl_form_request=>by_id( request_id ).


    es_task = VALUE #(

        inst_id               = 'FORM_' && request->id( )
        task_def_name         = 'Genehmigung von Mobilem Arbeiten'
        task_title            = 'Antrag auf mobiles Arbeiten'
        priority              = 5
        status                = 'READY'
        status_text           = 'Gesendet'
        created_on            = request->created_on( )
        created_by            = request->created_by( )
        has_comments          = abap_true
        supports_comments     = abap_true
        prioritynumber        = 5
        task_supports         = VALUE #( addcomments = abap_true comments = abap_true uiexecutionlink = abap_true )
        uid                   = 'FORM_' && request->id( )
        gui_link              = '#ZFORM-approveMobileWork'
    ).

  ENDMETHOD.
  METHOD /iwpgw/if_tgw_task_facade~confirm_task.
    RAISE EXCEPTION TYPE zcx_no_customer.
  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~apply_decision_on_task.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~apply_decision_on_task(
        EXPORTING
          iv_instance_id  = iv_instance_id
          iv_decision_key = iv_decision_key
          iv_comments     = iv_comments
          iv_reason_code  = iv_reason_code
        IMPORTING
          es_task         = es_task
      ).
      RETURN.
    ENDIF.

    DATA(request_id) = CONV raw16( iv_instance_id+5 ).
    DATA(request) = zcl_form_request=>by_id( request_id ).

        me->/iwpgw/if_tgw_task_facade~read_task(
      EXPORTING
        iv_instance_id = iv_instance_id
      IMPORTING
        es_task        = es_task
    ).


    IF iv_decision_key = '0001'.
      request->approve( iv_comments ).
       es_task-status = 'APPROVED'.
    ELSEIF iv_decision_key = '0004'.
      request->reject( iv_comments ).
       es_task-status = 'REJECTED'.
    ELSE.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception.
    ENDIF.






  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~get_task_reason_options.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~get_task_reason_options(
        EXPORTING
          iv_instance_id = iv_instance_id
          iv_dec_key     = iv_dec_key
        IMPORTING
          et_reason_opt  = et_reason_opt
      ).
      RETURN.
    ENDIF.
*  CATCH /iwbep/cx_mgw_busi_exception.
*  CATCH /iwbep/cx_mgw_tech_exception.
    DATA(x) = 1.
  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~read_task_description.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~read_task_description(
        EXPORTING
          iv_instance_id = iv_instance_id
        IMPORTING
          es_description = es_description
      ).
      RETURN.
    ENDIF.
    es_description = VALUE #( inst_id = 'FORM_testidjfawufnu' description = 'beschreibung dnuiqndinwidnwi' description_html = 'XXX' ).
  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~get_task_decision_options.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~get_task_decision_options(
        EXPORTING
          iv_instance_id = iv_instance_id
        IMPORTING
          et_dec_opt     = et_dec_opt
      ).
      RETURN.
    ENDIF.

    et_dec_opt = VALUE #(
    ( inst_id = iv_instance_id decision_key = '0001' decision_text = 'Genehmigen' nature = 'POSITIVE' reason_required = 'UNSUPPORTED' comment_supported = abap_true )
    ( inst_id = iv_instance_id decision_key = '0004' decision_text = 'Ablehnen' nature = 'NEGATIVE' reason_required = 'UNSUPPORTED' comment_supported = abap_true )

     ).


  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~create_task_comment.
    IF is_comment-inst_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~create_task_comment(
        EXPORTING
          is_comment = is_comment
        IMPORTING
          es_comment = es_comment
      ).

      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~read_task_object.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~read_task_object(
        EXPORTING
          iv_instance_id    = iv_instance_id
          iv_task_object_id = iv_task_object_id
        IMPORTING
          es_task_object    = es_task_object
      ).
      RETURN.
    ENDIF.
    DATA(x) = 1.
  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~read_task_definition.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~read_task_definition(
        EXPORTING
          iv_instance_id     = iv_instance_id
          iv_task_id         = iv_task_id
        IMPORTING
          es_task_definition = es_task_definition
      ).
      RETURN.
    ENDIF.
*CATCH /iwbep/cx_mgw_busi_exception.
*CATCH /iwbep/cx_mgw_tech_exception.
  ENDMETHOD.

  METHOD /iwpgw/if_tgw_task_facade~query_task_comments.
    IF iv_instance_id(5) NE 'FORM_'.
      super->/iwpgw/if_tgw_task_facade~query_task_comments(
        EXPORTING
          iv_instance_id = iv_instance_id
        IMPORTING
          et_comments    = et_comments
          ev_inlinecount = ev_inlinecount
          ev_count       = ev_count
      ).

      RETURN.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
