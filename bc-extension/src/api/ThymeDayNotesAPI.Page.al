/// <summary>
/// Custom API page for day notes: notes on particular days, e.g. "Company Off-Site", for the
/// whole company (blank resourceNo) or one person. Thyme shows them on the Plan grid; the AI
/// agent's plan review treats noProjectWork days like public holidays.
///
/// Notes for the dates on screen (Thyme):
///   GET .../dayNotes?$filter=noteDate ge 2026-10-19 and noteDate le 2026-11-15
/// Add a company-wide day off project work:
///   POST .../dayNotes  { "noteDate": "2026-10-22", "note": "Company Off-Site", "noProjectWork": true }
///
/// Who can do what (codeunit "Thyme Record Security"):
/// - read: every Thyme user;
/// - create, change or delete: users who may change the plan (permission to write Job Planning
///   Lines; being a Thyme administrator or the AI agent doesn't count on its own). canEditPlan
///   on the projects and resources APIs answers this for the caller.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/dayNotes
/// </summary>
page 50122 "Thyme Day Notes API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'dayNote';
    EntitySetName = 'dayNotes';
    EntityCaption = 'Day Note';
    EntitySetCaption = 'Day Notes';
    PageType = API;
    SourceTable = "Thyme Day Note";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;
    // THYME USER only has indirect insert, modify and delete on day notes, so writes go through
    // this page and its CanEditPlan check.
    Permissions = tabledata "Thyme Day Note" = rimd;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(noteDate; Rec."Note Date")
                {
                    Caption = 'Note Date';
                }
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(note; Rec.Note)
                {
                    Caption = 'Note';
                }
                field(noProjectWork; Rec."No Project Work")
                {
                    Caption = 'No Project Work';
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                    Editable = false;
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'Created At';
                    Editable = false;
                }
                field(modifiedBy; Rec."Modified By")
                {
                    Caption = 'Modified By';
                    Editable = false;
                }
                field(modifiedAt; Rec."Modified At")
                {
                    Caption = 'Modified At';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified DateTime';
                    Editable = false;
                }
            }
        }
    }

    var
        NotAllowedToChangeDayNotesErr: Label 'You don''t have permission to change day notes.';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanEditPlan(NotAllowedToChangeDayNotesErr);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanEditPlan(NotAllowedToChangeDayNotesErr);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanEditPlan(NotAllowedToChangeDayNotesErr);
        exit(true);
    end;
}
