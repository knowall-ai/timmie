/// <summary>
/// Severity of a single finding within an AI timesheet review.
/// Value names deliberately have no spaces so the API exposes them unchanged
/// ("Info", "Warning", "Issue").
/// </summary>
enum 50101 "Thyme Review Severity"
{
    Extensible = false;
    Caption = 'Thyme Review Severity';

    value(0; Info)
    {
        Caption = 'Info';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Issue)
    {
        Caption = 'Issue';
    }
}
