/// <summary>
/// Custom API page exposing Time Sheets with approval workflow information
/// not available in the standard BC API v2.0 timeRegistrationEntries endpoint.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timeSheets
/// </summary>
page 50102 "Thyme Time Sheet API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timeSheet';
    EntitySetName = 'timeSheets';
    PageType = API;
    SourceTable = "Time Sheet Header";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                }
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(ownerUserId; Rec."Owner User ID")
                {
                    Caption = 'Owner User ID';
                }
                field(approverUserId; Rec."Approver User ID")
                {
                    Caption = 'Approver User ID';
                }
                field(openExists; Rec."Open Exists")
                {
                    Caption = 'Open Exists';
                }
                field(submittedExists; Rec."Submitted Exists")
                {
                    Caption = 'Submitted Exists';
                }
                field(rejectedExists; Rec."Rejected Exists")
                {
                    Caption = 'Rejected Exists';
                }
                field(approvedExists; Rec."Approved Exists")
                {
                    Caption = 'Approved Exists';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    /// <summary>
    /// Applies the same setup as BC's "Create Time Sheets" batch job before inserting,
    /// so POST /timeSheets produces a usable header instead of one with a blank No.
    /// </summary>
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        ThymeActions.InitTimeSheetFromApi(Rec);
        exit(true);
    end;

    /// <summary>
    /// Submits the time sheet for approval.
    /// POST /timeSheets({id})/Microsoft.NAV.submit
    /// </summary>
    [ServiceEnabled]
    procedure submit(var ActionContext: WebServiceActionContext)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetHeader.Get(Rec."No.");
        ThymeActions.SubmitTimeSheet(TimeSheetHeader);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Approves the time sheet.
    /// POST /timeSheets({id})/Microsoft.NAV.approve
    /// </summary>
    [ServiceEnabled]
    procedure approve(var ActionContext: WebServiceActionContext)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetHeader.Get(Rec."No.");
        ThymeActions.ApproveTimeSheet(TimeSheetHeader);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Rejects the time sheet.
    /// POST /timeSheets({id})/Microsoft.NAV.reject
    /// </summary>
    [ServiceEnabled]
    procedure reject(var ActionContext: WebServiceActionContext)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetHeader.Get(Rec."No.");
        ThymeActions.RejectTimeSheet(TimeSheetHeader);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Reopens a rejected or approved time sheet for editing.
    /// POST /timeSheets({id})/Microsoft.NAV.reopen
    /// </summary>
    [ServiceEnabled]
    procedure reopen(var ActionContext: WebServiceActionContext)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetHeader.Get(Rec."No.");
        ThymeActions.ReopenTimeSheet(TimeSheetHeader);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
