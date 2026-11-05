/// <summary>
/// Changes a project's Sell-to customer and keeps its Bill-to customer, for the projects API.
///
/// In Business Central, validating a project's Sell-to Customer No. also validates its Bill-to
/// Customer No. (setting it to the new customer's Bill-to Customer, or the customer itself). That
/// copies the new Bill-to customer's contact, payment terms, price groups and default dimensions
/// onto the project and re-prices its planning lines; setting the Bill-to back afterwards repeats it
/// all. Prices set by hand on planning lines and the project's own default dimensions are lost on
/// the way. When the project already has a Bill-to customer, SetSellToCustomer skips that Bill-to
/// validation, so only the Sell-to fields change. BC's own Sell-to validation still runs, with its
/// checks: e.g. it's refused once the project has invoiced (Sale) ledger entries. A project without
/// a Bill-to customer gets one from the Sell-to customer, as in BC, and clearing the Sell-to customer
/// is left to BC too (it clears the Bill-to customer as well), as a project with a Bill-to but no
/// Sell-to customer can't be invoiced.
///
/// While BC's Sell-to validation runs, the Bill-to Customer No. briefly holds the value BC would have
/// set (only the number: the validation that would copy the rest is skipped), so a subscriber to
/// OnAfterSellToCustomerNoUpdated sees it; it's set back before SetSellToCustomer returns.
///
/// The subscriber only runs while SetSellToCustomer has it bound (EventSubscriberInstance = Manual),
/// so Business Central's own pages and other code are unaffected.
/// </summary>
codeunit 50109 "Thyme Project Customer"
{
    EventSubscriberInstance = Manual;

    /// <summary>
    /// Sets the project's Sell-to customer (not saved), keeping any Bill-to customer. Clearing it
    /// is BC's own validation, which clears the Bill-to customer too.
    /// </summary>
    procedure SetSellToCustomer(var Job: Record Job; SellToCustomerNo: Code[20])
    var
        KeepBillTo: Codeunit "Thyme Project Customer";
        BillToCustomerNo: Code[20];
    begin
        if Job."Sell-to Customer No." = SellToCustomerNo then
            exit;
        BillToCustomerNo := Job."Bill-to Customer No.";
        if (BillToCustomerNo = '') or (SellToCustomerNo = '') then begin
            Job.Validate("Sell-to Customer No.", SellToCustomerNo);
            exit;
        end;
        BindSubscription(KeepBillTo);
        Job.Validate("Sell-to Customer No.", SellToCustomerNo);
        UnbindSubscription(KeepBillTo);
        // Its validation was skipped, so only the number had changed
        Job."Bill-to Customer No." := BillToCustomerNo;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeValidateBillToCustomerNo', '', false, false)]
    local procedure SkipBillToValidation(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
