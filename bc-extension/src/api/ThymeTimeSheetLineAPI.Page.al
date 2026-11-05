/// <summary>
/// Custom API page exposing Time Sheet Lines with job/task references and status.
/// This enables Thyme to display time entries in all approval states,
/// not just posted entries available via standard BC API v2.0.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timeSheetLines
/// </summary>
page 50103 "Thyme Time Sheet Line API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timeSheetLine';
    EntitySetName = 'timeSheetLines';
    PageType = API;
    SourceTable = "Time Sheet Line";
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
                field(timeSheetNo; Rec."Time Sheet No.")
                {
                    Caption = 'Time Sheet No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(timeSheetStartingDate; Rec."Time Sheet Starting Date")
                {
                    Caption = 'Time Sheet Starting Date';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(causeOfAbsenceCode; Rec."Cause of Absence Code")
                {
                    Caption = 'Cause of Absence Code';
                }
                field(workTypeCode; Rec."Work Type Code")
                {
                    Caption = 'Work Type Code';
                }
                field(chargeable; Rec.Chargeable)
                {
                    Caption = 'Chargeable';
                }
                field(totalQuantity; Rec."Total Quantity")
                {
                    Caption = 'Total Quantity';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(approvedBy; Rec."Approved By")
                {
                    Caption = 'Approved By';
                }
                field(approvalDate; Rec."Approval Date")
                {
                    Caption = 'Approval Date';
                }
                field(posted; Rec.Posted)
                {
                    Caption = 'Posted';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
        NextLineNo: Integer;
    begin
        // Auto-assign Line No. if not provided or is 0
        if Rec."Line No." = 0 then begin
            TimeSheetLine.SetRange("Time Sheet No.", Rec."Time Sheet No.");
            if TimeSheetLine.FindLast() then
                NextLineNo := TimeSheetLine."Line No." + 10000
            else
                NextLineNo := 10000;
            Rec."Line No." := NextLineNo;
        end;
        exit(true); // Continue with default insert
    end;

    /// <summary>
    /// Approves the time sheet line.
    /// POST /timeSheetLines({id})/Microsoft.NAV.approve
    /// </summary>
    [ServiceEnabled]
    procedure approve(var ActionContext: WebServiceActionContext)
    var
        TimeSheetLine: Record "Time Sheet Line";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Line No.");
        ThymeActions.ApproveTimeSheetLine(TimeSheetLine);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet Line API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Rejects the time sheet line.
    /// POST /timeSheetLines({id})/Microsoft.NAV.reject
    /// </summary>
    [ServiceEnabled]
    procedure reject(var ActionContext: WebServiceActionContext)
    var
        TimeSheetLine: Record "Time Sheet Line";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Line No.");
        ThymeActions.RejectTimeSheetLine(TimeSheetLine);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet Line API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Reopens a rejected or approved time sheet line for editing.
    /// POST /timeSheetLines({id})/Microsoft.NAV.reopen
    /// </summary>
    [ServiceEnabled]
    procedure reopen(var ActionContext: WebServiceActionContext)
    var
        TimeSheetLine: Record "Time Sheet Line";
        ThymeActions: Codeunit "Thyme Time Sheet Actions";
    begin
        TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Line No.");
        ThymeActions.ReopenTimeSheetLine(TimeSheetLine);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet Line API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Sets hours for a specific day of the week (1-7).
    /// POST /timeSheetLines({id})/Microsoft.NAV.setHours
    /// Body: { "dayOfWeek": 3, "hours": 4.5 }
    /// </summary>
    [ServiceEnabled]
    procedure setHours(var ActionContext: WebServiceActionContext; dayOfWeek: Integer; hours: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        AllocatedQty: array[7] of Decimal;
        i: Integer;
        DayDate: Date;
    begin
        if (dayOfWeek < 1) or (dayOfWeek > 7) then
            Error('dayOfWeek must be between 1 and 7');

        TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Line No.");
        TimeSheetHeader.Get(Rec."Time Sheet No.");

        // Get current allocations from existing detail records
        for i := 1 to 7 do begin
            DayDate := TimeSheetHeader."Starting Date" + i - 1;
            if TimeSheetDetail.Get(Rec."Time Sheet No.", Rec."Line No.", DayDate) then
                AllocatedQty[i] := TimeSheetDetail.Quantity
            else
                AllocatedQty[i] := 0;
        end;

        // Set the quantity for the requested day
        AllocatedQty[dayOfWeek] := hours;

        // Update through BC's Time Sheet Management
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, AllocatedQty);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet Line API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Sets hours for a specific date.
    /// POST /timeSheetLines({id})/Microsoft.NAV.setHoursForDate
    /// Body: { "entryDate": "2026-01-08", "hours": 4.5 }
    /// </summary>
    [ServiceEnabled]
    procedure setHoursForDate(var ActionContext: WebServiceActionContext; entryDate: Date; hours: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        AllocatedQty: array[7] of Decimal;
        i: Integer;
        DayIndex: Integer;
        DayDate: Date;
    begin
        TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Line No.");
        TimeSheetHeader.Get(Rec."Time Sheet No.");

        // Calculate which day of the week (1-7) this date falls on
        DayIndex := entryDate - TimeSheetHeader."Starting Date" + 1;
        if (DayIndex < 1) or (DayIndex > 7) then
            Error('Date %1 is outside time sheet period %2 to %3',
                entryDate, TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");

        // Get current allocations from existing detail records
        for i := 1 to 7 do begin
            DayDate := TimeSheetHeader."Starting Date" + i - 1;
            if TimeSheetDetail.Get(Rec."Time Sheet No.", Rec."Line No.", DayDate) then
                AllocatedQty[i] := TimeSheetDetail.Quantity
            else
                AllocatedQty[i] := 0;
        end;

        // Set the quantity for the requested day
        AllocatedQty[DayIndex] := hours;

        // Update through BC's Time Sheet Management
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, AllocatedQty);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Time Sheet Line API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
