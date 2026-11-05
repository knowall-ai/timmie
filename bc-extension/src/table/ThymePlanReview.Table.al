/// <summary>
/// An AI review of the plan (resource planning lines, i.e. Thyme's Plan grid) for one
/// subject-week: one person's week (Subject Type Resource) or one project's week (Project).
/// Written by the reviewing agent through the planReviews API and read by Thyme.
///
/// "Plan Hash" is the lowercase hex SHA-256 of the subject-week's planning lines when it was
/// reviewed, so a reader can tell whether the plan has changed since (and the review is out
/// of date). The agent writes the review with Plan Hash PENDING, then its findings and
/// changes, then the real hash last, so a half-written review never reads as current.
/// </summary>
table 50107 "Thyme Plan Review"
{
    Caption = 'Thyme Plan Review';
    DataClassification = CustomerContent;
    // For the cascade in OnDelete when a Thyme administrator (indirect access only) deletes a review.
    Permissions = tabledata "Thyme Plan Review Line" = rd,
                  tabledata "Thyme Plan Review Change" = rd;

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
            NotBlank = true;
        }
        // The Monday the week starts on (local date).
        field(4; "Week Start"; Date)
        {
            Caption = 'Week Start';
            NotBlank = true;
        }
        field(5; "Plan Hash"; Text[64])
        {
            Caption = 'Plan Hash';
        }
        field(6; Verdict; Enum "Thyme Review Verdict")
        {
            Caption = 'Verdict';
            // Default to the cautious outcome so a review posted without a verdict
            // never reads as an approval.
            InitValue = Check;
        }
        field(7; Summary; Text[2048])
        {
            Caption = 'Summary';
        }
        field(8; Reviewer; Text[100])
        {
            Caption = 'Reviewer';
        }
        field(9; "Reviewed At"; DateTime)
        {
            Caption = 'Reviewed At';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Latest review for a subject-week:
        // $filter=subjectType eq 'Resource' and subjectNo eq 'R0010' and weekStart eq 2026-10-19&$orderby=reviewedAt desc&$top=1
        key(SubjectWeekReviewedAt; "Subject Type", "Subject No.", "Week Start", "Reviewed At")
        {
        }
        // Thyme: every review of the weeks on screen for one kind of subject.
        key(TypeWeek; "Subject Type", "Week Start")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckReview();
        if "Reviewed At" = 0DT then
            "Reviewed At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        CheckReview();
        CheckSubjectWeekUnchanged();
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
    /// Deleting a review removes its findings and their proposed changes too, so nothing is
    /// left orphaned.
    /// </summary>
    trigger OnDelete()
    var
        StoredReview: Record "Thyme Plan Review";
        ReviewLine: Record "Thyme Plan Review Line";
        ReviewChange: Record "Thyme Plan Review Change";
    begin
        // Lock the review first: a finding or change being added waits on the same lock, then
        // finds the review gone, so none is left orphaned.
        StoredReview.ReadIsolation := IsolationLevel::UpdLock;
        if StoredReview.Get("Entry No.") then;
        ReviewLine.SetRange("Review Entry No.", "Entry No.");
        ReviewLine.DeleteAll(true);
        ReviewChange.SetRange("Review Entry No.", "Entry No.");
        ReviewChange.DeleteAll();
    end;

    local procedure CheckReview()
    begin
        TestField("Subject No.");
        TestField("Week Start");
        TestField("Plan Hash");
        if Date2DWY("Week Start", 1) <> 1 then
            Error(WeekStartNotMondayErr, "Week Start");
    end;

    /// <summary>
    /// A review's findings and changes are about its subject-week (their days, resource and project
    /// were checked against it), so once it has any, its subject and week can't change.
    /// </summary>
    local procedure CheckSubjectWeekUnchanged()
    var
        StoredReview: Record "Thyme Plan Review";
        ReviewLine: Record "Thyme Plan Review Line";
        ReviewChange: Record "Thyme Plan Review Change";
    begin
        // Lock the stored review (held until commit) before looking for findings and changes:
        // adding one locks the review too, so the two can't interleave.
        StoredReview.ReadIsolation := IsolationLevel::UpdLock;
        if not StoredReview.Get("Entry No.") then
            exit;
        if (StoredReview."Subject Type" = "Subject Type") and (StoredReview."Subject No." = "Subject No.") and
           (StoredReview."Week Start" = "Week Start")
        then
            exit;
        ReviewLine.SetRange("Review Entry No.", "Entry No.");
        ReviewChange.SetRange("Review Entry No.", "Entry No.");
        // Read committed, so another session's uncommitted delete doesn't hide a finding or change.
        ReviewLine.ReadIsolation := IsolationLevel::ReadCommitted;
        ReviewChange.ReadIsolation := IsolationLevel::ReadCommitted;
        if not ReviewLine.IsEmpty() or not ReviewChange.IsEmpty() then
            Error(SubjectWeekLockedErr, "Entry No.");
    end;

    var
        RenameNotAllowedErr: Label 'A plan review''s entry number can''t be changed. Delete the review and write a new one instead.';
        SubjectWeekLockedErr: Label 'Plan review %1 already has findings or changes, so its subject and week can''t change. Write a new review instead.', Comment = '%1 = review entry number';
        WeekStartNotMondayErr: Label 'The week must start on a Monday; %1 isn''t one.', Comment = '%1 = week start date';
}
