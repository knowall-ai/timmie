/// <summary>
/// An AI review of a time sheet, written by the reviewing agent through the
/// timesheetReviews API and read by the Thyme web app.
///
/// "Version Stamp" records the latest lastModifiedDateTime across the time sheet's
/// lines and details at the moment it was reviewed, so a reader can tell whether
/// the time sheet has changed since (and the review is therefore stale).
/// </summary>
table 50100 "Thyme Timesheet Review"
{
    Caption = 'Thyme Timesheet Review';
    DataClassification = CustomerContent;

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
            NotBlank = true;
        }
        field(3; "Version Stamp"; DateTime)
        {
            Caption = 'Version Stamp';
        }
        field(4; Verdict; Enum "Thyme Review Verdict")
        {
            Caption = 'Verdict';
            // Default to the cautious outcome so a review posted without a verdict
            // never reads as an approval.
            InitValue = Check;
        }
        field(5; Summary; Text[2048])
        {
            Caption = 'Summary';
        }
        field(6; Reviewer; Text[100])
        {
            Caption = 'Reviewer';
        }
        field(7; "Reviewed At"; DateTime)
        {
            Caption = 'Reviewed At';
        }
        // Used by "Thyme Record Security" to show a review only to the reviewed time sheet's
        // owner and approver. AL filters can't OR two fields, so the check is inverted:
        // with "User ID Filter" set to <>(current user), "Hidden From User Filter" is true
        // when the time sheet's owner AND approver are both someone else.
        field(8; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Hidden From User Filter"; Boolean)
        {
            Caption = 'Hidden From User Filter';
            FieldClass = FlowField;
            CalcFormula = exist("Time Sheet Header" where("No." = field("Time Sheet No."),
                                                          "Owner User ID" = field("User ID Filter"),
                                                          "Approver User ID" = field("User ID Filter")));
            Editable = false;
        }
        field(10; "Time Sheet Exists"; Boolean)
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
        // Supports "latest review for a time sheet" queries:
        // $filter=timeSheetNo eq '...'&$orderby=reviewedAt desc&$top=1
        key(TimeSheetReviewedAt; "Time Sheet No.", "Reviewed At")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Time Sheet No.");
        TestField("Version Stamp");
        if "Reviewed At" = 0DT then
            "Reviewed At" := CurrentDateTime();
    end;

    /// <summary>
    /// If the review is moved to another time sheet, moves its findings with it so
    /// filtering review lines by time sheet stays correct.
    /// </summary>
    trigger OnModify()
    var
        StoredReview: Record "Thyme Timesheet Review";
        ReviewLine: Record "Thyme Timesheet Review Line";
    begin
        TestField("Time Sheet No.");
        TestField("Version Stamp");
        if StoredReview.Get("Entry No.") then
            if StoredReview."Time Sheet No." <> "Time Sheet No." then begin
                ReviewLine.SetRange("Review Entry No.", "Entry No.");
                ReviewLine.ModifyAll("Time Sheet No.", "Time Sheet No.", false);
            end;
    end;

    /// <summary>
    /// Deleting a review removes its findings too, so no orphaned lines are left behind.
    /// </summary>
    trigger OnDelete()
    var
        ReviewLine: Record "Thyme Timesheet Review Line";
    begin
        ReviewLine.SetRange("Review Entry No.", "Entry No.");
        if not ReviewLine.IsEmpty() then
            ReviewLine.DeleteAll(true);
    end;
}
