/// <summary>
/// A project's note, as the projectNotes API returns it: one of Business Central's own
/// Notes on the project (the Notes factbox on the Project card, stored as a Record Link
/// of type Note), so a note added in Thyme shows in Business Central and the other way
/// round. Temporary: filled per request by codeunit "Thyme Project Notes"; nothing is
/// stored here.
/// </summary>
table 50112 "Thyme Project Note"
{
    Caption = 'Thyme Project Note';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        // The Record Link's Link ID
        field(1; "Link ID"; Integer)
        {
            Caption = 'Link ID';
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(3; Note; Text[2048])
        {
            Caption = 'Note';
        }
        field(4; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        // The BC user who wrote it (User Name), and their full name to show
        field(5; "Created By"; Code[50])
        {
            Caption = 'Created By';
        }
        field(6; "Created By Name"; Text[80])
        {
            Caption = 'Created By Name';
        }
        // Newest first, as Thyme lists them
        field(7; "Sort Key"; BigInteger)
        {
            Caption = 'Sort Key';
        }
    }

    keys
    {
        key(PK; "Link ID")
        {
            Clustered = true;
        }
        key(Newest; "Sort Key")
        {
        }
    }
}
