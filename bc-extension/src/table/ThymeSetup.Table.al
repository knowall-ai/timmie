/// <summary>
/// Company-wide Thyme settings (a single record with a blank primary key).
/// Holds the default billable target used for resources that have no target of their own.
///
/// Read and modified by Thyme through the thymeSetup API; edited in BC on the Thyme Setup page.
/// </summary>
table 50103 "Thyme Setup"
{
    Caption = 'Thyme Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "Thyme Setup";
    LookupPageId = "Thyme Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            AllowInCustomizations = Never;
        }
        field(2; "Default Billable Target %"; Decimal)
        {
            Caption = 'Default Billable Target %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
            InitValue = 75;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Creates the setup record with its default values if it doesn't exist yet.
    /// </summary>
    procedure InsertIfNotExists()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}
