/// <summary>
/// An AI time-entry suggestion: time the reviewing agent believes a resource spent on
/// a job task (from calendar, GitHub, DevOps or other evidence), for the user to
/// accept or dismiss in Thyme.
///
/// The agent upserts by (Resource No., Source, Source Ref, Date): inserting a second
/// suggestion with the same values is rejected, so it should PATCH the existing one.
/// </summary>
table 50102 "Thyme Time Suggestion"
{
    Caption = 'Thyme Time Suggestion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(6; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(8; Source; Enum "Thyme Suggestion Source")
        {
            Caption = 'Source';
        }
        field(9; "Source Ref"; Text[250])
        {
            Caption = 'Source Ref';
        }
        field(10; "Source Url"; Text[2048])
        {
            Caption = 'Source Url';
            ExtendedDatatype = URL;
        }
        field(11; Evidence; Text[2048])
        {
            Caption = 'Evidence';
        }
        field(12; Confidence; Enum "Thyme Suggestion Confidence")
        {
            Caption = 'Confidence';
        }
        field(13; Status; Enum "Thyme Suggestion Status")
        {
            Caption = 'Status';
            InitValue = Pending;
        }
        field(14; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(15; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            MinValue = 0;
        }
        field(16; "Created By"; Text[100])
        {
            Caption = 'Created By';
        }
        field(17; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(18; "Actioned At"; DateTime)
        {
            Caption = 'Actioned At';
        }
        // Time sheet owner of the suggestion's resource: the user the suggestion is for.
        // Used by "Thyme Record Security" to show a suggestion only to that user.
        field(19; "Resource Owner User ID"; Code[50])
        {
            Caption = 'Resource Owner User ID';
            FieldClass = FlowField;
            CalcFormula = lookup(Resource."Time Sheet Owner User ID" where("No." = field("Resource No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Supports the week view: $filter=resourceNo eq '...' and date ge ... and date le ...
        key(ResourceDate; "Resource No.", Date)
        {
        }
        // Upsert lookup; uniqueness is enforced in OnInsert (see CheckNotDuplicate).
        key(ResourceSourceRefDate; "Resource No.", Source, "Source Ref", Date)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Resource No.");
        TestField(Date);
        CheckNotDuplicate();
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
        SetActionedAt();
    end;

    trigger OnModify()
    begin
        CheckNotDuplicate();
        SetActionedAt();
    end;

    /// <summary>
    /// Rejects a second suggestion (on insert, or a PATCH that would create one) for the
    /// same resource, source, source reference and date, so the agent can re-run
    /// without creating duplicates. Suggestions without a source reference cannot be
    /// matched, so they are not checked.
    /// </summary>
    local procedure CheckNotDuplicate()
    var
        Existing: Record "Thyme Time Suggestion";
    begin
        if "Source Ref" = '' then
            exit;

        Existing.SetCurrentKey("Resource No.", Source, "Source Ref", Date);
        Existing.SetRange("Resource No.", "Resource No.");
        Existing.SetRange(Source, Source);
        Existing.SetRange("Source Ref", "Source Ref");
        Existing.SetRange(Date, Date);
        Existing.SetFilter("Entry No.", '<>%1', "Entry No.");
        if Existing.FindFirst() then
            Error(DuplicateSuggestionErr, "Resource No.", Source, "Source Ref", Date, Existing."Entry No.");
    end;

    /// <summary>
    /// Stamps when a suggestion was accepted or dismissed, unless the caller supplied it.
    /// </summary>
    local procedure SetActionedAt()
    begin
        if (Status <> Status::Pending) and ("Actioned At" = 0DT) then
            "Actioned At" := CurrentDateTime();
    end;

    var
        DuplicateSuggestionErr: Label 'A suggestion for resource %1 from %2 %3 on %4 already exists (entry %5). Update it instead of creating a new one.', Comment = '%1 = resource number, %2 = source, %3 = source reference, %4 = date, %5 = existing entry number';
}
