/// <summary>
/// Custom API page for on-demand AI timesheet review requests. Thyme creates a request for
/// the time sheet on screen ("Ask Poppie to look again") and polls it for progress; the agent
/// claims Requested rows, updates their progress and finishes them as Done or Failed.
///
/// Create (Thyme):
///   POST .../timesheetReviewRequests  { "timeSheetNo": "TS00042" }
/// Latest request for a time sheet (Thyme):
///   GET .../timesheetReviewRequests?$filter=timeSheetNo eq 'TS00042'  $orderby=requestedAt desc  $top=1
/// Waiting requests, oldest first (agent):
///   GET .../timesheetReviewRequests?$filter=status eq 'Requested'  $orderby=requestedAt
///
/// Who can do what (codeunit "Thyme Record Security"):
/// - read: the time sheet's owner and approver, Thyme administrators, the AI agent (the same
///   people who see the time sheet's reviews);
/// - create: the same people (owner and approver for that time sheet only);
/// - change or delete: only the AI agent.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timesheetReviewRequests
/// </summary>
page 50124 "Thyme TS Review Requests API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timesheetReviewRequest';
    EntitySetName = 'timesheetReviewRequests';
    EntityCaption = 'Timesheet Review Request';
    EntitySetCaption = 'Timesheet Review Requests';
    PageType = API;
    SourceTable = "Thyme Timesheet Review Request";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    // THYME USER only has indirect insert on requests, so they are created through this page
    // and its owner-or-approver check. The AI agent's own direct RIMD covers its changes.
    Permissions = tabledata "Thyme Timesheet Review Request" = i;

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

    trigger OnOpenPage()
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.ApplyTimesheetReviewRequestFilter(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanRequestTimesheetReview(Rec."Time Sheet No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanChangeTimesheetReviewRequests();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanChangeTimesheetReviewRequests();
        exit(true);
    end;
}
