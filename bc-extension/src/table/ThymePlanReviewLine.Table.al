/// <summary>
/// A single finding within an AI plan review. "Check" says which check raised it (ROUNDING,
/// OVER_CAPACITY, BILLABLE_TARGET, CALENDAR, BUDGET_BURN, PLAN_SHAPE, OUTSIDE_PROJECT_DATES
/// or OTHER); "Planning Date" = 0D means the finding is about the whole week. A finding can
/// carry proposed changes to planning-line cells ("Thyme Plan Review Change"), applied together.
/// </summary>
table 50108 "Thyme Plan Review Line"
{
    Caption = 'Thyme Plan Review Line';
    DataClassification = CustomerContent;
    // For the cascade in OnDelete when a Thyme administrator (indirect access only) deletes a finding.
    Permissions = tabledata "Thyme Plan Review Change" = rd;

    fields
    {
        field(1; "Review Entry No."; Integer)
        {
            Caption = 'Review Entry No.';
            TableRelation = "Thyme Plan Review"."Entry No.";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Severity; Enum "Thyme Review Severity")
        {
            Caption = 'Severity';
        }
        field(4; Check; Code[30])
        {
            Caption = 'Check';
        }
        // Optional: the day the finding is about (0D = the whole week).
        field(5; "Planning Date"; Date)
        {
            Caption = 'Planning Date';
        }
        field(6; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(7; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(8; Note; Text[500])
        {
            Caption = 'Note';
        }
        // Stamped by "Thyme Plan Review Apply" when the finding's changes are applied from Thyme.
        field(9; "Applied At"; DateTime)
        {
            Caption = 'Applied At';
            Editable = false;
        }
        field(10; "Applied By"; Code[50])
        {
            Caption = 'Applied By';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Review Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        ReviewLine: Record "Thyme Plan Review Line";
    begin
        CheckAgainstReview();

        // Callers may omit lineNo; number findings in 10000 steps like BC's own lines.
        if "Line No." = 0 then begin
            ReviewLine.SetRange("Review Entry No.", "Review Entry No.");
            if ReviewLine.FindLast() then
                "Line No." := ReviewLine."Line No." + 10000
            else
                "Line No." := 10000;
        end;
    end;

    trigger OnModify()
    begin
        CheckAgainstReview();
    end;

    /// <summary>
    /// Changing the key (a PATCH of a key field) would move the row without the OnModify checks,
    /// so it is refused: delete it and create a new one instead.
    /// </summary>
    trigger OnRename()
    begin
        Error(RenameNotAllowedErr);
    end;

    /// <summary>
    /// Deleting a finding removes its proposed changes too.
    /// </summary>
    trigger OnDelete()
    var
        StoredLine: Record "Thyme Plan Review Line";
        ReviewChange: Record "Thyme Plan Review Change";
    begin
        // Lock the finding first: a change being added waits on the same lock, then finds the
        // finding gone, so none is left orphaned.
        StoredLine.ReadIsolation := IsolationLevel::UpdLock;
        if StoredLine.Get("Review Entry No.", "Line No.") then;
        ReviewChange.SetRange("Review Entry No.", "Review Entry No.");
        ReviewChange.SetRange("Review Line No.", "Line No.");
        ReviewChange.DeleteAll();
    end;

    /// <summary>
    /// The review must exist, and a finding about a particular day must be about a day in the
    /// review's week.
    /// </summary>
    local procedure CheckAgainstReview()
    var
        Review: Record "Thyme Plan Review";
    begin
        TestField("Review Entry No.");
        // Lock the review (held until commit) so it can't move to another subject-week or be
        // deleted between this check and the commit.
        Review.ReadIsolation := IsolationLevel::UpdLock;
        if not Review.Get("Review Entry No.") then
            Error(ReviewNotFoundErr, "Review Entry No.");
        if "Planning Date" = 0D then
            exit;
        if ("Planning Date" < Review."Week Start") or ("Planning Date" > Review."Week Start" + 6) then
            Error(DateOutsideWeekErr, "Planning Date", Review."Week Start", "Review Entry No.");
    end;

    var
        RenameNotAllowedErr: Label 'A finding''s review entry number and line number can''t be changed. Delete the finding and create a new one instead.';
        ReviewNotFoundErr: Label 'Plan review %1 does not exist.', Comment = '%1 = review entry number';
        DateOutsideWeekErr: Label '%1 isn''t in the week starting %2 that plan review %3 covers.', Comment = '%1 = planning date, %2 = week start date, %3 = review entry number';
}
