/// <summary>
/// Card page for the company-wide Thyme settings.
/// </summary>
page 50113 "Thyme Setup"
{
    Caption = 'Thyme Setup';
    PageType = Card;
    SourceTable = "Thyme Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Targets)
            {
                Caption = 'Targets';

                field("Default Billable Target %"; Rec."Default Billable Target %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the billable target, from 0 to 100, that Thyme uses for people who don''t have their own target on the Resource Card.';
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
