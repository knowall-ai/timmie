/// <summary>
/// Custom API page for AI plan reviews: one review per subject-week (a person's week,
/// subjectType Resource, or a project's week, subjectType Project). The reviewing agent
/// creates them here; Thyme reads them for the Plan grid.
///
/// Latest review for a subject-week:
///   GET .../planReviews?$filter=subjectType eq 'Resource' and subjectNo eq 'R0010' and weekStart eq 2026-10-19
///         $orderby=reviewedAt desc  $top=1
/// Reviews of the weeks on screen (Thyme):
///   GET .../planReviews?$filter=subjectType eq 'Resource' and weekStart ge 2026-10-19 and weekStart le 2026-11-09
///
/// planHash is the lowercase hex SHA-256 of the subject-week's planning lines when reviewed
/// (PENDING while the agent is still writing the findings), so Thyme can tell when a review is
/// out of date.
///
/// Who can do what (codeunit "Thyme Record Security"): every Thyme user reads them; only the
/// AI agent or a Thyme administrator creates, changes or deletes them.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/planReviews
/// </summary>
page 50118 "Thyme Plan Reviews API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'planReview';
    EntitySetName = 'planReviews';
    EntityCaption = 'Plan Review';
    EntitySetCaption = 'Plan Reviews';
    PageType = API;
    SourceTable = "Thyme Plan Review";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    // THYME ADMIN writes reviews only indirectly, through this page and its
    // CheckCanWritePlanReviews triggers; the AI agent has direct access.
    Permissions = tabledata "Thyme Plan Review" = rimd;

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
                field(subjectType; Rec."Subject Type")
                {
                    Caption = 'Subject Type';
                }
                field(subjectNo; Rec."Subject No.")
                {
                    Caption = 'Subject No.';
                }
                field(weekStart; Rec."Week Start")
                {
                    Caption = 'Week Start';
                }
                field(planHash; Rec."Plan Hash")
                {
                    Caption = 'Plan Hash';
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWritePlanReviews();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWritePlanReviews();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWritePlanReviews();
        exit(true);
    end;
}
