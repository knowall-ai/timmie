/// <summary>
/// How confident the agent is in an AI time-entry suggestion.
/// </summary>
enum 50103 "Thyme Suggestion Confidence"
{
    Extensible = false;
    Caption = 'Thyme Suggestion Confidence';

    value(0; High)
    {
        Caption = 'High';
    }
    value(1; Medium)
    {
        Caption = 'Medium';
    }
    value(2; Low)
    {
        Caption = 'Low';
    }
}
