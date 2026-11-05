/// <summary>
/// Creates the Thyme Setup record (with its default targets) in every company when an
/// existing installation is upgraded to a version that has it.
/// </summary>
codeunit 50102 "Thyme Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        ThymeSetup: Record "Thyme Setup";
    begin
        ThymeSetup.InsertIfNotExists();
    end;
}
