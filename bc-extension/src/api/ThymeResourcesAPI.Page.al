/// <summary>
/// Custom API page exposing Resources with capacity data.
/// Enables Thyme to fetch weekly hours targets and billable targets per employee.
///
/// canRequestSuggestions is true when the caller may ask the agent for time suggestions for
/// the resource (see the suggestionRequests endpoint).
///
/// billableTargetPercent (0..100) is only meaningful when billableTargetSet is true;
/// otherwise Thyme uses defaultBillableTargetPercent from the thymeSetup endpoint.
/// billableTargetPercent comes before billableTargetSet so that, when a PATCH sends both,
/// the flag is applied last (setting a percentage marks the target as set).
///
/// weeklyCapacityHours is only meaningful when weeklyCapacitySet is true; otherwise Thyme uses
/// hours per day x 5. An explicit 0 means the person is listed but not counted. The same
/// ordering rule applies: the flag comes after the hours. flexibleWorkingDays means the person
/// works their weekly capacity on any days, so Thyme judges the week rather than each day.
///
/// githubUsername is the person's GitHub login (their Azure DevOps user is their Microsoft 365
/// sign-in, so it isn't stored). canEditConnectedAccounts is true when the caller may change it: a
/// Thyme administrator for anyone, a person for their own resource. Change it with the
/// setGitHubUsername action, which works without permission to modify resources:
///   POST /resources({id})/Microsoft.NAV.setGitHubUsername   { "githubUsername": "alex-contoso" }
/// ("" clears it). A PATCH works too, for callers who may modify resources; the same rule applies.
///
/// canEditPlan is true when the caller may change the plan (resource planning lines and what goes
/// with them): a user with permission to write Job Planning Lines. Per caller, the same on every row.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/resources
/// </summary>
page 50104 "Thyme Resources API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'resource';
    EntitySetName = 'resources';
    PageType = API;
    SourceTable = Resource;
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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(searchName; Rec."Search Name")
                {
                    Caption = 'Search Name';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(capacity; Rec.Capacity)
                {
                    Caption = 'Capacity';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(baseUnitOfMeasure; Rec."Base Unit of Measure")
                {
                    Caption = 'Base Unit of Measure';
                }
                field(resourceGroupNo; Rec."Resource Group No.")
                {
                    Caption = 'Resource Group No.';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(privacyBlocked; Rec."Privacy Blocked")
                {
                    Caption = 'Privacy Blocked';
                }
                // The person's country (blank = the company's), so the plan review can check
                // public holidays by country. Read-only: change it on the Resource Card.
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                    Editable = false;
                }
                field(useTimeSheet; Rec."Use Time Sheet")
                {
                    Caption = 'Use Time Sheet';
                }
                field(timeSheetOwnerUserId; Rec."Time Sheet Owner User ID")
                {
                    Caption = 'Time Sheet Owner User ID';
                }
                field(timeSheetApproverUserId; Rec."Time Sheet Approver User ID")
                {
                    Caption = 'Time Sheet Approver User ID';
                }
                // Whether the caller may ask the agent for time suggestions for this resource
                // (suggestionRequests). Worked out per caller; read-only.
                field(canRequestSuggestions; CanRequestSuggestions)
                {
                    Caption = 'Can Request Suggestions';
                    Editable = false;
                }
                field(billableTargetPercent; Rec."Thyme Billable Target %")
                {
                    Caption = 'Billable Target %';
                }
                field(billableTargetSet; Rec."Thyme Billable Target Set")
                {
                    Caption = 'Billable Target Set';
                }
                field(weeklyCapacityHours; Rec."Thyme Weekly Capacity (Hours)")
                {
                    Caption = 'Weekly Capacity (Hours)';
                }
                field(weeklyCapacitySet; Rec."Thyme Weekly Capacity Set")
                {
                    Caption = 'Weekly Capacity Set';
                }
                field(flexibleWorkingDays; Rec."Thyme Flexible Working Days")
                {
                    Caption = 'Flexible Working Days';
                }
                field(githubUsername; Rec."Thyme GitHub Username")
                {
                    Caption = 'GitHub Username';
                }
                // Whether the caller may change githubUsername. Per caller; read-only.
                field(canEditConnectedAccounts; CanEditConnectedAccounts)
                {
                    Caption = 'Can Edit Connected Accounts';
                    Editable = false;
                }
                // Whether the caller may change the plan. Per caller; read-only.
                field(canEditPlan; CanEditPlan)
                {
                    Caption = 'Can Edit Plan';
                    Editable = false;
                }
                field(lastDateModified; Rec."Last Date Modified")
                {
                    Caption = 'Last Date Modified';
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
        CallerCanAccessAll: Boolean;
        CallerIsThymeAdmin: Boolean;
        CanRequestSuggestions: Boolean;
        CanEditConnectedAccounts: Boolean;
        CanEditPlan: Boolean;

    trigger OnOpenPage()
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        CallerCanAccessAll := RecordSecurity.CanAccessAll();
        CallerIsThymeAdmin := RecordSecurity.IsThymeAdmin();
        CanEditPlan := RecordSecurity.CanEditPlan();
    end;

    trigger OnAfterGetRecord()
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        CanRequestSuggestions := RecordSecurity.CanRequestSuggestions(Rec, CallerCanAccessAll);
        CanEditConnectedAccounts := RecordSecurity.CanEditConnectedAccounts(Rec, CallerIsThymeAdmin);
    end;

    /// <summary>
    /// Sets the resource's GitHub username (blank clears it). For the person themselves or a
    /// Thyme administrator; doesn't need permission to modify resources.
    /// </summary>
    [ServiceEnabled]
    procedure setGitHubUsername(var ActionContext: WebServiceActionContext; githubUsername: Text)
    var
        ConnectedAccounts: Codeunit "Thyme Connected Accounts";
    begin
        ConnectedAccounts.SetGitHubUsername(Rec."No.", githubUsername);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Thyme Resources API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
