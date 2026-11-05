/// <summary>
/// Custom API page for project source links: the GitHub repos, Azure DevOps projects and repos, meeting
/// keywords and attendee domains that belong to a project, optionally with the task to log
/// that time against. The AI agent reads them to map activity to projects when it suggests
/// time entries; Thyme shows and edits them on the project page.
///
/// Every link of a project (Thyme):
///   GET .../projectSourceLinks?$filter=jobNo eq 'PR00010'
/// Add one (Thyme; a GitHub URL is stored as owner/repo):
///   POST .../projectSourceLinks  { "jobNo": "PR00010", "type": "GitHubRepo", "value": "https://github.com/contoso/app", "jobTaskNo": "100" }
/// Every link in the company (agent):
///   GET .../projectSourceLinks
///
/// Who can do what (codeunit "Thyme Record Security", enforced by the table):
/// - read: every Thyme user;
/// - create, change, delete: Thyme administrators and the project's manager (see the projects
///   API's canEditSourceLinks);
/// - the AI agent: create learned links (learned = true), and change or delete only those.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/projectSourceLinks
/// </summary>
page 50116 "Thyme Project Source Links API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'projectSourceLink';
    EntitySetName = 'projectSourceLinks';
    EntityCaption = 'Project Source Link';
    EntitySetCaption = 'Project Source Links';
    PageType = API;
    SourceTable = "Thyme Project Source Link";
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
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(value; Rec.Value)
                {
                    Caption = 'Value';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(useMonthlyBlock; Rec."Use Monthly Block")
                {
                    Caption = 'Use Monthly Block';
                }
                field(learned; Rec.Learned)
                {
                    Caption = 'Learned';
                    Editable = false;
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                    Editable = false;
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'Created At';
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
}
