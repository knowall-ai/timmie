/// <summary>
/// Custom API page for the individual findings of an AI timesheet review.
/// timeSheetLineNo = 0 means the finding applies to the whole time sheet.
///
/// Findings for a time sheet:
///   GET .../timesheetReviewLines?$filter=timeSheetNo eq 'TS00001'
/// Findings for one review:
///   GET .../timesheetReviewLines?$filter=reviewEntryNo eq 42
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timesheetReviewLines
/// </summary>
page 50110 "Thyme TS Review Lines API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timesheetReviewLine';
    EntitySetName = 'timesheetReviewLines';
    EntityCaption = 'Timesheet Review Line';
    EntitySetCaption = 'Timesheet Review Lines';
    PageType = API;
    SourceTable = "Thyme Timesheet Review Line";
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
                field(reviewEntryNo; Rec."Review Entry No.")
                {
                    Caption = 'Review Entry No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(timeSheetNo; Rec."Time Sheet No.")
                {
                    Caption = 'Time Sheet No.';
                }
                field(timeSheetLineNo; Rec."Time Sheet Line No.")
                {
                    Caption = 'Time Sheet Line No.';
                }
                field(severity; Rec.Severity)
                {
                    Caption = 'Severity';
                }
                field(note; Rec.Note)
                {
                    Caption = 'Note';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.ApplyReviewLineFilter(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteReviews();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteReviews();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteReviews();
        exit(true);
    end;
}
