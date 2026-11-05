/// <summary>
/// Adds a per-person billable target to the Resource table.
///
/// "Thyme Billable Target Set" tells "not set" apart from a real 0% target:
/// - Set = false: the resource has no target of its own; Thyme uses the company default
///   from Thyme Setup ("Default Billable Target %"). The percentage is kept at 0.
/// - Set = true: "Thyme Billable Target %" is the resource's target, and 0 means 0%.
/// Entering a percentage marks the target as set; clearing the flag resets the percentage to 0.
///
/// Weekly capacity works the same way:
/// - "Thyme Weekly Capacity Set" = false: Thyme uses hours per day (from the resource's HOUR
///   unit of measure) x 5. The hours are kept at 0.
/// - Set = true: "Thyme Weekly Capacity (Hours)" is the person's weekly capacity. 0 is a real
///   value: the person is listed in Thyme but not counted (for example an AI agent).
/// "Thyme Flexible Working Days" means the person works their weekly capacity on any days
/// rather than fixed weekdays, so Thyme judges their week as a whole.
///
/// "Thyme GitHub Username" is the person's GitHub login, so the AI agent knows whose GitHub
/// activity is whose (their Azure DevOps user is their Microsoft 365 sign-in, from the time sheet
/// owner). Blank = not set: the agent falls back to its own config and lookups. A Thyme
/// administrator can change it for anyone, and a person for their own resource (the one whose
/// Time Sheet Owner User ID is them); see codeunit "Thyme Connected Accounts".
/// </summary>
tableextension 50100 "Thyme Resource" extends Resource
{
    fields
    {
        field(50100; "Thyme Billable Target %"; Decimal)
        {
            Caption = 'Thyme Billable Target %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;

            // MinValue/MaxValue aren't enforced through API pages, so check explicitly
            trigger OnValidate()
            begin
                if (Rec."Thyme Billable Target %" < 0) or (Rec."Thyme Billable Target %" > 100) then
                    Error(BillableTargetRangeErr);
                Rec."Thyme Billable Target Set" := true;
            end;
        }
        field(50101; "Thyme Billable Target Set"; Boolean)
        {
            Caption = 'Thyme Billable Target Set';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not Rec."Thyme Billable Target Set" then
                    Rec."Thyme Billable Target %" := 0;
            end;
        }
        field(50102; "Thyme Weekly Capacity (Hours)"; Decimal)
        {
            Caption = 'Thyme Weekly Capacity (Hours)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 168;

            trigger OnValidate()
            begin
                if (Rec."Thyme Weekly Capacity (Hours)" < 0) or (Rec."Thyme Weekly Capacity (Hours)" > 168) then
                    Error(WeeklyCapacityRangeErr);
                Rec."Thyme Weekly Capacity Set" := true;
            end;
        }
        field(50103; "Thyme Weekly Capacity Set"; Boolean)
        {
            Caption = 'Thyme Weekly Capacity Set';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not Rec."Thyme Weekly Capacity Set" then
                    Rec."Thyme Weekly Capacity (Hours)" := 0;
            end;
        }
        field(50104; "Thyme Flexible Working Days"; Boolean)
        {
            Caption = 'Thyme Flexible Working Days';
            DataClassification = CustomerContent;
        }
        field(50105; "Thyme GitHub Username"; Text[39])
        {
            Caption = 'GitHub Username';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                ConnectedAccounts: Codeunit "Thyme Connected Accounts";
                RecordSecurity: Codeunit "Thyme Record Security";
            begin
                RecordSecurity.CheckCanEditConnectedAccounts(Rec."No.");
                Rec."Thyme GitHub Username" := CopyStr(ConnectedAccounts.NormaliseGitHubUsername(Rec."Thyme GitHub Username"), 1, MaxStrLen(Rec."Thyme GitHub Username"));
            end;
        }
    }

    var
        BillableTargetRangeErr: Label 'The billable target must be from 0 to 100.';
        WeeklyCapacityRangeErr: Label 'The weekly capacity must be from 0 to 168 hours.';
}
