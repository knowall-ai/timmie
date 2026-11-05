/// <summary>
/// Shows the Thyme billable target, weekly capacity, flexible working days and GitHub username
/// on the Resource Card.
/// </summary>
pageextension 50100 "Thyme Resource Card" extends "Resource Card"
{
    layout
    {
        addlast(Content)
        {
            group(Thyme)
            {
                Caption = 'Thyme';

                field("Thyme Billable Target %"; Rec."Thyme Billable Target %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of this person''s logged time that should be billable, from 0 to 100. Entering a value, including 0, sets a target for this person and turns on Billable Target Set.';
                }
                field("Thyme Billable Target Set"; Rec."Thyme Billable Target Set")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this person has their own billable target. When this is off, Thyme uses the Default Billable Target % from Thyme Setup. Turning it off clears the person''s target.';
                }
                field("Thyme Weekly Capacity (Hours)"; Rec."Thyme Weekly Capacity (Hours)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many hours a week this person works, for example 15 for two days a week. Entering a value, including 0, turns on Weekly Capacity Set. 0 keeps the person listed in Thyme but leaves them out of team capacity and targets.';
                }
                field("Thyme Weekly Capacity Set"; Rec."Thyme Weekly Capacity Set")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this person has their own weekly capacity. When this is off, Thyme uses their hours per day times 5. Turning it off clears the person''s weekly capacity.';
                }
                field("Thyme Flexible Working Days"; Rec."Thyme Flexible Working Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this person works their weekly capacity on any days rather than fixed weekdays. Thyme then checks their week as a whole instead of expecting hours every day.';
                }
                field("Thyme GitHub Username"; Rec."Thyme GitHub Username")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies this person''s GitHub username, so the AI agent can suggest time for their pull requests and issues. A Thyme administrator can change anyone''s; people can change their own.';
                }
            }
        }
    }
}
