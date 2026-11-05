/// <summary>
/// Codeunit providing time sheet approval workflow actions for the Thyme API.
/// Wraps BC's built-in Time Sheet Approval Management functionality.
/// </summary>
codeunit 50100 "Thyme Time Sheet Actions"
{
    var
        TimeSheetOverlapErr: Label 'A time sheet already exists for resource %1 covering %2. Overlapping time sheets are not allowed.', Comment = '%1 = resource number, %2 = starting date';
        NotAllowedToCreateErr: Label 'You are not allowed to create a time sheet for resource %1. Only the resource''s time sheet owner or approver, or a time sheet administrator, can create one.', Comment = '%1 = resource number';

    /// <summary>
    /// Prepares a new Time Sheet Header created through the API so that it matches
    /// what BC's "Create Time Sheets" batch job would have produced.
    ///
    /// A plain API insert leaves "No." blank (the number series is only applied by the
    /// batch job) and "Ending Date" as 0D, which produces an unusable header. This fills
    /// in the number, the week end date and the owner/approver from the resource card.
    /// </summary>
    procedure InitTimeSheetFromApi(var TimeSheetHeader: Record "Time Sheet Header")
    var
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        ExistingTimeSheet: Record "Time Sheet Header";
        NoSeries: Codeunit "No. Series";
    begin
        TimeSheetHeader.TestField("Resource No.");
        TimeSheetHeader.TestField("Starting Date");

        Resource.Get(TimeSheetHeader."Resource No.");
        Resource.TestField("Use Time Sheet");
        CheckMayCreateTimeSheet(Resource);

        // Always a one week period, as the batch job produces. Any endingDate supplied by
        // the caller is overwritten rather than honoured, so the period cannot drift away
        // from the contract and undermine the overlap check below.
        TimeSheetHeader."Ending Date" := TimeSheetHeader."Starting Date" + 6;

        // Reject a period that overlaps an existing sheet. This catches both a duplicate
        // week and a starting date that is not aligned to the resource's week boundary.
        // Lock first so concurrent POSTs for the same period cannot both pass the check.
        ExistingTimeSheet.LockTable();
        ExistingTimeSheet.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        ExistingTimeSheet.SetFilter("Ending Date", '>=%1', TimeSheetHeader."Starting Date");
        ExistingTimeSheet.SetFilter("Starting Date", '<=%1', TimeSheetHeader."Ending Date");
        if ExistingTimeSheet.FindFirst() then
            Error(TimeSheetOverlapErr, TimeSheetHeader."Resource No.", TimeSheetHeader."Starting Date");

        if TimeSheetHeader."No." = '' then begin
            ResourcesSetup.Get();
            ResourcesSetup.TestField("Time Sheet Nos.");
            TimeSheetHeader."No." := NoSeries.GetNextNo(ResourcesSetup."Time Sheet Nos.", TimeSheetHeader."Starting Date");
        end;

        if TimeSheetHeader."Owner User ID" = '' then
            TimeSheetHeader."Owner User ID" := Resource."Time Sheet Owner User ID";
        if TimeSheetHeader."Approver User ID" = '' then
            TimeSheetHeader."Approver User ID" := Resource."Time Sheet Approver User ID";

        TimeSheetHeader.TestField("Owner User ID");
        TimeSheetHeader.TestField("Approver User ID");
    end;

    /// <summary>
    /// Mirrors who BC lets create time sheets: the resource's own time sheet owner, its
    /// approver, or a time sheet administrator (User Setup). Without this, any user with
    /// API access could create time sheets for any resource.
    /// </summary>
    local procedure CheckMayCreateTimeSheet(Resource: Record Resource)
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        if (Resource."Time Sheet Owner User ID" <> '') and (UpperCase(Resource."Time Sheet Owner User ID") = UpperCase(UserId())) then
            exit;
        if (Resource."Time Sheet Approver User ID" <> '') and (UpperCase(Resource."Time Sheet Approver User ID") = UpperCase(UserId())) then
            exit;
        if RecordSecurity.IsTimeSheetAdmin() then
            exit;
        Error(NotAllowedToCreateErr, Resource."No.");
    end;

    /// <summary>
    /// Submits a time sheet for approval by submitting all open lines.
    /// </summary>
    procedure SubmitTimeSheet(var TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Open);
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.Submit(TimeSheetLine);
            until TimeSheetLine.Next() = 0;
    end;

    /// <summary>
    /// Approves a submitted time sheet by approving all submitted lines.
    /// </summary>
    procedure ApproveTimeSheet(var TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.Approve(TimeSheetLine);
            until TimeSheetLine.Next() = 0;
    end;

    /// <summary>
    /// Rejects a submitted time sheet by rejecting all submitted lines.
    /// </summary>
    procedure RejectTimeSheet(var TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.Reject(TimeSheetLine);
            until TimeSheetLine.Next() = 0;
    end;

    /// <summary>
    /// Reopens a rejected or approved time sheet by reopening all non-open lines.
    /// </summary>
    procedure ReopenTimeSheet(var TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetFilter(Status, '%1|%2|%3',
            TimeSheetLine.Status::Submitted,
            TimeSheetLine.Status::Rejected,
            TimeSheetLine.Status::Approved);
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.ReopenSubmitted(TimeSheetLine);
            until TimeSheetLine.Next() = 0;
    end;

    /// <summary>
    /// Approves a specific time sheet line.
    /// </summary>
    procedure ApproveTimeSheetLine(var TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
    end;

    /// <summary>
    /// Rejects a specific time sheet line.
    /// </summary>
    procedure RejectTimeSheetLine(var TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetApprovalMgt.Reject(TimeSheetLine);
    end;

    /// <summary>
    /// Reopens a specific time sheet line for editing.
    /// </summary>
    procedure ReopenTimeSheetLine(var TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetApprovalMgt.ReopenSubmitted(TimeSheetLine);
    end;
}
