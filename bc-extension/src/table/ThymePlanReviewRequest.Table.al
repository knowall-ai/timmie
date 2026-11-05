/// <summary>
/// An on-demand request for an AI plan review: "Poppie, look at this week's plan now".
/// Created from Thyme (status Requested) for one subject-week (a person's or a project's
/// week); the agent polls for Requested rows, claims one (Running, with an ETag so two pollers
/// can't both claim it), reports progress as it goes and finishes it as Done or Failed (with
/// a message).
///
/// At most one open (Requested or Running) request per subject-week: a second one is
/// rejected, so Thyme shows the progress of the one already open instead.
/// </summary>
table 50110 "Thyme Plan Review Request"
{
    Caption = 'Thyme Plan Review Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Subject Type"; Enum "Thyme Plan Review Subject")
        {
            Caption = 'Subject Type';
        }
        // Resource No. for a resource-week, Job No. for a project-week.
        field(3; "Subject No."; Code[20])
        {
            Caption = 'Subject No.';
            TableRelation = if ("Subject Type" = const(Resource)) Resource
            else
            if ("Subject Type" = const(Project)) Job;
        }
        // The Monday the week starts on (local date).
        field(4; "Week Start"; Date)
        {
            Caption = 'Week Start';
        }
        field(5; Status; Enum "Thyme Plan Review Req. Status")
        {
            Caption = 'Status';
            InitValue = Requested;
        }
        // What the agent is doing right now, shown under the spinner in Thyme.
        field(6; Progress; Text[250])
        {
            Caption = 'Progress';
        }
        // Why a Failed request failed, in words the requester can act on.
        field(7; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(8; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            Editable = false;
        }
        field(9; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            Editable = false;
        }
        field(10; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(11; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Thyme: the latest request for the subject-week on screen; also the open-request check.
        key(SubjectWeek; "Subject Type", "Subject No.", "Week Start", Status)
        {
        }
        // Agent: the oldest waiting request.
        key(StatusRequestedAt; Status, "Requested At")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckSubjectWeek();

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
        CheckSubjectWeek();
        // Re-opening a finished request (or moving one to another subject-week) must not make
        // a second open request for the same subject-week.
        if Status in [Status::Requested, Status::Running] then
            CheckNoOpenRequest();
        if (Status in [Status::Running, Status::Done, Status::Failed]) and ("Started At" = 0DT) then
            "Started At" := CurrentDateTime();
        if (Status in [Status::Done, Status::Failed]) and ("Finished At" = 0DT) then
            "Finished At" := CurrentDateTime();
    end;

    local procedure CheckSubjectWeek()
    begin
        TestField("Subject No.");
        TestField("Week Start");
        if Date2DWY("Week Start", 1) <> 1 then
            Error(WeekStartNotMondayErr, "Week Start");
    end;

    local procedure CheckNoOpenRequest()
    var
        Existing: Record "Thyme Plan Review Request";
        Resource: Record Resource;
        Job: Record Job;
    begin
        // Two requests arriving together could both find no open request. Locking the
        // subject's row first serialises them: the second waits, then sees the first.
        case "Subject Type" of
            "Subject Type"::Resource:
                begin
                    Resource.LockTable();
                    if Resource.Get("Subject No.") then;
                end;
            "Subject Type"::Project:
                begin
                    Job.LockTable();
                    if Job.Get("Subject No.") then;
                end;
        end;

        Existing.SetCurrentKey("Subject Type", "Subject No.", "Week Start", Status);
        Existing.SetRange("Subject Type", "Subject Type");
        Existing.SetRange("Subject No.", "Subject No.");
        Existing.SetRange("Week Start", "Week Start");
        Existing.SetFilter(Status, '%1|%2', Status::Requested, Status::Running);
        Existing.SetFilter("Entry No.", '<>%1', "Entry No.");
        // Read committed, so another session's uncommitted change doesn't hide an open request.
        Existing.ReadIsolation := IsolationLevel::ReadCommitted;
        if Existing.FindFirst() then
            Error(OpenRequestExistsErr, "Subject Type", "Subject No.", "Week Start", Existing."Entry No.");
    end;

    var
        WeekStartNotMondayErr: Label 'The week must start on a Monday; %1 isn''t one.', Comment = '%1 = week start date';
        OpenRequestExistsErr: Label 'A plan review of %1 %2 for the week starting %3 has already been requested (entry %4). Wait for that request to finish.', Comment = '%1 = subject type (Resource or Project), %2 = resource or job number, %3 = week start date, %4 = entry number';
}
