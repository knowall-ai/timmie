/// <summary>
/// Custom API page for on-demand AI plan review requests. Thyme creates a request for a
/// subject-week on screen ("Ask Poppie to re-review") and polls it for progress; the agent
/// claims Requested rows, updates their progress and finishes them as Done or Failed.
///
/// Create (Thyme):
///   POST .../planReviewRequests  { "subjectType": "Resource", "subjectNo": "R0010", "weekStart": "2026-10-19" }
/// Latest request for a subject-week (Thyme):
///   GET .../planReviewRequests?$filter=subjectType eq 'Resource' and subjectNo eq 'R0010'
///       and weekStart eq 2026-10-19  $orderby=requestedAt desc  $top=1
/// Waiting requests, oldest first (agent):
///   GET .../planReviewRequests?$filter=status eq 'Requested'  $orderby=requestedAt
///
/// Who can do what (codeunit "Thyme Record Security"):
/// - read: every Thyme user;
/// - create: people who may change the plan (permission to write Job Planning Lines; being a
///   Thyme administrator or the AI agent doesn't count on its own; canEditPlan on projects and
///   resources);
/// - change or delete: only the AI agent.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/planReviewRequests
/// </summary>
page 50121 "Thyme Plan Review Requests API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'planReviewRequest';
    EntitySetName = 'planReviewRequests';
    EntityCaption = 'Plan Review Request';
    EntitySetCaption = 'Plan Review Requests';
    PageType = API;
    SourceTable = "Thyme Plan Review Request";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    // THYME USER only has indirect insert on requests, so they are created through this page
    // and its CanEditPlan check. The AI agent's own direct RIMD covers its changes.
    Permissions = tabledata "Thyme Plan Review Request" = i;

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
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(progress; Rec.Progress)
                {
                    Caption = 'Progress';
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                }
                field(requestedBy; Rec."Requested By")
                {
                    Caption = 'Requested By';
                    Editable = false;
                }
                field(requestedAt; Rec."Requested At")
                {
                    Caption = 'Requested At';
                    Editable = false;
                }
                field(startedAt; Rec."Started At")
                {
                    Caption = 'Started At';
                }
                field(finishedAt; Rec."Finished At")
                {
                    Caption = 'Finished At';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    var
        NotAllowedToRequestPlanReviewErr: Label 'You are not allowed to request a plan review. You need permission to change the plan (project planning lines).';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanEditPlan(NotAllowedToRequestPlanReviewErr);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanChangePlanReviewRequests();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanChangePlanReviewRequests();
        exit(true);
    end;
}
