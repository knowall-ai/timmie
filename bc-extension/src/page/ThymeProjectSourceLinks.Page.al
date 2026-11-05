/// <summary>
/// Linked sources on the Project Card: the GitHub repos, Azure DevOps projects and repos, meeting
/// keywords and attendee domains whose time belongs to this project. Thyme administrators and
/// the project's manager can edit them; the table refuses changes from anyone else.
/// </summary>
page 50117 "Thyme Project Source Links"
{
    Caption = 'Thyme Linked Sources';
    PageType = ListPart;
    SourceTable = "Thyme Project Source Link";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Links)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies what the link matches: a GitHub repo, an Azure DevOps project or repo, a keyword in a meeting''s subject, or the e-mail domain of an external meeting attendee.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the repo (owner/repo, owner/* or owner/prefix-*, or its URL), the DevOps project (organisation/project or its URL) or repo (organisation/project/repo or its URL), the meeting keyword, or the attendee domain (or an attendee''s e-mail address).';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the task to log this time against. Leave it empty to let the agent pick the task (the month''s block, or the only posting task).';
                }
                field("Use Monthly Block"; Rec."Use Monthly Block")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log this time against the posting task named after the month (for example "Block 7 - October"). With a task, that task is used until the month''s block exists.';
                }
                field(Learned; Rec.Learned)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the AI agent added this link, learned from approved time. Editing a learned link makes it yours.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who added the link.';
                    Visible = false;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the link was added.';
                    Visible = false;
                }
            }
        }
    }
}
