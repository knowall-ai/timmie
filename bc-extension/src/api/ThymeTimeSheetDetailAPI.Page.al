/// <summary>
/// Custom API page exposing Time Sheet Details (daily hour entries).
/// Each detail record represents hours worked on a specific date for a time sheet line.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timeSheetDetails
/// </summary>
page 50106 "Thyme Time Sheet Detail API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timeSheetDetail';
    EntitySetName = 'timeSheetDetails';
    PageType = API;
    SourceTable = "Time Sheet Detail";
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
                field(timeSheetLineNo; Rec."Time Sheet Line No.")
                {
                    Caption = 'Time Sheet Line No.';
                }
                field(date; Rec.Date)
                {
                    Caption = 'Date';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(causeOfAbsenceCode; Rec."Cause of Absence Code")
                {
                    Caption = 'Cause of Absence Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                    Editable = true;
                }
                field(postedQuantity; Rec."Posted Quantity")
                {
                    Caption = 'Posted Quantity';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
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
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        DayIndex: Integer;
        i: Integer;
        AllocatedQty: array[7] of Decimal;
        DayDate: Date;
    begin
        // Get the parent line and header to find the day index
        if not TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Time Sheet Line No.") then
            Error('Time Sheet Line %1-%2 not found', Rec."Time Sheet No.", Rec."Time Sheet Line No.");

        if not TimeSheetHeader.Get(Rec."Time Sheet No.") then
            Error('Time Sheet %1 not found', Rec."Time Sheet No.");

        // Calculate which day of the week (1-7) this date falls on
        DayIndex := Rec.Date - TimeSheetHeader."Starting Date" + 1;
        if (DayIndex < 1) or (DayIndex > 7) then
            Error('Date %1 is outside time sheet period %2 to %3',
                Rec.Date, TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");

        // Get current allocations from existing detail records
        for i := 1 to 7 do begin
            DayDate := TimeSheetHeader."Starting Date" + i - 1;
            if TimeSheetDetail.Get(Rec."Time Sheet No.", Rec."Time Sheet Line No.", DayDate) then
                AllocatedQty[i] := TimeSheetDetail.Quantity
            else
                AllocatedQty[i] := 0;
        end;

        // Set the quantity for the requested day
        AllocatedQty[DayIndex] := Rec.Quantity;

        // Update through the proper BC procedure
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, AllocatedQty);
        exit(false); // Don't do default insert, UpdateTimeAllocation handles it
    end;

    trigger OnModifyRecord(): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        DayIndex: Integer;
        i: Integer;
        AllocatedQty: array[7] of Decimal;
        DayDate: Date;
    begin
        if not TimeSheetLine.Get(Rec."Time Sheet No.", Rec."Time Sheet Line No.") then
            exit(false);

        if not TimeSheetHeader.Get(Rec."Time Sheet No.") then
            exit(false);

        DayIndex := Rec.Date - TimeSheetHeader."Starting Date" + 1;
        if (DayIndex < 1) or (DayIndex > 7) then
            exit(false);

        // Get current allocations
        for i := 1 to 7 do begin
            DayDate := TimeSheetHeader."Starting Date" + i - 1;
            if TimeSheetDetail.Get(Rec."Time Sheet No.", Rec."Time Sheet Line No.", DayDate) then
                AllocatedQty[i] := TimeSheetDetail.Quantity
            else
                AllocatedQty[i] := 0;
        end;

        AllocatedQty[DayIndex] := Rec.Quantity;
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, AllocatedQty);
        exit(false);
    end;
}
