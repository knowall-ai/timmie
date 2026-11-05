/// <summary>
/// Custom API page for AI timesheet reviews. The reviewing agent creates and updates
/// reviews here; the Thyme web app reads them.
///
/// Latest review for a time sheet:
///   GET .../timesheetReviews?$filter=timeSheetNo eq 'TS00001'  $orderby=reviewedAt desc  $top=1
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timesheetReviews
/// </summary>
page 50109 "Thyme Timesheet Reviews API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timesheetReview';
    EntitySetName = 'timesheetReviews';
    EntityCaption = 'Timesheet Review';
    EntitySetCaption = 'Timesheet Reviews';
    PageType = API;
    SourceTable = "Thyme Timesheet Review";
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
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(timeSheetNo; Rec."Time Sheet No.")
                {
                    Caption = 'Time Sheet No.';
                }
                field(versionStamp; Rec."Version Stamp")
                {
                    Caption = 'Version Stamp';
                }
                field(verdict; Rec.Verdict)
                {
                    Caption = 'Verdict';
                }
                field(summary; Rec.Summary)
                {
                    Caption = 'Summary';
                }
                field(reviewer; Rec.Reviewer)
                {
                    Caption = 'Reviewer';
                }
                field(reviewedAt; Rec."Reviewed At")
                {
                    Caption = 'Reviewed At';
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
        RecordSecurity.ApplyReviewFilter(Rec);
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
