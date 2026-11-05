/// <summary>
/// Custom API page exposing Resource Units of Measure conversion factors.
/// Used to convert quantities from units like DAY to base unit HOUR.
///
/// Example: resourceNo="EMP001", code="DAY", qtyPerUnitOfMeasure=8
/// means 1 DAY = 8 HOURs for that resource.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/resourceUnitsOfMeasure
/// </summary>
page 50108 "Thyme Resource UoM API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'resourceUnitOfMeasure';
    EntitySetName = 'resourceUnitsOfMeasure';
    PageType = API;
    SourceTable = "Resource Unit of Measure";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    DeleteAllowed = false;

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
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure")
                {
                    Caption = 'Qty. per Unit of Measure';
                }
                field(relatedToBaseUnitOfMeasure; Rec."Related to Base Unit of Meas.")
                {
                    Caption = 'Related to Base Unit of Measure';
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
    /// Validates a conversion factor created through the API. Going through Validate
    /// rather than a plain assignment means the table's own checks still run, so an
    /// unknown resource or unit code is rejected rather than stored.
    /// </summary>
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Resource: Record Resource;
    begin
        Rec.TestField("Resource No.");
        Rec.TestField(Code);

        // Checked up front so an unknown resource gives a clear message rather than
        // surfacing as a table relation violation from deeper in the insert.
        if not Resource.Get(Rec."Resource No.") then
            Error(ResourceNotFoundErr, Rec."Resource No.");

        if Rec."Qty. per Unit of Measure" <= 0 then
            Error(QtyPerUnitOfMeasureErr);

        Rec.Validate("Resource No.");
        Rec.Validate(Code);
        Rec.Validate("Qty. per Unit of Measure");
        exit(true);
    end;

    /// <summary>
    /// Revalidates on PATCH. Resource No. and Code stay editable so a factor can be
    /// corrected in place, which means both need validating here too - otherwise a
    /// PATCH would slip past the table checks the insert path deliberately runs.
    /// </summary>
    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Qty. per Unit of Measure" <= 0 then
            Error(QtyPerUnitOfMeasureErr);

        Rec.Validate("Resource No.");
        Rec.Validate(Code);
        Rec.Validate("Qty. per Unit of Measure");
        exit(true);
    end;

    var
        QtyPerUnitOfMeasureErr: Label 'Qty. per Unit of Measure must be greater than zero.';
        ResourceNotFoundErr: Label 'Resource %1 does not exist.', Comment = '%1 = resource number';
}
