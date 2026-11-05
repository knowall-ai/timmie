/// <summary>
/// A single finding within an AI timesheet review. "Time Sheet Line No." = 0 means
/// the finding applies to the whole time sheet rather than one line.
/// </summary>
table 50101 "Thyme Timesheet Review Line"
{
    Caption = 'Thyme Timesheet Review Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Review Entry No."; Integer)
        {
            Caption = 'Review Entry No.';
            TableRelation = "Thyme Timesheet Review"."Entry No.";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(4; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            MinValue = 0;
        }
        field(5; Severity; Enum "Thyme Review Severity")
        {
            Caption = 'Severity';
        }
        field(6; Note; Text[500])
        {
            Caption = 'Note';
        }
        // Used by "Thyme Record Security" to show a finding only to the reviewed time sheet's
        // owner and approver. AL filters can't OR two fields, so the check is inverted:
        // with "User ID Filter" set to <>(current user), "Hidden From User Filter" is true
        // when the time sheet's owner AND approver are both someone else.
        field(7; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(8; "Hidden From User Filter"; Boolean)
        {
            Caption = 'Hidden From User Filter';
            FieldClass = FlowField;
            CalcFormula = exist("Time Sheet Header" where("No." = field("Time Sheet No."),
                                                          "Owner User ID" = field("User ID Filter"),
                                                          "Approver User ID" = field("User ID Filter")));
            Editable = false;
        }
        field(9; "Time Sheet Exists"; Boolean)
        {
            Caption = 'Time Sheet Exists';
            FieldClass = FlowField;
            CalcFormula = exist("Time Sheet Header" where("No." = field("Time Sheet No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Review Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(TimeSheetLine; "Time Sheet No.", "Time Sheet Line No.")
        {
        }
    }

    trigger OnInsert()
    var
        ReviewLine: Record "Thyme Timesheet Review Line";
    begin
        SyncTimeSheetNoFromReview();

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
        SyncTimeSheetNoFromReview();
    end;

    /// <summary>
    /// Fills the time sheet number from the parent review when it is blank, and rejects
    /// a finding that points at a different time sheet than its review.
    /// </summary>
    local procedure SyncTimeSheetNoFromReview()
    var
        Review: Record "Thyme Timesheet Review";
    begin
        TestField("Review Entry No.");
        if not Review.Get("Review Entry No.") then
            Error(ReviewNotFoundErr, "Review Entry No.");

        if "Time Sheet No." = '' then
            "Time Sheet No." := Review."Time Sheet No."
        else
            if "Time Sheet No." <> Review."Time Sheet No." then
                Error(TimeSheetMismatchErr, "Time Sheet No.", Review."Time Sheet No.", "Review Entry No.");
    end;

    var
        ReviewNotFoundErr: Label 'Timesheet review %1 does not exist.', Comment = '%1 = review entry number';
        TimeSheetMismatchErr: Label 'Time sheet %1 does not match time sheet %2 on review %3.', Comment = '%1 = time sheet number on the finding, %2 = time sheet number on the review, %3 = review entry number';
}
