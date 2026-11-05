/// <summary>
/// Creates the Thyme Setup record (with its default targets) in companies created after
/// the extension was installed, so read-only Thyme users see the defaults straight away.
/// </summary>
codeunit 50103 "Thyme Company Initialize"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CreateThymeSetupOnCompanyInitialize()
    var
        ThymeSetup: Record "Thyme Setup";
    begin
        ThymeSetup.InsertIfNotExists();
    end;
}
