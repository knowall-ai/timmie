/// <summary>
/// Custom API page for the changes AI plan reviews propose to planning-line cells, in hours.
/// A finding's changes (same reviewEntryNo and reviewLineNo) are applied together by Thyme's
/// "Apply change", which re-checks that the cell still holds currentHours and then writes the
/// planning lines with the user's own permissions (canEditPlan on projects). proposedHours is a
/// multiple of 0.25; 0 means remove the cell's planning line(s).
///
/// Changes for one review:
///   GET .../planReviewChanges?$filter=reviewEntryNo eq 42
///
/// Who can do what (codeunit "Thyme Record Security"): every Thyme user reads them; only the
/// AI agent or a Thyme administrator creates, changes or deletes them.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/planReviewChanges
/// </summary>
page 50120 "Thyme Plan Review Changes API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'planReviewChange';
    EntitySetName = 'planReviewChanges';
    EntityCaption = 'Plan Review Change';
    EntitySetCaption = 'Plan Review Changes';
    PageType = API;
    SourceTable = "Thyme Plan Review Change";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    // THYME ADMIN writes proposed changes only indirectly, through this page and its
    // CheckCanWritePlanReviews triggers; the AI agent has direct access.
    Permissions = tabledata "Thyme Plan Review Change" = rimd;

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
                field(reviewLineNo; Rec."Review Line No.")
                {
                    Caption = 'Review Line No.';
                }
                field(changeNo; Rec."Change No.")
                {
                    Caption = 'Change No.';
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(planningDate; Rec."Planning Date")
                {
                    Caption = 'Planning Date';
                }
                field(currentHours; Rec."Current Hours")
                {
                    Caption = 'Current Hours';
                }
                field(proposedHours; Rec."Proposed Hours")
                {
                    Caption = 'Proposed Hours';
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
