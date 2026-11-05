/// <summary>
/// Lifecycle of an on-demand request for AI time suggestions: created as Requested from
/// Thyme, claimed by the agent (Running), then Done or Failed.
/// </summary>
enum 50105 "Thyme Suggestion Request Status"
{
    Extensible = false;
    Caption = 'Thyme Suggestion Request Status';

    value(0; Requested)
    {
        Caption = 'Requested';
    }
    value(1; Running)
    {
        Caption = 'Running';
    }
    value(2; Done)
    {
        Caption = 'Done';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
}
