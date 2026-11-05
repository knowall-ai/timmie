/// <summary>
/// Custom API page exposing the company-wide Thyme settings (a single record).
/// Thyme reads the default billable target and lets admins change it.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/thymeSetup
/// Update with PATCH /thymeSetup({id}); the record can't be inserted or deleted.
/// </summary>
page 50112 "Thyme Setup API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'thymeSetup';
    EntitySetName = 'thymeSetup';
    PageType = API;
    SourceTable = "Thyme Setup";
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
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
                field(defaultBillableTargetPercent; Rec."Default Billable Target %")
                {
                    Caption = 'Default Billable Target %';
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
    begin
        // The install and upgrade codeunits create the record; this covers companies
        // created later. Users who can only read get an empty result rather than an error.
        if Rec.WritePermission() then
            Rec.InsertIfNotExists();
    end;
}
