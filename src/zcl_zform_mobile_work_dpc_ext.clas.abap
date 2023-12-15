CLASS zcl_zform_mobile_work_dpc_ext DEFINITION
  PUBLIC
  INHERITING FROM zcl_zform_mobile_work_dpc
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS: /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity REDEFINITION.

  PROTECTED SECTION.
    METHODS: dataset_create_entity REDEFINITION,
      dataset_get_entity REDEFINITION,
      overviewset_get_entityset REDEFINITION,
      substitutes_get_entityset REDEFINITION,
      substitutes_get_entity REDEFINITION.

  PRIVATE SECTION.

    DATA: current_substitute TYPE pernr_d.

ENDCLASS.



CLASS zcl_zform_mobile_work_dpc_ext IMPLEMENTATION.
  METHOD dataset_create_entity.

    DATA: request_data TYPE zcl_zform_mobile_work_mpc_ext=>ts_data,
          table_data   TYPE zform_mob_work,
          header       TYPE zform_headers.

    io_data_provider->read_entry_data( IMPORTING es_data = request_data ).


    DATA(current_employee) = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).
*    DATA(header_id) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).

    data(request) = zcl_form_request=>new(
                      employee_number = current_employee
                      application     = 'MOB_WORK'
                    ).

    table_data = CORRESPONDING #( request_data ).
    table_data-employee_number = current_employee.

    table_data-header_id = request->id( ).



*    GET TIME STAMP FIELD DATA(current_timestamp).
*
*    header = VALUE zform_headers(
*        mandt           = sy-mandt
*        id              = header_id
*        employee_number = current_employee
*        application     = 'MOB_WORK'
*        timestamp       = current_timestamp
*        approval_step   = 0
*    ).
*
*
*    INSERT zform_headers FROM header.

    IF sy-subrc = 0.
      INSERT zform_mob_work FROM table_data.
      er_entity = request_data.
      er_entity-header_id = request->id( ).
    ENDIF.

  ENDMETHOD.

  METHOD overviewset_get_entityset.

    DATA: response_data TYPE zcl_zform_mobile_work_mpc_ext=>ts_overview,
          header_ids    TYPE RANGE OF uuid.

    DATA(current_employee) = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).

*    select * from zform_headers where employee_number = @current_employee and application = 'MOB_WORK' into table @data(headers).

    DATA(requests) = zcl_form_request=>from_employee( employee = current_employee application = 'MOB_WORK' ).

    header_ids = VALUE #( FOR _request IN requests ( sign = 'I' option = 'EQ' low = _request->id( ) ) ).

    SELECT * FROM zform_mob_work WHERE header_id IN @header_ids INTO TABLE @DATA(form_data).

    LOOP AT requests INTO DATA(request).

      DATA(corresponding_form_data) = form_data[ header_id = request->id( ) ].

      DATA(mobile_work_hours) = corresponding_form_data-weekly_hours * corresponding_form_data-mobile_work_percent / 100.

      DATA(approval) = NEW zcl_form_approver( employee = current_employee approval_step = CONV #( request->current_step( ) ) ).

      DATA(response_entry) = VALUE zcl_zform_mobile_work_mpc_ext=>ts_overview(
      header_id = request->id( )
          begin_date         = corresponding_form_data-begin_date
          next_approver      = approval->get_next_approver( )
          next_approver_name = approval->get_next_approver_name( )
          approval_status    = request->current_step( )
          mobile_work_string = |{ mobile_work_hours }/{ corresponding_form_data-weekly_hours } Stunden ({ corresponding_form_data-mobile_work_percent }%)|
          end_date           = corresponding_form_data-end_date
      ).

      APPEND response_entry TO et_entityset.

    ENDLOOP.


  ENDMETHOD.

  METHOD dataset_get_entity.
    "Zeitraum von 00000101-00000101, heißt neues Formular wird erstellt und es werden Defaultwerte mitgegeben

    DATA(begin_date) = it_key_tab[ name = 'beginDate' ]-value.
    DATA(end_date) = it_key_tab[ name = 'endDate' ]-value.
    DATA(header_id) = it_key_tab[ name = 'headerId' ]-value.
    DATA(current_employee) = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).


    IF header_id NE '0000000000000000'.
      "mit header selektieren

      SELECT SINGLE * FROM zform_mob_work INTO @DATA(existing_form) WHERE header_id = @header_id.
       SELECT SINGLE wostd FROM pa0007 WHERE pernr = @existing_form-employee_number AND begda <= @sy-datum AND endda >= @sy-datum INTO @er_entity-weekly_hours.
      er_entity = CORRESPONDING #( existing_form ).
      me->current_substitute = er_entity-substitute.
      RETURN.
    ENDIF.

    IF begin_date NE '19700101' AND end_date NE '19700101'.


      SELECT SINGLE * FROM zform_mob_work INTO @existing_form WHERE begin_date = @begin_date AND end_date = @end_date AND employee_number = @current_employee.


      er_entity = CORRESPONDING #( existing_form ).
*er_entity-substitute = '00000017'.

    ELSE.
      "default-werte
      er_entity-employee_number = current_employee.
      er_entity-begin_date = sy-datum.
      er_entity-end_date = sy-datum.
      er_entity-mobile_work_percent = 75.
      er_entity-end_date = cl_reca_date=>add_to_date( id_date = er_entity-end_date id_years = 2 ).
      SUBTRACT 1 FROM er_entity-end_date.
      SELECT SINGLE wostd FROM pa0007 WHERE pernr = @current_employee AND begda <= @sy-datum AND endda >= @sy-datum INTO @er_entity-weekly_hours.


    ENDIF.

    me->current_substitute = er_entity-substitute.



  ENDMETHOD.

  METHOD substitutes_get_entityset.

    SELECT DISTINCT pa0000~pernr, pa0002~vorna, pa0002~nachn FROM pa0000
                                                             JOIN pa0002 ON pa0000~pernr = pa0002~pernr AND
                                                                            pa0002~begda <= @sy-datum AND
                                                                            pa0002~endda >= @sy-datum
                                                             WHERE pa0000~stat2 = '3' INTO TABLE @et_entityset.


  ENDMETHOD.

  METHOD substitutes_get_entity.
    SELECT SINGLE pa0000~pernr, pa0002~vorna, pa0002~nachn FROM pa0000
                                                             JOIN pa0002 ON pa0000~pernr = pa0002~pernr AND
                                                                            pa0002~begda <= @sy-datum AND
                                                                            pa0002~endda >= @sy-datum
                                                             WHERE pa0000~pernr EQ @current_substitute INTO @er_entity.
  ENDMETHOD.

  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.

    super->/iwbep/if_mgw_appl_srv_runtime~get_expanded_entity(
      EXPORTING
        iv_entity_name           = iv_entity_name
        iv_entity_set_name       = iv_entity_set_name
        iv_source_name           = iv_source_name
        it_key_tab               = it_key_tab
        it_navigation_path       = it_navigation_path
        io_expand                = io_expand
        io_tech_request_context  = io_tech_request_context
      IMPORTING
        er_entity                = er_entity
        es_response_context      = es_response_context
        et_expanded_clauses      = et_expanded_clauses
        et_expanded_tech_clauses = et_expanded_tech_clauses
    ).
**    CATCH /iwbep/cx_mgw_busi_exception.
**    CATCH /iwbep/cx_mgw_tech_exception.
  ENDMETHOD.

ENDCLASS.
