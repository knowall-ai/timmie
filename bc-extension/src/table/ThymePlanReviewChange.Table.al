/// <summary>
/// A change an AI plan review proposes to one planning-line cell (project, task, resource and
/// day), in hours. A finding's changes are applied together, by a user who may change the plan,
/// with Thyme's "Apply change"; Thyme refuses to apply one if the cell no longer holds
/// "Current Hours". "Proposed Hours" = 0 means remove the cell's planning line(s).
///
/// A change stays inside the review's subject-week: its day is in the week, and it is for the
/// review's resource (resource-week) or project (project-week).
/// </summary>
table 50109 "Thyme Plan Review Change"
{
    Caption = 'Thyme Plan Review Change';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Review Entry No."; Integer)
        {
            Caption = 'Review Entry No.';
            TableRelation = "Thyme Plan Review"."Entry No.";
            NotBlank = true;
        }
        // The finding the change belongs to.
        field(2; "Review Line No."; Integer)
        {
            Caption = 'Review Line No.';
            TableRelation = "Thyme Plan Review Line"."Line No." where("Review Entry No." = field("Review Entry No."));
            NotBlank = true;
        }
        field(3; "Change No."; Integer)
        {
            Caption = 'Change No.';
        }
        field(4; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
            NotBlank = true;
        }
        field(5; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            NotBlank = true;
        }
        field(6; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
            NotBlank = true;
        }
        field(7; "Planning Date"; Date)
        {
            Caption = 'Planning Date';
            NotBlank = true;
        }
        // Hours (not the resource's base unit) in the cell when the agent looked.
        field(8; "Current Hours"; Decimal)
        {
            Caption = 'Current Hours';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        // Hours the cell should hold: a multiple of 0.25; 0 = remove the cell's planning line(s).
        field(9; "Proposed Hours"; Decimal)
        {
            Caption = 'Proposed Hours';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Review Entry No.", "Review Line No.", "Change No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        ReviewChange: Record "Thyme Plan Review Change";
    begin
        CheckChange();

        // Callers may omit changeNo; number a finding's changes 1, 2, 3...
        if "Change No." = 0 then begin
            ReviewChange.SetRange("Review Entry No.", "Review Entry No.");
            ReviewChange.SetRange("Review Line No.", "Review Line No.");
            if ReviewChange.FindLast() then
                "Change No." := ReviewChange."Change No." + 1
            else
                "Change No." := 1;
        end;
    end;

    trigger OnModify()
    begin
        CheckChange();
    end;

    /// <summary>
    /// Changing the key (a PATCH of a key field) would move the row without the OnModify checks,
    /// so it is refused: delete it and create a new one instead.
    /// </summary>
    trigger OnRename()
    begin
        Error(RenameNotAllowedErr);
    end;

    local procedure CheckChange()
    var
        Review: Record "Thyme Plan Review";
        ReviewLine: Record "Thyme Plan Review Line";
    begin
        TestField("Review Entry No.");
        TestField("Review Line No.");
        TestField("Job No.");
        TestField("Job Task No.");
        TestField("Resource No.");
        TestField("Planning Date");
        // Lock the review and the finding (held until commit) so neither can change subject-week or
        // be deleted between these checks and the commit.
        Review.ReadIsolation := IsolationLevel::UpdLock;
        if not Review.Get("Review Entry No.") then
            Error(ReviewNotFoundErr, "Review Entry No.");
        ReviewLine.ReadIsolation := IsolationLevel::UpdLock;
        if not ReviewLine.Get("Review Entry No.", "Review Line No.") then
            Error(ReviewLineNotFoundErr, "Review Entry No.", "Review Line No.");

        // Hours on the Plan grid are in quarter hours (also guards against negatives, which
        // MinValue only enforces on pages).
        if ("Current Hours" < 0) or ("Proposed Hours" < 0) then
            Error(NegativeHoursErr);
        if "Proposed Hours" mod 0.25 <> 0 then
            Error(NotQuarterHoursErr, "Proposed Hours");

        if ("Planning Date" < Review."Week Start") or ("Planning Date" > Review."Week Start" + 6) then
            Error(DateOutsideWeekErr, "Planning Date", Review."Week Start", "Review Entry No.");
        case Review."Subject Type" of
            Review."Subject Type"::Resource:
                if "Resource No." <> Review."Subject No." then
                    Error(OtherResourceErr, "Resource No.", Review."Subject No.", "Review Entry No.");
            Review."Subject Type"::Project:
                if "Job No." <> Review."Subject No." then
                    Error(OtherProjectErr, "Job No.", Review."Subject No.", "Review Entry No.");
        end;
    end;

    var
        RenameNotAllowedErr: Label 'A proposed change''s review entry, finding and change numbers can''t be changed. Delete the change and create a new one instead.';
        ReviewNotFoundErr: Label 'Plan review %1 does not exist.', Comment = '%1 = review entry number';
        ReviewLineNotFoundErr: Label 'Plan review %1 has no finding %2.', Comment = '%1 = review entry number, %2 = review line number';
        NegativeHoursErr: Label 'Current and proposed hours can''t be negative.';
        NotQuarterHoursErr: Label 'Proposed hours must be a multiple of 0.25 (%1 isn''t).', Comment = '%1 = proposed hours';
        DateOutsideWeekErr: Label '%1 isn''t in the week starting %2 that plan review %3 covers.', Comment = '%1 = planning date, %2 = week start date, %3 = review entry number';
        OtherResourceErr: Label 'A change to resource %1 can''t be part of plan review %3, which covers resource %2.', Comment = '%1 = resource number on the change, %2 = resource number reviewed, %3 = review entry number';
        OtherProjectErr: Label 'A change to project %1 can''t be part of plan review %3, which covers project %2.', Comment = '%1 = job number on the change, %2 = job number reviewed, %3 = review entry number';
}
