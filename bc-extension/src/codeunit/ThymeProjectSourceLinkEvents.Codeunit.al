/// <summary>
/// Keeps project source links tidy: a deleted project takes its links with it.
/// </summary>
codeunit 50105 "Thyme Source Link Events"
{
    Permissions = tabledata "Thyme Project Source Link" = rd;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteSourceLinksOnAfterDeleteJob(var Rec: Record Job; RunTrigger: Boolean)
    var
        Link: Record "Thyme Project Source Link";
    begin
        if Rec.IsTemporary() then
            exit;
        Link.SetRange("Job No.", Rec."No.");
        // Without triggers: whoever may delete the project may remove its links.
        Link.DeleteAll(false);
    end;
}
