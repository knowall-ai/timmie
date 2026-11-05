/// <summary>
/// A note on a particular day, e.g. "Company Off-Site", shown on Thyme's Plan grid and read
/// by the AI agent's plan review. A blank Resource No. means the note is for the whole
/// company; otherwise it is just for that person.
///
/// "No Project Work" marks the day as not available for project work (capacity 0 that day,
/// e.g. an off-site or a holiday), so Thyme counts any hours planned on it as over capacity
/// and the plan review treats it like a public holiday.
/// </summary>
table 50111 "Thyme Day Note"
{
    Caption = 'Thyme Day Note';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Note Date"; Date)
        {
            Caption = 'Note Date';
            NotBlank = true;
        }
        // Blank = the whole company.
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(4; Note; Text[100])
        {
            Caption = 'Note';
            NotBlank = true;
        }
        field(5; "No Project Work"; Boolean)
        {
            Caption = 'No Project Work';
        }
        field(6; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
        }
        field(7; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
        }
        field(8; "Modified By"; Code[50])
        {
            Caption = 'Modified By';
            Editable = false;
        }
        field(9; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Thyme: the notes for the dates on screen ($filter=noteDate ge ... and noteDate le ...).
        key(DateResource; "Note Date", "Resource No.")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckNote();
        "Created By" := CopyStr(UpperCase(UserId()), 1, MaxStrLen("Created By"));
        "Created At" := CurrentDateTime();
        "Modified By" := '';
        "Modified At" := 0DT;
    end;

    trigger OnModify()
    begin
        CheckNote();
        "Modified By" := CopyStr(UpperCase(UserId()), 1, MaxStrLen("Modified By"));
        "Modified At" := CurrentDateTime();
    end;

    local procedure CheckNote()
    begin
        TestField("Note Date");
        if DelChr(Note, '<>', ' ') = '' then
            FieldError(Note, NoteBlankErr);
    end;

    var
        NoteBlankErr: Label 'must not be blank';
}
