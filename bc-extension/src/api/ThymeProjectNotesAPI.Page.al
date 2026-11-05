/// <summary>
/// Custom API page for a project's Notes: Business Central's own Notes on the project
/// (the Notes factbox on the Project card), newest first. Thyme shows the latest as the
/// project's status, with the earlier ones a click away, and adds new ones.
///
/// A project's notes (the jobNo filter is required; without it there are none):
///   GET .../projectNotes?$filter=jobNo eq 'PR00010'
/// Add one, as the signed-in user:
///   POST .../projectNotes  { "jobNo": "PR00010", "note": "Blocked on the Azure database" }
///
/// Who can do what: anyone who can read the project can read and add its notes, as in
/// Business Central. Notes aren't changed or deleted here (do that in Business Central).
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/projectNotes
/// </summary>
page 50123 "Thyme Project Notes API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'projectNote';
    EntitySetName = 'projectNotes';
    EntityCaption = 'Project Note';
    EntitySetCaption = 'Project Notes';
    PageType = API;
    SourceTable = "Thyme Project Note";
    SourceTableTemporary = true;
    SourceTableView = sorting("Sort Key");
    DelayedInsert = true;
    ODataKeyFields = "Link ID";
    Extensible = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec."Link ID")
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(note; Rec.Note)
                {
                    Caption = 'Note';
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'Created At';
                    Editable = false;
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                    Editable = false;
                }
                field(createdByName; Rec."Created By Name")
                {
                    Caption = 'Created By Name';
                    Editable = false;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        JobNo: Code[20];
    begin
        // Loaded once per request, for the project the filter names
        if not Loaded then begin
            JobNo := CopyStr(Rec.GetFilter("Job No."), 1, MaxStrLen(JobNo));
            ProjectNotes.LoadNotes(JobNo, Rec);
            Loaded := true;
        end;
        exit(Rec.Find(Which));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Added: Record "Thyme Project Note" temporary;
    begin
        ProjectNotes.AddNote(Rec."Job No.", Rec.Note, Added);
        Rec := Added;
        Rec.Insert();
        exit(false);
    end;

    var
        ProjectNotes: Codeunit "Thyme Project Notes";
        Loaded: Boolean;
}
