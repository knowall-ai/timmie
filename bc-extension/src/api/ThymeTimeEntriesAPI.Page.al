/// <summary>
/// Custom API page exposing Job Ledger Entries for reading posted time entries.
/// Filtered to Resource-type entries only (time tracked by employees).
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/timeEntries
/// </summary>
page 50105 "Thyme Time Entries API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'timeEntry';
    EntitySetName = 'timeEntries';
    PageType = API;
    SourceTable = "Job Ledger Entry";
    SourceTableView = where(Type = const(Resource));
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
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
                field(unitCost; Rec."Unit Cost (LCY)")
                {
                    Caption = 'Unit Cost';
                }
                field(totalCost; Rec."Total Cost (LCY)")
                {
                    Caption = 'Total Cost';
                }
                field(unitPrice; Rec."Unit Price (LCY)")
                {
                    Caption = 'Unit Price';
                }
                field(totalPrice; Rec."Total Price (LCY)")
                {
                    Caption = 'Total Price';
                }
                // The fields above are in the company's local currency (LCY). These are in the
                // project's currency (currencyCode; blank = LCY), matching the amounts on the
                // project's planning lines, so prices can be compared like with like.
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(unitCostProjectCurrency; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost (Project Currency)';
                }
                field(totalCostProjectCurrency; Rec."Total Cost")
                {
                    Caption = 'Total Cost (Project Currency)';
                }
                field(unitPriceProjectCurrency; Rec."Unit Price")
                {
                    Caption = 'Unit Price (Project Currency)';
                }
                field(totalPriceProjectCurrency; Rec."Total Price")
                {
                    Caption = 'Total Price (Project Currency)';
                }
                field(workTypeCode; Rec."Work Type Code")
                {
                    Caption = 'Work Type Code';
                }
                field(entryType; Rec."Entry Type")
                {
                    Caption = 'Entry Type';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                }
            }
        }
    }
}
