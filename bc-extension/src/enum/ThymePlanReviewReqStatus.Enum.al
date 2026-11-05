/// <summary>
/// Lifecycle of an on-demand request for an AI plan review: created as Requested from Thyme,
/// claimed by the agent (Running), then Done or Failed.
/// </summary>
enum 50108 "Thyme Plan Review Req. Status"
{
    Extensible = false;
    Caption = 'Thyme Plan Review Request Status';

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
