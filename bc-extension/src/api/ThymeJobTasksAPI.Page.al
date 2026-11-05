/// <summary>
/// Custom API page exposing Job Tasks for projects.
/// Thyme filters to only show Posting type tasks (billable).
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/jobTasks
/// </summary>
page 50101 "Thyme Job Tasks API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'jobTask';
    EntitySetName = 'jobTasks';
    PageType = API;
    SourceTable = "Job Task";
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
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(jobTaskType; Rec."Job Task Type")
                {
                    Caption = 'Job Task Type';
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
