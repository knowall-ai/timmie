/// <summary>
/// Shows the Thyme linked sources (repos, DevOps projects, meeting keywords, attendee domains)
/// on the Project Card.
/// </summary>
pageextension 50101 "Thyme Job Card" extends "Job Card"
{
    layout
    {
        addlast(Content)
        {
            part(ThymeSourceLinks; "Thyme Project Source Links")
            {
                ApplicationArea = All;
                Caption = 'Thyme Linked Sources';
                SubPageLink = "Job No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }
}
