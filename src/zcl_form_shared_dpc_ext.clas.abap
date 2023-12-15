CLASS zcl_form_shared_dpc_ext DEFINITION
  PUBLIC
  INHERITING FROM zcl_form_shared_dpc
  CREATE PUBLIC .

  PUBLIC SECTION.
  PROTECTED SECTION.

    METHODS:
      approvers_get_entity REDEFINITION,
      approvers_get_entityset REDEFINITION,
      personneldataset_get_entity REDEFINITION,
      notes_get_entityset REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_form_shared_dpc_ext IMPLEMENTATION.
  METHOD approvers_get_entity.
    DATA(approver_type) = it_key_tab[ name = 'type' ]-value.
    DATA(current_employee) = CONV pernr_d( it_key_tab[ name = 'employeeNumber' ]-value ).

    if current_employee = '00000000'.
    current_employee  = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).
    endif.

*    DATA(current_employee) = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).

    DATA(approval) = NEW zcl_form_approver( employee = current_employee approval_step = 0 ).

    DATA(approver) = SWITCH #( approver_type
        WHEN 'M' THEN approval->get_manager( )
        WHEN 'MM' THEN approval->get_managers_manager( )
        WHEN 'C' THEN approval->get_clerk( )
     ).
    DATA(dummy_name) = |Genehmiger von { current_employee }|.

    er_entity = VALUE #(
        employee_number = current_employee
       approver = approver
       type = approver_type
       name = zcl_form_approver=>name_of( approver )
    ).


  ENDMETHOD.

  METHOD approvers_get_entityset.
    RETURN.
*    DATA(current_employee) = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).
    DATA(current_employee) = CONV pernr_d( it_key_tab[ name = 'employeeNumber' ]-value ).
    DATA(approval) = NEW zcl_form_approver( employee = current_employee approval_step = 0 ).

    DATA(manager) = approval->get_manager( ).
    DATA(manangers_manager) = approval->get_managers_manager( ).
    DATA(clerk) = approval->get_clerk( ).


    et_entityset = VALUE #(
    (
        employee_number = '00000006'
        approver = manager
        type = 'M'
        name =  zcl_form_approver=>name_of( manager )
    )
    (
        employee_number = '00000006'
        approver = manangers_manager
        type = 'MM'
        name =  zcl_form_approver=>name_of( manangers_manager )
    )
    (
        employee_number = '00000006'
        approver = clerk
        type = 'C'
        name =  zcl_form_approver=>name_of( clerk )
    )
    ).
  ENDMETHOD.

  METHOD personneldataset_get_entity.
    "TODO: Prüfung einbauen, sodass nur Vorgesetzte Daten lesen können
    DATA(employee_api) = cl_hcmfab_employee_api=>get_instance( ).
*    DATA(employee_number) = employee_api->get_employeenumber_from_user( ).
    DATA(employee_number) = CONV pernr_d( it_key_tab[ name = 'employeeNumber' ]-value ).

    IF employee_number EQ '00000000'.
      employee_number = employee_api->get_employeenumber_from_user( ).
    ENDIF.


    SELECT SINGLE vorna, nachn FROM pa0002 WHERE pernr EQ @employee_number AND begda <= @sy-datum AND endda >= @sy-datum INTO ( @DATA(first_name), @DATA(last_name) ).



    er_entity = VALUE #(
        employee_number = employee_number
        first_name = first_name
        last_name = last_name
        phone_number = employee_api->get_address_from_user( employee_api->get_userid_from_employeenumber( employee_number ) )-tel1_numbr

    ).



  ENDMETHOD.

  METHOD notes_get_entityset.


    DATA(id) = mr_request_details->filter_select_options[ property = 'headerId' ]-select_options[ 1 ]-low.

    DATA(current_employee) = cl_hcmfab_employee_api=>get_instance( )->get_employeenumber_from_user( ).
    DATA(request) = zcl_form_request=>by_id( id = CONV #( id ) ).
    DATA(notes) = VALUE zform_note_table( ).

*    loop at requests into data(request).
*    append lines of request->notes( ) to notes.
*    endloop.

    et_entityset = VALUE #(
        FOR note IN request->notes( )
        (
            request_id = request->id( )
            approval_step = note-approval_step
            from = zcl_form_approver=>name_of( note-sender )
            timestamp = note-timestamp
            note = note-message
        )
    ).



  ENDMETHOD.

ENDCLASS.
