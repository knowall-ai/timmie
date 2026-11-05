/// <summary>
/// Custom API page exposing Job Planning Lines for budget data.
/// Supports reading, creating, and updating planning lines with upsert logic.
/// Enables Thyme to show budget vs actual comparisons and create resource allocations.
/// Use with Resource Units of Measure API to convert quantities to hours.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/jobPlanningLines
///
/// POST to create/update planning lines (upsert behavior):
/// - If a line exists for the same jobNo + jobTaskNo + planningDate + number, quantity is updated
/// - Otherwise a new line is created
/// Required fields: jobNo, jobTaskNo, planningDate, number, quantity
/// Optional: type (defaults to Resource), lineType (defaults to Budget)
/// lineNo is auto-generated in increments of 10000.
/// </summary>
page 50107 "Thyme Job Planning Lines API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'jobPlanningLine';
    EntitySetName = 'jobPlanningLines';
    PageType = API;
    SourceTable = "Job Planning Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';

                    trigger OnValidate()
                    begin
                        // BC only copies the project's currency onto a planning line in OnInsert,
                        // after the API has already priced the line, so a line on a project in
                        // another currency would hold local-currency amounts labelled with the
                        // project currency. jobNo is the first field applied, so setting the
                        // currency here prices the rest of the line in the project currency.
                        SetCurrencyFromJob();
                    end;
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(planningDate; Rec."Planning Date")
                {
                    Caption = 'Planning Date';
                }
                field(lineType; Rec."Line Type")
                {
                    Caption = 'Line Type';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(totalCost; Rec."Total Cost")
                {
                    Caption = 'Total Cost';
                }
                field(totalPrice; Rec."Total Price")
                {
                    Caption = 'Total Price';
                }
                // The cost and price fields above are in the project's currency (currencyCode;
                // blank = LCY). These are the same amounts in the company's local currency, for
                // internal cost reporting. All read-only: BC calculates them from the line.
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                    Editable = false;
                }
                field(unitCostLCY; Rec."Unit Cost (LCY)")
                {
                    Caption = 'Unit Cost (LCY)';
                    Editable = false;
                }
                field(totalCostLCY; Rec."Total Cost (LCY)")
                {
                    Caption = 'Total Cost (LCY)';
                    Editable = false;
                }
                field(unitPriceLCY; Rec."Unit Price (LCY)")
                {
                    Caption = 'Unit Price (LCY)';
                    Editable = false;
                }
                field(totalPriceLCY; Rec."Total Price (LCY)")
                {
                    Caption = 'Total Price (LCY)';
                    Editable = false;
                }
                field(workTypeCode; Rec."Work Type Code")
                {
                    Caption = 'Work Type Code';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    /// <summary>
    /// Takes an update lock on the line's project (held until commit), the same lock a plan review's
    /// applyChanges takes, so the two writers change a project's plan one at a time.
    /// </summary>
    local procedure LockProject()
    var
        Job: Record Job;
    begin
        Job.ReadIsolation := IsolationLevel::UpdLock;
        if Job.Get(Rec."Job No.") then;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        LockProject();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        LockProject();
        exit(true);
    end;

    local procedure SetCurrencyFromJob()
    var
        Job: Record Job;
    begin
        if not Job.Get(Rec."Job No.") then
            exit;
        if Rec."Currency Code" = Job."Currency Code" then
            exit;
        Rec."Currency Code" := Job."Currency Code";
        Rec.UpdateCurrencyFactor();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ExistingLine: Record "Job Planning Line";
        JobPlanningLine: Record "Job Planning Line";
        NextLineNo: Integer;
    begin
        LockProject();
        // Upsert logic: Check if a line already exists for the same job/task/date/resource/type
        // Lock the table to prevent race conditions with concurrent inserts
        ExistingLine.LockTable();
        ExistingLine.SetRange("Job No.", Rec."Job No.");
        ExistingLine.SetRange("Job Task No.", Rec."Job Task No.");
        ExistingLine.SetRange("Planning Date", Rec."Planning Date");
        ExistingLine.SetRange(Type, Rec.Type);
        ExistingLine.SetRange("No.", Rec."No.");

        if ExistingLine.FindFirst() then begin
            // Update existing line instead of creating duplicate
            ExistingLine.Validate(Quantity, Rec.Quantity);
            ExistingLine.Modify(true);
            // Copy the existing record back to Rec so the API returns the updated record
            Rec := ExistingLine;
            exit(false); // Don't do default insert
        end;

        // No existing line found - create new one
        // Auto-assign Line No. if not provided or is 0
        if Rec."Line No." = 0 then begin
            JobPlanningLine.SetRange("Job No.", Rec."Job No.");
            JobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
            if JobPlanningLine.FindLast() then
                NextLineNo := JobPlanningLine."Line No." + 10000
            else
                NextLineNo := 10000;
            Rec."Line No." := NextLineNo;
        end;

        // Type defaults to Resource (enum value 0) - appropriate for time/resource planning
        // Line Type defaults to Budget (enum value 0) - appropriate for planning

        exit(true); // Continue with default insert
    end;
}
