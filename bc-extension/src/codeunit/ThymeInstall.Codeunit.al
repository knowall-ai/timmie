/// <summary>
/// Creates the Thyme Setup record (with its default targets) in every company when the
/// extension is first installed.
/// </summary>
codeunit 50101 "Thyme Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ThymeSetup: Record "Thyme Setup";
    begin
        ThymeSetup.InsertIfNotExists();
    end;
}
