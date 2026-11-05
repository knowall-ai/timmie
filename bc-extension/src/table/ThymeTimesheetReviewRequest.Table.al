/// <summary>
/// An on-demand request for an AI timesheet review: "Poppie, look at this timesheet again".
/// Created from Thyme (status Requested) for one time sheet; the agent polls for Requested
/// rows, claims one (Running, with an ETag so two pollers can't both claim it), reports
/// progress as it goes and finishes it as Done or Failed (with a message).
///
/// At most one open (Requested or Running) request per time sheet: a second one is
/// rejected, so Thyme shows the progress of the one already open instead.
/// </summary>
table 50113 "Thyme Timesheet Review Request"
{
    Caption = 'Thyme Timesheet Review Request';
    DataClassification = CustomerContent;
    // CheckNoOpenRequest locks and reads the time sheet header, even for callers without direct access
    Permissions = tabledata "Time Sheet Header" = r;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(3; Status; Enum "Thyme TS Review Req. Status")
        {
            Caption = 'Status';
            InitValue = Requested;
        }
        // What the agent is doing right now, shown under the spinner in Thyme.
        field(4; Progress; Text[250])
        {
            Caption = 'Progress';
        }
        // Why a Failed request failed, in words the requester can act on.
        field(5; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(6; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            Editable = false;
        }
        field(7; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            Editable = false;
        }
        field(8; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(9; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
        }
        // Used by "Thyme Record Security" to show a request only to its time sheet's owner and
        // approver, as for the reviews themselves. AL filters can't OR two fields, so the check
        // is inverted: with "User ID Filter" set to <>(current user), "Hidden From User Filter"
        // is true when the time sheet's owner AND approver are both someone else.
        field(10; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Hidden From User Filter"; Boolean)
        {
            Caption = 'Hidden From User Filter';
            FieldClass = FlowField;
            CalcFormula = exist("Time Sheet Header" where("No." = field("Time Sheet No."),
                                                          "Owner User ID" = field("User ID Filter"),
                                                          "Approver User ID" = field("User ID Filter")));
            Editable = false;
        }
        field(12; "Time Sheet Exists"; Boolean)
        {
            Caption = 'Time Sheet Exists';
            FieldClass = FlowField;
            CalcFormula = exist("Time Sheet Header" where("No." = field("Time Sheet No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Thyme: the latest request for the time sheet on screen; also the open-request check.
        key(TimeSheetStatus; "Time Sheet No.", Status)
        {
        }
        // Agent: the oldest waiting request.
        key(StatusRequestedAt; Status, "Requested At")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Time Sheet No.");

        // A new request always starts from scratch, whatever the caller sent.
        Status := Status::Requested;
        Progress := '';
        "Error Message" := '';
        "Started At" := 0DT;
        "Finished At" := 0DT;
        "Requested By" := CopyStr(UpperCase(UserId()), 1, MaxStrLen("Requested By"));
        "Requested At" := CurrentDateTime();

        CheckNoOpenRequest();
    end;

    trigger OnModify()
    begin
        TestField("Time Sheet No.");
        // Re-opening a finished request (or moving one to another time sheet) must not make
        // a second open request for the same time sheet.
        if Status in [Status::Requested, Status::Running] then
            CheckNoOpenRequest();
        if (Status in [Status::Running, Status::Done, Status::Failed]) and ("Started At" = 0DT) then
            "Started At" := CurrentDateTime();
        if (Status in [Status::Done, Status::Failed]) and ("Finished At" = 0DT) then
            "Finished At" := CurrentDateTime();
    end;

    local procedure CheckNoOpenRequest()
    var
        Existing: Record "Thyme Timesheet Review Request";
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // Two requests arriving together could both find no open request. Locking the
        // time sheet's row first serialises them: the second waits, then sees the first.
        TimeSheetHeader.LockTable();
        // It also stops a request for a time sheet that doesn't exist (or was just deleted).
        if not TimeSheetHeader.Get("Time Sheet No.") then
            Error(TimeSheetNotFoundErr, "Time Sheet No.");

        Existing.SetCurrentKey("Time Sheet No.", Status);
        Existing.SetRange("Time Sheet No.", "Time Sheet No.");
        Existing.SetFilter(Status, '%1|%2', Status::Requested, Status::Running);
        Existing.SetFilter("Entry No.", '<>%1', "Entry No.");
        // Read committed, so another session's uncommitted change doesn't hide an open request.
        Existing.ReadIsolation := IsolationLevel::ReadCommitted;
        if Existing.FindFirst() then
            Error(OpenRequestExistsErr, "Time Sheet No.", Existing."Entry No.");
    end;

    var
        TimeSheetNotFoundErr: Label 'Time sheet %1 does not exist.', Comment = '%1 = time sheet number';
        OpenRequestExistsErr: Label 'A review of time sheet %1 has already been requested (entry %2). Wait for that request to finish.', Comment = '%1 = time sheet number, %2 = entry number';
}
