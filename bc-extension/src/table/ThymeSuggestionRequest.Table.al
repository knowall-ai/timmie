/// <summary>
/// An on-demand request for AI time suggestions: "Poppie, look at this person's week now".
/// Created from Thyme (status Requested); the agent polls for Requested rows, claims one
/// (Running, with an ETag so two pollers can't both claim it), reports progress as it goes
/// ("Checking calendar…") and finishes it as Done (with counts) or Failed (with a message).
///
/// At most one open (Requested or Running) request per resource and date range: a second
/// one is rejected, so Thyme shows the progress of the one already open instead.
/// </summary>
table 50104 "Thyme Suggestion Request"
{
    Caption = 'Thyme Suggestion Request';
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
        field(3; "From Date"; Date)
        {
            Caption = 'From Date';
        }
        field(4; "To Date"; Date)
        {
            Caption = 'To Date';
        }
        field(5; Status; Enum "Thyme Suggestion Request Status")
        {
            Caption = 'Status';
            InitValue = Requested;
        }
        // What the agent is doing right now, shown under the spinner in Thyme.
        field(6; Progress; Text[250])
        {
            Caption = 'Progress';
        }
        field(7; "Created Count"; Integer)
        {
            Caption = 'Created Count';
            MinValue = 0;
        }
        field(8; "Updated Count"; Integer)
        {
            Caption = 'Updated Count';
            MinValue = 0;
        }
        // Why a Failed request failed, in words the requester can act on.
        field(9; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(10; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            Editable = false;
        }
        field(11; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            Editable = false;
        }
        field(12; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(13; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
        }
        // Used by "Thyme Record Security" to show a request only to its resource's time
        // sheet owner and approver. AL filters can't OR two fields, so the check is inverted:
        // with "User ID Filter" set to <>(current user), "Hidden From User Filter" is true
        // when the resource's owner AND approver are both someone else.
        field(14; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Hidden From User Filter"; Boolean)
        {
            Caption = 'Hidden From User Filter';
            FieldClass = FlowField;
            CalcFormula = exist(Resource where("No." = field("Resource No."),
                                               "Time Sheet Owner User ID" = field("User ID Filter"),
                                               "Time Sheet Approver User ID" = field("User ID Filter")));
            Editable = false;
        }
        field(16; "Resource Exists"; Boolean)
        {
            Caption = 'Resource Exists';
            FieldClass = FlowField;
            CalcFormula = exist(Resource where("No." = field("Resource No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Thyme: the latest request for the resource and week on screen; also the open-request check.
        key(ResourceDates; "Resource No.", "From Date", "To Date", Status)
        {
        }
        // Agent: the oldest waiting request.
        key(StatusRequestedAt; Status, "Requested At")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckPeriod();

        // A new request always starts from scratch, whatever the caller sent.
        Status := Status::Requested;
        Progress := '';
        "Created Count" := 0;
        "Updated Count" := 0;
        "Error Message" := '';
        "Started At" := 0DT;
        "Finished At" := 0DT;
        "Requested By" := CopyStr(UpperCase(UserId()), 1, MaxStrLen("Requested By"));
        "Requested At" := CurrentDateTime();

        CheckNoOpenRequest();
    end;

    trigger OnModify()
    begin
        CheckPeriod();
        // Re-opening a finished request (or moving one to another period) must not make a
        // second open request for the same resource and period.
        if Status in [Status::Requested, Status::Running] then
            CheckNoOpenRequest();
        if (Status in [Status::Running, Status::Done, Status::Failed]) and ("Started At" = 0DT) then
            "Started At" := CurrentDateTime();
        if (Status in [Status::Done, Status::Failed]) and ("Finished At" = 0DT) then
            "Finished At" := CurrentDateTime();
    end;

    /// <summary>
    /// Longest range one request may cover, in days (a time sheet week).
    /// </summary>
    procedure MaxDays(): Integer
    begin
        exit(7);
    end;

    local procedure CheckPeriod()
    begin
        TestField("Resource No.");
        TestField("From Date");
        TestField("To Date");
        if "To Date" < "From Date" then
            Error(ToBeforeFromErr, "To Date", "From Date");
        if "To Date" - "From Date" > MaxDays() - 1 then
            Error(RangeTooLongErr, MaxDays());
        // A day's leeway: BC's Today() is the server (UTC) date, and a user east of UTC may
        // already be in the new week.
        if "From Date" > Today() + 1 then
            Error(FutureErr, "From Date");
    end;

    local procedure CheckNoOpenRequest()
    var
        Existing: Record "Thyme Suggestion Request";
        Resource: Record Resource;
    begin
        // Two requests arriving together could both find no open request. Locking the
        // resource row first serialises them: the second waits, then sees the first.
        Resource.LockTable();
        if Resource.Get("Resource No.") then;

        Existing.SetCurrentKey("Resource No.", "From Date", "To Date", Status);
        Existing.SetRange("Resource No.", "Resource No.");
        Existing.SetRange("From Date", "From Date");
        Existing.SetRange("To Date", "To Date");
        Existing.SetFilter(Status, '%1|%2', Status::Requested, Status::Running);
        Existing.SetFilter("Entry No.", '<>%1', "Entry No.");
        if Existing.FindFirst() then
            Error(OpenRequestExistsErr, "Resource No.", "From Date", "To Date", Existing."Entry No.");
    end;

    var
        ToBeforeFromErr: Label 'The To Date (%1) can''t be before the From Date (%2).', Comment = '%1 = to date, %2 = from date';
        RangeTooLongErr: Label 'A suggestion request can cover at most %1 days.', Comment = '%1 = number of days';
        FutureErr: Label 'Suggestions can''t be requested for a period that hasn''t started yet (%1).', Comment = '%1 = from date';
        OpenRequestExistsErr: Label 'Suggestions for resource %1 from %2 to %3 have already been requested (entry %4). Wait for that request to finish.', Comment = '%1 = resource number, %2 = from date, %3 = to date, %4 = entry number';
}
