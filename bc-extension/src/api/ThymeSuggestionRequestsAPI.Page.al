/// <summary>
/// Custom API page for on-demand AI time suggestion requests. Thyme creates a request for
/// the resource and week on screen and polls it for progress; the agent claims Requested
/// rows, updates their progress and finishes them as Done or Failed.
///
/// Create (Thyme):
///   POST .../suggestionRequests  { "resourceNo": "R0010", "fromDate": "2026-01-05", "toDate": "2026-01-11" }
/// Latest request for a resource's week (Thyme):
///   GET .../suggestionRequests?$filter=resourceNo eq 'R0010' and fromDate eq 2026-01-05
///       and toDate eq 2026-01-11&$orderby=requestedAt desc&$top=1
/// Waiting requests, oldest first (agent):
///   GET .../suggestionRequests?$filter=status eq 'Requested'&$orderby=requestedAt
///
/// Who can do what (codeunit "Thyme Record Security"):
/// - read: the resource's time sheet owner and approver, Thyme administrators, the AI agent;
/// - create: the same people (owner and approver for that resource only);
/// - change or delete: only the AI agent.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/suggestionRequests
/// </summary>
page 50114 "Thyme Suggestion Requests API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'suggestionRequest';
    EntitySetName = 'suggestionRequests';
    EntityCaption = 'Suggestion Request';
    EntitySetCaption = 'Suggestion Requests';
    PageType = API;
    SourceTable = "Thyme Suggestion Request";
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
                field(fromDate; Rec."From Date")
                {
                    Caption = 'From Date';
                }
                field(toDate; Rec."To Date")
                {
                    Caption = 'To Date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(progress; Rec.Progress)
                {
                    Caption = 'Progress';
                }
                field(createdCount; Rec."Created Count")
                {
                    Caption = 'Created Count';
                }
                field(updatedCount; Rec."Updated Count")
                {
                    Caption = 'Updated Count';
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
        RecordSecurity.ApplySuggestionRequestFilter(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanRequestSuggestions(Rec."Resource No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanChangeSuggestionRequests();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanChangeSuggestionRequests();
        exit(true);
    end;
}
