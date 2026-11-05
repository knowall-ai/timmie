/// <summary>
/// What an AI plan review looks at: one person's week (Resource, Subject No. = Resource No.)
/// or one project's week (Project, Subject No. = Job No.).
/// </summary>
enum 50107 "Thyme Plan Review Subject"
{
    Extensible = false;
    Caption = 'Thyme Plan Review Subject';

    value(0; Resource)
    {
        Caption = 'Resource';
    }
    value(1; Project)
    {
        Caption = 'Project';
    }
}
