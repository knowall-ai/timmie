/// <summary>
/// Custom API page for the findings of AI plan reviews. planningDate = 0001-01-01 (blank)
/// means the finding is about the whole week. check is the check that raised it: ROUNDING,
/// OVER_CAPACITY, BILLABLE_TARGET, CALENDAR, BUDGET_BURN, PLAN_SHAPE, OUTSIDE_PROJECT_DATES
/// or OTHER.
///
/// appliedAt / appliedBy are stamped when a user applies the finding's changes with the
/// applyChanges action (POST .../planReviewLines({id})/Microsoft.NAV.applyChanges, no body):
/// all of them in one transaction, for a user who may change the plan (canEditPlan).
///
/// Findings for one review:
///   GET .../planReviewLines?$filter=reviewEntryNo eq 42
///
/// Who can do what (codeunit "Thyme Record Security"): every Thyme user reads them; only the
/// AI agent or a Thyme administrator creates, changes or deletes them.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/planReviewLines
/// </summary>
page 50119 "Thyme Plan Review Lines API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'planReviewLine';
    EntitySetName = 'planReviewLines';
    EntityCaption = 'Plan Review Line';
    EntitySetCaption = 'Plan Review Lines';
    PageType = API;
    SourceTable = "Thyme Plan Review Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    // THYME ADMIN writes findings only indirectly, through this page and its
    // CheckCanWritePlanReviews triggers; the AI agent has direct access.
    Permissions = tabledata "Thyme Plan Review Line" = rimd;

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
                field(severity; Rec.Severity)
                {
                    Caption = 'Severity';
                }
                field(check; Rec.Check)
                {
                    Caption = 'Check';
                }
                field(planningDate; Rec."Planning Date")
                {
                    Caption = 'Planning Date';
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(note; Rec.Note)
                {
                    Caption = 'Note';
                }
                field(appliedAt; Rec."Applied At")
                {
                    Caption = 'Applied At';
                    Editable = false;
                }
                field(appliedBy; Rec."Applied By")
                {
                    Caption = 'Applied By';
                    Editable = false;
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

    /// <summary>
    /// Applies all of this finding's proposed changes to the planning lines in one transaction
    /// (codeunit "Thyme Plan Review Apply"), for a user who may change the plan.
    ///   POST .../planReviewLines({id})/Microsoft.NAV.applyChanges   (no body)
    /// </summary>
    [ServiceEnabled]
    procedure applyChanges(var ActionContext: WebServiceActionContext)
    var
        PlanReviewApply: Codeunit "Thyme Plan Review Apply";
    begin
        PlanReviewApply.ApplyChanges(Rec);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Plan Review Lines API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
