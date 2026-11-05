/// <summary>
/// Lifecycle of an AI time-entry suggestion: written as Pending by the agent, then
/// Accepted (turned into a time sheet entry) or Dismissed by the user in Thyme.
/// </summary>
enum 50104 "Thyme Suggestion Status"
{
    Extensible = false;
    Caption = 'Thyme Suggestion Status';

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Accepted)
    {
        Caption = 'Accepted';
    }
    value(2; Dismissed)
    {
        Caption = 'Dismissed';
    }
}
