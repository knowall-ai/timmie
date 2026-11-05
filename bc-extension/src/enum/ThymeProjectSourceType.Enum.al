/// <summary>
/// What a project source link matches: work in a GitHub repo, work in an Azure DevOps project or
/// one of its Git repos, a meeting whose subject contains a keyword, or a meeting with an
/// attendee from a domain.
/// Value names deliberately have no spaces so the API exposes them unchanged.
/// </summary>
enum 50106 "Thyme Project Source Type"
{
    Extensible = false;
    Caption = 'Thyme Project Source Type';

    value(0; GitHubRepo)
    {
        Caption = 'GitHub Repo';
    }
    value(1; DevOpsProject)
    {
        Caption = 'DevOps Project';
    }
    value(2; DevOpsRepo)
    {
        Caption = 'DevOps Repo';
    }
    value(3; MeetingKeyword)
    {
        Caption = 'Meeting Keyword';
    }
    value(4; AttendeeDomain)
    {
        Caption = 'Attendee Domain';
    }
}
