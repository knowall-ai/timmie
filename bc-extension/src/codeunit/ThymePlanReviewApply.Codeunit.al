/// <summary>
/// Applies a plan review finding's proposed changes to the plan (Resource Job Planning Lines) in
/// one transaction: Thyme's "Apply change", through the planReviewLines API's applyChanges action.
///
/// Only a user who may change the plan (Thyme Record Security's CanEditPlan: permission to write
/// Job Planning Lines) can apply. The review, the finding, its changes and each affected project
/// are locked, and the changes are read once into a snapshot that everything below works from.
/// A finding that changes the same cell twice is refused. Every cell is checked before anything is
/// written: it must be empty or hold exactly one Budget line in the resource's base unit, and its
/// hours must still be the change's Current Hours. Each cell is checked again immediately before
/// it is written. Then each cell gets its Proposed Hours (0 deletes the line; an empty cell gets a
/// new Budget line), and the finding is stamped Applied At / Applied By. Any error rolls all of it
/// back.
///
/// Hours follow Thyme's rule: if the resource has an HOUR unit of measure whose factor isn't 1,
/// the base unit is a day of (factor, or 1 / factor when below 1) hours; otherwise it's an hour.
///
/// The Permissions property gives the indirect rights this needs (writing planning lines, stamping
/// the finding); THYME USER grants the matching indirect modify on findings, and CanEditPlan gates
/// the planning-line writes, so only people who may change the plan succeed.
/// </summary>
codeunit 50107 "Thyme Plan Review Apply"
{
    Permissions = tabledata "Job Planning Line" = rimd,
                  tabledata Resource = r,
                  tabledata "Thyme Plan Review" = r,
                  tabledata "Thyme Plan Review Line" = rm,
                  tabledata "Thyme Plan Review Change" = r,
                  tabledata "Resource Unit of Measure" = r,
                  tabledata Job = r;

    var
        NotAllowedToChangePlanErr: Label 'You don''t have permission to change the plan.';
        NoChangesErr: Label 'Finding %2 of plan review %1 has no changes to apply.', Comment = '%1 = review entry number, %2 = finding line number';
        SameCellTwiceErr: Label 'Edit this cell by hand: the finding changes the same cell twice.';
        SeveralLinesErr: Label 'Edit this cell by hand: %1 has %2 planning lines on %3 for project %4, task %5.', Comment = '%1 = resource number, %2 = number of lines, %3 = planning date, %4 = job number, %5 = job task number';
        NotBudgetLineErr: Label 'Edit this cell by hand: the planning line for %1 on %2 for project %3, task %4 is a %5 line, not a Budget line.', Comment = '%1 = resource number, %2 = planning date, %3 = job number, %4 = job task number, %5 = line type';
        OtherUnitErr: Label 'Edit this cell by hand: the planning line for %1 on %2 for project %3, task %4 uses unit %5.', Comment = '%1 = resource number, %2 = planning date, %3 = job number, %4 = job task number, %5 = unit of measure code';
        PlanChangedErr: Label 'The plan changed since Poppie looked. Ask her to re-review.';
        HourUoMTok: Label 'HOUR', Locked = true;

    /// <summary>
    /// Applies all of the finding's changes, or none of them (an error rolls back the lot).
    /// </summary>
    procedure ApplyChanges(var ReviewLine: Record "Thyme Plan Review Line")
    var
        Review: Record "Thyme Plan Review";
        StoredLine: Record "Thyme Plan Review Line";
        TempChange: Record "Thyme Plan Review Change" temporary;
        JobPlanningLine: Record "Job Planning Line";
        CellLine: Record "Job Planning Line";
        RecordSecurity: Codeunit "Thyme Record Security";
        CellFound: Boolean;
    begin
        RecordSecurity.CheckCanEditPlan(NotAllowedToChangePlanErr);

        // Lock the review and the finding (held until commit) so neither changes underneath us.
        Review.ReadIsolation := IsolationLevel::UpdLock;
        Review.Get(ReviewLine."Review Entry No.");
        StoredLine.ReadIsolation := IsolationLevel::UpdLock;
        StoredLine.Get(ReviewLine."Review Entry No.", ReviewLine."Line No.");

        ReadChanges(StoredLine, TempChange);
        LockProjects(TempChange);
        // Hold the planning lines until commit, so the cells can't change between check and write.
        JobPlanningLine.LockTable();

        // Check every cell first; write only once they all pass.
        TempChange.FindSet();
        repeat
            CheckCell(TempChange, false, CellLine, CellFound);
        until TempChange.Next() = 0;

        TempChange.FindSet();
        repeat
            // Check again right before writing: anything different now means the plan changed.
            // The write then goes to exactly the line this check found (or a new one).
            CheckCell(TempChange, true, CellLine, CellFound);
            ApplyCell(TempChange, CellLine, CellFound);
        until TempChange.Next() = 0;

        StoredLine."Applied At" := CurrentDateTime();
        StoredLine."Applied By" := CopyStr(UpperCase(UserId()), 1, MaxStrLen(StoredLine."Applied By"));
        StoredLine.Modify(true);
        ReviewLine := StoredLine;
    end;

    /// <summary>
    /// Reads the finding's changes once, with an update lock, into the snapshot used from here on,
    /// refusing a finding with none or with two changes to the same cell.
    /// </summary>
    local procedure ReadChanges(StoredLine: Record "Thyme Plan Review Line"; var TempChange: Record "Thyme Plan Review Change" temporary)
    var
        ReviewChange: Record "Thyme Plan Review Change";
    begin
        ReviewChange.ReadIsolation := IsolationLevel::UpdLock;
        ReviewChange.SetRange("Review Entry No.", StoredLine."Review Entry No.");
        ReviewChange.SetRange("Review Line No.", StoredLine."Line No.");
        if not ReviewChange.FindSet() then
            Error(NoChangesErr, StoredLine."Review Entry No.", StoredLine."Line No.");
        repeat
            TempChange.Reset();
            TempChange.SetRange("Job No.", ReviewChange."Job No.");
            TempChange.SetRange("Job Task No.", ReviewChange."Job Task No.");
            TempChange.SetRange("Resource No.", ReviewChange."Resource No.");
            TempChange.SetRange("Planning Date", ReviewChange."Planning Date");
            if not TempChange.IsEmpty() then
                Error(SameCellTwiceErr);
            TempChange := ReviewChange;
            TempChange.Insert();
        until ReviewChange.Next() = 0;
        TempChange.Reset();
    end;

    /// <summary>
    /// Takes an update lock on each affected project (in project order, to avoid deadlocks), so
    /// plan-review applies on the same project run one at a time.
    /// </summary>
    local procedure LockProjects(var TempChange: Record "Thyme Plan Review Change" temporary)
    var
        TempJob: Record Job temporary;
        Job: Record Job;
    begin
        TempChange.FindSet();
        repeat
            if not TempJob.Get(TempChange."Job No.") then begin
                TempJob.Init();
                TempJob."No." := TempChange."Job No.";
                TempJob.Insert();
            end;
        until TempChange.Next() = 0;
        TempJob.FindSet();
        repeat
            Job.ReadIsolation := IsolationLevel::UpdLock;
            if Job.Get(TempJob."No.") then;
        until TempJob.Next() = 0;
    end;

    /// <summary>
    /// The cell must be empty or hold one Budget line in the resource's base unit, and hold the
    /// change's Current Hours. On the re-check before writing (Recheck), any difference is reported
    /// as the plan having changed.
    /// </summary>
    local procedure CheckCell(TempChange: Record "Thyme Plan Review Change" temporary; Recheck: Boolean; var CellLine: Record "Job Planning Line"; var CellFound: Boolean)
    var
        CellHours: Decimal;
        LineCount: Integer;
    begin
        Clear(CellLine);
        CellFound := false;
        FilterCell(CellLine, TempChange);
        LineCount := CellLine.Count();
        if LineCount > 1 then
            FailCell(Recheck, StrSubstNo(SeveralLinesErr, TempChange."Resource No.", LineCount, TempChange."Planning Date", TempChange."Job No.", TempChange."Job Task No."));
        if LineCount = 1 then begin
            CellLine.FindFirst();
            if CellLine."Line Type" <> CellLine."Line Type"::Budget then
                FailCell(Recheck, StrSubstNo(NotBudgetLineErr, TempChange."Resource No.", TempChange."Planning Date", TempChange."Job No.", TempChange."Job Task No.", CellLine."Line Type"));
            if not IsBaseUnit(CellLine) then
                FailCell(Recheck, StrSubstNo(OtherUnitErr, TempChange."Resource No.", TempChange."Planning Date", TempChange."Job No.", TempChange."Job Task No.", CellLine."Unit of Measure Code"));
            CellHours := CellLine.Quantity * HoursPerUnit(TempChange."Resource No.");
            CellFound := true;
        end;
        if Abs(CellHours - TempChange."Current Hours") >= 0.005 then
            Error(PlanChangedErr);
    end;

    local procedure FailCell(Recheck: Boolean; Reason: Text)
    begin
        if Recheck then
            Error(PlanChangedErr);
        Error(Reason);
    end;

    /// <summary>
    /// Writes the cell: to exactly the line the final check found (re-read by its key and checked
    /// unchanged), or a new line for an empty cell. Afterwards the cell must hold just the expected
    /// lines (one, or none for 0 hours); a line someone else added meanwhile means the plan changed,
    /// and the error rolls everything back.
    /// </summary>
    local procedure ApplyCell(TempChange: Record "Thyme Plan Review Change" temporary; CheckedLine: Record "Job Planning Line"; CellFound: Boolean)
    var
        CellLine: Record "Job Planning Line";
        NewQuantity: Decimal;
        ExpectedLines: Integer;
    begin
        NewQuantity := TempChange."Proposed Hours" / HoursPerUnit(TempChange."Resource No.");
        if TempChange."Proposed Hours" <> 0 then
            ExpectedLines := 1;
        if CellFound then begin
            if not CellLine.Get(CheckedLine."Job No.", CheckedLine."Job Task No.", CheckedLine."Line No.") then
                Error(PlanChangedErr);
            if (CellLine."Line Type" <> CellLine."Line Type"::Budget) or (CellLine.Quantity <> CheckedLine.Quantity) or
               (CellLine."Unit of Measure Code" <> CheckedLine."Unit of Measure Code") or (CellLine.Type <> CheckedLine.Type) or
               (CellLine."No." <> CheckedLine."No.") or (CellLine."Planning Date" <> CheckedLine."Planning Date")
            then
                Error(PlanChangedErr);
            if TempChange."Proposed Hours" = 0 then
                CellLine.Delete(true)
            else begin
                CellLine.Validate(Quantity, NewQuantity);
                CellLine.Modify(true);
            end;
        end else
            if TempChange."Proposed Hours" <> 0 then
                InsertCellLine(TempChange, NewQuantity);

        Clear(CellLine);
        FilterCell(CellLine, TempChange);
        if CellLine.Count() <> ExpectedLines then
            Error(PlanChangedErr);
    end;

    local procedure InsertCellLine(TempChange: Record "Thyme Plan Review Change" temporary; NewQuantity: Decimal)
    var
        NewLine: Record "Job Planning Line";
        LastLine: Record "Job Planning Line";
        Job: Record Job;
    begin
        LastLine.SetRange("Job No.", TempChange."Job No.");
        LastLine.SetRange("Job Task No.", TempChange."Job Task No.");
        NewLine.Init();
        NewLine."Job No." := TempChange."Job No.";
        NewLine."Job Task No." := TempChange."Job Task No.";
        if LastLine.FindLast() then
            NewLine."Line No." := LastLine."Line No." + 10000
        else
            NewLine."Line No." := 10000;
        // As the jobPlanningLines API does: BC only copies the project's currency onto a planning
        // line in OnInsert, after it is priced, so set it first to price the line in that currency.
        if Job.Get(TempChange."Job No.") then
            if NewLine."Currency Code" <> Job."Currency Code" then begin
                NewLine."Currency Code" := Job."Currency Code";
                NewLine.UpdateCurrencyFactor();
            end;
        NewLine.Validate("Line Type", NewLine."Line Type"::Budget);
        NewLine.Validate("Planning Date", TempChange."Planning Date");
        NewLine.Validate(Type, NewLine.Type::Resource);
        // Validating the resource sets the line's unit to the resource's base unit.
        NewLine.Validate("No.", TempChange."Resource No.");
        NewLine.Validate(Quantity, NewQuantity);
        NewLine.Insert(true);
    end;

    /// <summary>The cell's lines: this project task, resource and day, with a quantity.</summary>
    local procedure FilterCell(var CellLine: Record "Job Planning Line"; TempChange: Record "Thyme Plan Review Change" temporary)
    begin
        CellLine.SetRange("Job No.", TempChange."Job No.");
        CellLine.SetRange("Job Task No.", TempChange."Job Task No.");
        CellLine.SetRange(Type, CellLine.Type::Resource);
        CellLine.SetRange("No.", TempChange."Resource No.");
        CellLine.SetRange("Planning Date", TempChange."Planning Date");
        CellLine.SetFilter(Quantity, '<>0');
    end;

    /// <summary>
    /// True if the line's quantity is in the resource's base unit (or has no unit), the unit Thyme's
    /// Plan grid and the review's Current Hours assume. A line in another unit is left to a person.
    /// </summary>
    local procedure IsBaseUnit(CellLine: Record "Job Planning Line"): Boolean
    var
        Resource: Record Resource;
    begin
        if CellLine."Unit of Measure Code" = '' then
            exit(true);
        if not Resource.Get(CellLine."No.") then
            exit(false);
        exit(CellLine."Unit of Measure Code" = Resource."Base Unit of Measure");
    end;

    /// <summary>
    /// Hours in one base unit of the resource: the HOUR unit's factor (or its inverse when below 1)
    /// when it exists and isn't 1, i.e. the base unit is a day; otherwise 1 (the base unit is an hour).
    /// </summary>
    local procedure HoursPerUnit(ResourceNo: Code[20]): Decimal
    var
        ResourceUoM: Record "Resource Unit of Measure";
        Factor: Decimal;
    begin
        if not ResourceUoM.Get(ResourceNo, HourUoMTok) then
            exit(1);
        Factor := ResourceUoM."Qty. per Unit of Measure";
        if (Factor = 0) or (Factor = 1) then
            exit(1);
        if Factor > 1 then
            exit(Factor);
        exit(1 / Factor);
    end;
}
