/// <summary>
/// A project's Notes: Business Central's own (Record Links of type Note on the Job), read
/// and added for the projectNotes API. Anyone who can read the project can read and add
/// its notes, as on the Project card in Business Central.
/// </summary>
codeunit 50108 "Thyme Project Notes"
{
    Permissions = tabledata "Record Link" = ri;

    /// <summary>Every note on the project, newest first, into the temporary NoteBuffer.</summary>
    procedure LoadNotes(JobNo: Code[20]; var NoteBuffer: Record "Thyme Project Note" temporary)
    var
        Job: Record Job;
        RecordLink: Record "Record Link";
    begin
        NoteBuffer.Reset();
        NoteBuffer.DeleteAll();
        if (JobNo = '') or not Job.Get(JobNo) then
            exit;
        RecordLink.SetRange("Record ID", Job.RecordId);
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange(Company, CompanyName);
        if RecordLink.FindSet() then
            repeat
                AddToBuffer(Job."No.", RecordLink, NoteBuffer);
            until RecordLink.Next() = 0;
        NoteBuffer.SetCurrentKey("Sort Key");
    end;

    /// <summary>Adds a note to the project, written by the current user, and returns it.</summary>
    procedure AddNote(JobNo: Code[20]; NoteText: Text; var NoteBuffer: Record "Thyme Project Note" temporary)
    var
        Job: Record Job;
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        if DelChr(NoteText, '<>', ' ') = '' then
            Error(EmptyNoteErr);
        Job.Get(JobNo);
        RecordLink.Init();
        RecordLink."Record ID" := Job.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := CopyStr(Job.Description, 1, MaxStrLen(RecordLink.Description));
        RecordLink.Created := CurrentDateTime;
        RecordLink."User ID" := CopyStr(UserId, 1, MaxStrLen(RecordLink."User ID"));
        RecordLink.Company := CopyStr(CompanyName, 1, MaxStrLen(RecordLink.Company));
        RecordLinkManagement.WriteNote(RecordLink, NoteText);
        RecordLink.Insert(true);
        AddToBuffer(Job."No.", RecordLink, NoteBuffer);
    end;

    local procedure AddToBuffer(JobNo: Code[20]; RecordLink: Record "Record Link"; var NoteBuffer: Record "Thyme Project Note" temporary)
    var
        User: Record User;
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        NoteBuffer.Init();
        NoteBuffer."Link ID" := RecordLink."Link ID";
        NoteBuffer."Job No." := JobNo;
        // The note is a Blob: not read with the record, so load it first
        RecordLink.CalcFields(Note);
        NoteBuffer.Note := CopyStr(RecordLinkManagement.ReadNote(RecordLink), 1, MaxStrLen(NoteBuffer.Note));
        NoteBuffer."Created At" := RecordLink.Created;
        NoteBuffer."Created By" := CopyStr(RecordLink."User ID", 1, MaxStrLen(NoteBuffer."Created By"));
        User.SetRange("User Name", RecordLink."User ID");
        if User.FindFirst() and (User."Full Name" <> '') then
            NoteBuffer."Created By Name" := CopyStr(User."Full Name", 1, MaxStrLen(NoteBuffer."Created By Name"))
        else
            NoteBuffer."Created By Name" := CopyStr(RecordLink."User ID", 1, MaxStrLen(NoteBuffer."Created By Name"));
        // Newest first: the later the note, the smaller the key (milliseconds until the
        // end of 9999); one without a date goes last
        if RecordLink.Created = 0DT then
            NoteBuffer."Sort Key" := 9223372036854775807L
        else
            NoteBuffer."Sort Key" := CreateDateTime(DMY2Date(31, 12, 9999), 0T) - RecordLink.Created;
        NoteBuffer.Insert();
    end;

    var
        EmptyNoteErr: Label 'A note needs some text.';
}
