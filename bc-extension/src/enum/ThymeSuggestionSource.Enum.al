/// <summary>
/// Where an AI time-entry suggestion came from.
/// Value names deliberately have no spaces so the API exposes them unchanged.
/// </summary>
enum 50102 "Thyme Suggestion Source"
{
    Extensible = false;
    Caption = 'Thyme Suggestion Source';

    value(0; Calendar)
    {
        Caption = 'Calendar';
    }
    value(1; GitHub)
    {
        Caption = 'GitHub';
    }
    value(2; DevOps)
    {
        Caption = 'DevOps';
    }
    value(3; Other)
    {
        Caption = 'Other';
    }
}
