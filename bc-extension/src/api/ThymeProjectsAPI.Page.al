/// <summary>
/// Custom API page exposing Projects (Jobs) with additional fields
/// not available in the standard BC API v2.0.
///
/// sellToCustomerNo / sellToCustomerName are the customer the project's work is for, and
/// billToCustomerNo / billToCustomerName the customer who pays for it. They differ when the work is
/// sold through a partner: Sell-to is the end client and Bill-to the partner. These are Business
/// Central's own Project fields. Changing sellToCustomerNo keeps the project's Bill-to customer and
/// everything that comes with it (contact, payment terms, default dimensions, planning line prices),
/// where BC's own validation would set the Bill-to customer too (see codeunit "Thyme Project
/// Customer"). BC's Sell-to checks still apply: it's refused once the project has invoiced (Sale)
/// ledger entries. A project without a Bill-to customer gets the Sell-to customer as Bill-to, as in
/// BC. Send billToCustomerNo only to change the Bill-to customer: BC then applies that customer's
/// terms and re-prices the planning lines, even when it's the same customer.
///
/// canEditSourceLinks is true when the caller may add, change and remove the project's linked
/// sources (see the projectSourceLinks endpoint): a Thyme administrator or the project's manager.
///
/// canEditPlan is true when the caller may change the plan (the project's resource planning lines
/// and what goes with them): a user with permission to write Job Planning Lines. Per caller, the
/// same on every row.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/projects
/// </summary>
page 50100 "Thyme Projects API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'project';
    EntitySetName = 'projects';
    PageType = API;
    SourceTable = Job;
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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(displayName; Rec.Description)
                {
                    Caption = 'Display Name';
                }
                // Keeps the Bill-to customer (see "Thyme Project Customer"). Before the Bill-to
                // fields, so a PATCH with both sets Sell-to first, then the Bill-to that was sent.
                field(sellToCustomerNo; SellToCustomerNo)
                {
                    Caption = 'Sell-to Customer No.';
                    TableRelation = Customer;

                    trigger OnValidate()
                    var
                        ProjectCustomer: Codeunit "Thyme Project Customer";
                    begin
                        ProjectCustomer.SetSellToCustomer(Rec, SellToCustomerNo);
                    end;
                }
                // Read-only: the customer's current name (see header). Set sellToCustomerNo instead.
                field(sellToCustomerName; SellToCustomerName)
                {
                    Caption = 'Sell-to Customer Name';
                    Editable = false;
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                }
                field(billToCustomerName; Rec."Bill-to Name")
                {
                    Caption = 'Bill-to Customer Name';
                }
                field(personResponsible; Rec."Person Responsible")
                {
                    Caption = 'Person Responsible';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                }
                // Currency of the project's prices (Job Planning Lines and Job Ledger Entries).
                // Blank means the company's local currency (LCY). Read-only: changing it in BC
                // re-prices the planning lines, so it isn't something to PATCH through the API.
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                    Editable = false;
                }
                field(canEditSourceLinks; CanEditSourceLinks)
                {
                    Caption = 'Can Edit Source Links';
                    Editable = false;
                }
                // Whether the caller may change the plan. Per caller; read-only.
                field(canEditPlan; CanEditPlan)
                {
                    Caption = 'Can Edit Plan';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    var
        CallerIsThymeAdmin: Boolean;
        CanEditSourceLinks: Boolean;
        CanEditPlan: Boolean;
        SellToCustomerNo: Code[20];
        SellToCustomerName: Text[100];

    trigger OnOpenPage()
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        CallerIsThymeAdmin := RecordSecurity.IsThymeAdmin();
        CanEditPlan := RecordSecurity.CanEditPlan();
    end;

    trigger OnAfterGetRecord()
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        CanEditSourceLinks := RecordSecurity.CanEditProjectSourceLinks(Rec, CallerIsThymeAdmin);
        SetSellToCustomer();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SellToCustomerNo := '';
        SellToCustomerName := '';
    end;

    // BC can set the Sell-to customer itself (e.g. from a new Bill-to customer when there's none),
    // so return what's on the record, not what was sent
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SetSellToCustomer();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        SetSellToCustomer();
        exit(true);
    end;

    local procedure SetSellToCustomer()
    var
        Customer: Record Customer;
    begin
        SellToCustomerNo := Rec."Sell-to Customer No.";
        SellToCustomerName := Rec."Sell-to Customer Name";
        // Callers who can't read customers keep the stored name rather than getting an error
        if (SellToCustomerNo = '') or not Customer.ReadPermission() then
            exit;
        Customer.SetLoadFields(Name);
        if Customer.Get(SellToCustomerNo) then
            SellToCustomerName := Customer.Name;
    end;
}
