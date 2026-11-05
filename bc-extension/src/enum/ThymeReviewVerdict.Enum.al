/// <summary>
/// Overall outcome of an AI timesheet review.
/// Value names deliberately have no spaces so the API exposes them unchanged
/// ("Approve", "Check", "Query").
/// </summary>
enum 50100 "Thyme Review Verdict"
{
    Extensible = false;
    Caption = 'Thyme Review Verdict';

    /// <summary>Nothing unusual found; the time sheet looks ready to approve.</summary>
    value(0; Approve)
    {
        Caption = 'Approve';
    }
    /// <summary>Something is worth a human look before approving.</summary>
    value(1; Check)
    {
        Caption = 'Check';
    }
    /// <summary>Something needs querying with the time sheet owner.</summary>
    value(2; Query)
    {
        Caption = 'Query';
    }
}
