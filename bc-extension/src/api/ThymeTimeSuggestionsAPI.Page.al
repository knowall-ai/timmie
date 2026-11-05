/// <summary>
/// Custom API page for AI time-entry suggestions. The reviewing agent creates and
/// updates suggestions here; the Thyme web app reads them and marks them Accepted
/// or Dismissed.
///
/// Pending suggestions for a resource's week:
///   GET .../timeSuggestions?$filter=resourceNo eq 'R0010' and date ge 2026-01-05
///       and date le 2026-01-11 and status eq 'Pending'
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timeSuggestions
/// </summary>
page 50111 "Thyme Time Suggestions API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timeSuggestion';
    EntitySetName = 'timeSuggestions';
    EntityCaption = 'Time Suggestion';
    EntitySetCaption = 'Time Suggestions';
    PageType = API;
    SourceTable = "Thyme Time Suggestion";
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
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(date; Rec.Date)
                {
                    Caption = 'Date';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
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
                field(source; Rec.Source)
                {
                    Caption = 'Source';
                }
                field(sourceRef; Rec."Source Ref")
                {
                    Caption = 'Source Ref';
                }
                field(sourceUrl; Rec."Source Url")
                {
                    Caption = 'Source Url';
                }
                field(evidence; Rec.Evidence)
                {
                    Caption = 'Evidence';
                }
                field(confidence; Rec.Confidence)
                {
                    Caption = 'Confidence';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(timeSheetNo; Rec."Time Sheet No.")
                {
                    Caption = 'Time Sheet No.';
                }
                field(timeSheetLineNo; Rec."Time Sheet Line No.")
                {
                    Caption = 'Time Sheet Line No.';
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'Created At';
                }
                field(actionedAt; Rec."Actioned At")
                {
                    Caption = 'Actioned At';
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
        RecordSecurity.ApplySuggestionFilter(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteSuggestion(Rec);
        exit(true);
    end;

    // Checks the new values: the read filter already limits which suggestions can be
    // reached, and this stops one being moved to a resource the caller doesn't own.
    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteSuggestion(Rec);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteSuggestion(Rec);
        exit(true);
    end;
}
