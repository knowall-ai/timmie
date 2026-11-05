/// <summary>
/// Row-level security for the AI timesheet review and time suggestion APIs.
///
/// Who sees what:
/// - A timesheet review and its findings: the time sheet's owner, its approver, a Thyme
///   administrator and the AI agent.
/// - A time suggestion: the user it is for (the time sheet owner of its resource), a
///   Thyme administrator and the AI agent.
/// - A suggestion request (asking the agent to generate suggestions now): the resource's
///   time sheet owner and approver, a Thyme administrator and the AI agent. The same people
///   can create one; only the AI agent can change or delete one. An approver who requests
///   suggestions still can't see them: they stay with the person they are for.
/// - An AI plan review (of a person's or a project's week of planning lines), its findings and
///   proposed changes: every Thyme user reads them; only the AI agent or a Thyme administrator
///   writes them (CheckCanWritePlanReviews). A plan review request: every Thyme user reads them;
///   people who may change the plan (CanEditPlan) create them; only the AI agent changes or deletes one.
/// - A timesheet review request (asking the agent to review a time sheet again now): the time
///   sheet's owner and approver, a Thyme administrator and the AI agent (the people who see its
///   reviews). The same people can create one; only the AI agent can change or delete one.
/// - An agent heartbeat (when the agent was last seen): every Thyme user; only the AI agent writes.
/// - A project source link (which repos, DevOps projects, meeting keywords and attendee domains
///   belong to a project): every Thyme user reads them. A Thyme administrator or the project's
///   manager (its Project Manager, or the time sheet owner of its Person Responsible) adds,
///   changes and removes them. The AI agent adds links it learned (always marked Learned) and
///   changes or removes only learned links; a person who edits a learned link adopts it.
/// - A person's connected accounts (the GitHub username on their resource):
///   everyone who can read resources sees them. A Thyme administrator changes anyone's; a person
///   changes their own (the resource whose Time Sheet Owner User ID is them).
/// - The plan (resource planning lines and what goes with them): only a user with permission to
///   write Job Planning Lines may change it, with no administrator or AI agent shortcut (CanEditPlan;
///   the projects and resources APIs expose it per caller as canEditPlan).
///
/// A Thyme administrator is a time sheet administrator (User Setup, the same rule that
/// governs creating time sheets through the API) or a user with the THYME ADMIN
/// permission set. The AI agent is identified by the THYME AI AGENT permission set. Both
/// permission sets count whether assigned directly or through a security group. SUPER
/// on its own does not bypass these rules.
///
/// The API pages apply the filters below in OnOpenPage, so collection reads, $filter
/// queries and GET/PATCH/DELETE by id all only reach records the caller may see. The
/// filters run in SQL (FlowFields), not as per-record checks.
/// </summary>
codeunit 50104 "Thyme Record Security"
{
    Permissions = tabledata "User Setup" = r,
                  tabledata Resource = r,
                  tabledata Job = r,
                  tabledata "Time Sheet Header" = r;

    var
        ThymeAdminRoleTok: Label 'THYME ADMIN', Locked = true;
        ThymeAIAgentRoleTok: Label 'THYME AI AGENT', Locked = true;
        NotAllowedToWriteReviewsErr: Label 'You are not allowed to change timesheet reviews. Only the AI agent or a Thyme administrator can.';
        NotAllowedToRequestSuggestionsErr: Label 'You are not allowed to request time suggestions for resource %1. You can request them for yourself, for people whose time sheets you approve, or for anyone as a Thyme administrator.', Comment = '%1 = resource number';
        NotAllowedToWriteHeartbeatErr: Label 'Only the AI agent can update agent heartbeats.';
        NotAllowedToChangeRequestsErr: Label 'You are not allowed to change suggestion requests. Only the AI agent can.';
        NotAllowedToWriteSourceLinksErr: Label 'You are not allowed to change the linked sources of project %1. A Thyme administrator or the project''s manager can.', Comment = '%1 = job number';
        AgentOnlyLearnedLinksErr: Label 'The AI agent can only change or remove linked sources it learned. Project %1 line %2 was added by a person.', Comment = '%1 = job number, %2 = line number';
        NotAllowedToEditConnectedAccountsErr: Label 'You are not allowed to change the GitHub username of resource %1. You can change your own, or anyone''s as a Thyme administrator.', Comment = '%1 = resource number';
        NotAllowedToWriteSuggestionErr: Label 'You are not allowed to change time suggestions for resource %1. You can only change suggestions for a resource whose time sheets you own.', Comment = '%1 = resource number';

    /// <summary>
    /// True for a time sheet administrator (the "Time Sheet Admin." flag in User Setup).
    /// </summary>
    procedure IsTimeSheetAdmin(): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId()) then
            exit(UserSetup."Time Sheet Admin.");
        exit(false);
    end;

    /// <summary>
    /// True for a time sheet administrator or a user with the THYME ADMIN permission set.
    /// </summary>
    procedure IsThymeAdmin(): Boolean
    begin
        if IsTimeSheetAdmin() then
            exit(true);
        exit(HasThymePermissionSet(ThymeAdminRoleTok));
    end;

    /// <summary>
    /// True for the AI agent's app identity, recognised by the THYME AI AGENT permission set.
    /// </summary>
    procedure IsAIAgent(): Boolean
    begin
        exit(HasThymePermissionSet(ThymeAIAgentRoleTok));
    end;

    /// <summary>
    /// True if the caller sees every review and suggestion: the AI agent or a Thyme administrator.
    /// </summary>
    procedure CanAccessAll(): Boolean
    begin
        if IsAIAgent() then
            exit(true);
        exit(IsThymeAdmin());
    end;

    /// <summary>
    /// Limits reviews to time sheets the caller owns or approves, unless they can access all.
    /// </summary>
    procedure ApplyReviewFilter(var Review: Record "Thyme Timesheet Review")
    begin
        if CanAccessAll() then
            exit;

        // Owner = me OR approver = me, written as: the time sheet exists AND it is not the
        // case that both its owner and its approver are someone else (see the table fields).
        Review.FilterGroup(2);
        Review.SetFilter("User ID Filter", '<>%1', CurrentUserCode());
        Review.SetRange("Hidden From User Filter", false);
        Review.SetRange("Time Sheet Exists", true);
        Review.FilterGroup(0);
    end;

    /// <summary>
    /// Limits review findings to time sheets the caller owns or approves, unless they can access all.
    /// </summary>
    procedure ApplyReviewLineFilter(var ReviewLine: Record "Thyme Timesheet Review Line")
    begin
        if CanAccessAll() then
            exit;

        ReviewLine.FilterGroup(2);
        ReviewLine.SetFilter("User ID Filter", '<>%1', CurrentUserCode());
        ReviewLine.SetRange("Hidden From User Filter", false);
        ReviewLine.SetRange("Time Sheet Exists", true);
        ReviewLine.FilterGroup(0);
    end;

    /// <summary>
    /// Limits suggestions to resources whose time sheets the caller owns, unless they can access all.
    /// </summary>
    procedure ApplySuggestionFilter(var Suggestion: Record "Thyme Time Suggestion")
    begin
        if CanAccessAll() then
            exit;

        Suggestion.FilterGroup(2);
        Suggestion.SetRange("Resource Owner User ID", CurrentUserCode());
        Suggestion.FilterGroup(0);
    end;

    /// <summary>
    /// Only the AI agent or a Thyme administrator may create, change or delete reviews
    /// and their findings.
    /// </summary>
    procedure CheckCanWriteReviews()
    begin
        if not CanAccessAll() then
            Error(NotAllowedToWriteReviewsErr);
    end;

    /// <summary>
    /// A suggestion being created or changed must be for a resource whose time sheets the
    /// caller owns, unless they can access all. Checked on the new values, so a user can't
    /// move their suggestion to someone else.
    /// </summary>
    procedure CheckCanWriteSuggestion(Suggestion: Record "Thyme Time Suggestion")
    begin
        if CanAccessAll() then
            exit;
        if not IsOwnResource(Suggestion."Resource No.") then
            Error(NotAllowedToWriteSuggestionErr, Suggestion."Resource No.");
    end;

    /// <summary>
    /// Limits suggestion requests to resources whose time sheets the caller owns or approves,
    /// unless they can access all.
    /// </summary>
    procedure ApplySuggestionRequestFilter(var Request: Record "Thyme Suggestion Request")
    begin
        if CanAccessAll() then
            exit;

        // Owner = me OR approver = me, written as: the resource exists AND it is not the case
        // that both its owner and its approver are someone else (see the table fields).
        Request.FilterGroup(2);
        Request.SetFilter("User ID Filter", '<>%1', CurrentUserCode());
        Request.SetRange("Hidden From User Filter", false);
        Request.SetRange("Resource Exists", true);
        Request.FilterGroup(0);
    end;

    /// <summary>
    /// True if the caller may ask the agent for suggestions for this resource: its time sheet
    /// owner or approver, a Thyme administrator or the AI agent. The resource must use time sheets.
    /// </summary>
    procedure CanRequestSuggestions(ResourceNo: Code[20]): Boolean
    var
        Resource: Record Resource;
    begin
        if ResourceNo = '' then
            exit(false);
        if not Resource.Get(ResourceNo) then
            exit(false);
        exit(CanRequestSuggestions(Resource, CanAccessAll()));
    end;

    /// <summary>
    /// As CanRequestSuggestions(ResourceNo), for a resource already read and with the caller's
    /// CanAccessAll() worked out once (the resources API asks this for every row).
    /// </summary>
    procedure CanRequestSuggestions(Resource: Record Resource; CallerCanAccessAll: Boolean): Boolean
    var
        Me: Code[50];
    begin
        if not Resource."Use Time Sheet" then
            exit(false);
        if CallerCanAccessAll then
            exit(true);
        Me := CurrentUserCode();
        exit((UpperCase(Resource."Time Sheet Owner User ID") = Me) or (UpperCase(Resource."Time Sheet Approver User ID") = Me));
    end;

    procedure CheckCanRequestSuggestions(ResourceNo: Code[20])
    begin
        if not CanRequestSuggestions(ResourceNo) then
            Error(NotAllowedToRequestSuggestionsErr, ResourceNo);
    end;

    /// <summary>
    /// Only the AI agent moves a request through Running to Done or Failed, or removes one.
    /// </summary>
    procedure CheckCanChangeSuggestionRequests()
    begin
        if not IsAIAgent() then
            Error(NotAllowedToChangeRequestsErr);
    end;

    /// <summary>
    /// Only the AI agent moves a plan review request through Running to Done or Failed, or
    /// removes one.
    /// </summary>
    procedure CheckCanChangePlanReviewRequests()
    var
        NotAllowedToChangePlanReviewRequestsErr: Label 'You are not allowed to change plan review requests. Only the AI agent can.';
    begin
        if not IsAIAgent() then
            Error(NotAllowedToChangePlanReviewRequestsErr);
    end;

    /// <summary>
    /// Limits timesheet review requests to time sheets the caller owns or approves, unless they
    /// can access all (the same rows as ApplyReviewFilter).
    /// </summary>
    procedure ApplyTimesheetReviewRequestFilter(var Request: Record "Thyme Timesheet Review Request")
    begin
        if CanAccessAll() then
            exit;

        Request.FilterGroup(2);
        Request.SetFilter("User ID Filter", '<>%1', CurrentUserCode());
        Request.SetRange("Hidden From User Filter", false);
        Request.SetRange("Time Sheet Exists", true);
        Request.FilterGroup(0);
    end;

    /// <summary>
    /// True if the caller may ask the agent to review this time sheet again: its owner or
    /// approver, a Thyme administrator or the AI agent. The time sheet must exist.
    /// </summary>
    procedure CanRequestTimesheetReview(TimeSheetNo: Code[20]): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
        Me: Code[50];
    begin
        if TimeSheetNo = '' then
            exit(false);
        if not TimeSheetHeader.Get(TimeSheetNo) then
            exit(false);
        if CanAccessAll() then
            exit(true);
        Me := CurrentUserCode();
        exit((UpperCase(TimeSheetHeader."Owner User ID") = Me) or (UpperCase(TimeSheetHeader."Approver User ID") = Me));
    end;

    procedure CheckCanRequestTimesheetReview(TimeSheetNo: Code[20])
    var
        NotAllowedToRequestTimesheetReviewErr: Label 'You are not allowed to request a review of time sheet %1. You can request one for your own time sheets, for time sheets you approve, or for any as a Thyme administrator.', Comment = '%1 = time sheet number';
    begin
        if not CanRequestTimesheetReview(TimeSheetNo) then
            Error(NotAllowedToRequestTimesheetReviewErr, TimeSheetNo);
    end;

    /// <summary>
    /// Only the AI agent moves a timesheet review request through Running to Done or Failed,
    /// or removes one.
    /// </summary>
    procedure CheckCanChangeTimesheetReviewRequests()
    var
        NotAllowedToChangeTimesheetReviewRequestsErr: Label 'You are not allowed to change timesheet review requests. Only the AI agent can.';
    begin
        if not IsAIAgent() then
            Error(NotAllowedToChangeTimesheetReviewRequestsErr);
    end;

    /// <summary>
    /// Only the AI agent or a Thyme administrator may create, change or delete plan reviews,
    /// their findings and proposed changes (the same rule as CheckCanWriteReviews).
    /// </summary>
    procedure CheckCanWritePlanReviews()
    var
        NotAllowedToWritePlanReviewsErr: Label 'You are not allowed to change plan reviews. Only the AI agent or a Thyme administrator can.';
    begin
        if not CanAccessAll() then
            Error(NotAllowedToWritePlanReviewsErr);
    end;

    /// <summary>
    /// Agent heartbeats are readable by every Thyme user and written only by the AI agent.
    /// </summary>
    procedure CheckCanWriteHeartbeat()
    begin
        if not IsAIAgent() then
            Error(NotAllowedToWriteHeartbeatErr);
    end;

    /// <summary>
    /// True if the caller may add, change and remove the linked sources of a project: a Thyme
    /// administrator or the project's manager.
    /// </summary>
    procedure CanEditProjectSourceLinks(JobNo: Code[20]): Boolean
    var
        Job: Record Job;
    begin
        if IsThymeAdmin() then
            exit(true);
        if JobNo = '' then
            exit(false);
        if not Job.Get(JobNo) then
            exit(false);
        exit(IsProjectManager(Job));
    end;

    /// <summary>
    /// As CanEditProjectSourceLinks(JobNo), for a project already read and with IsThymeAdmin()
    /// worked out once (the projects API asks this for every row).
    /// </summary>
    procedure CanEditProjectSourceLinks(Job: Record Job; CallerIsThymeAdmin: Boolean): Boolean
    begin
        if CallerIsThymeAdmin then
            exit(true);
        exit(IsProjectManager(Job));
    end;

    /// <summary>
    /// The project's manager: its Project Manager user, or the time sheet owner of the resource
    /// that is its Person Responsible.
    /// </summary>
    procedure IsProjectManager(Job: Record Job): Boolean
    var
        Resource: Record Resource;
        Me: Code[50];
    begin
        Me := CurrentUserCode();
        if (Job."Project Manager" <> '') and (UpperCase(Job."Project Manager") = Me) then
            exit(true);
        if Job."Person Responsible" = '' then
            exit(false);
        if not Resource.Get(Job."Person Responsible") then
            exit(false);
        exit((Resource."Time Sheet Owner User ID" <> '') and (UpperCase(Resource."Time Sheet Owner User ID") = Me));
    end;

    /// <summary>
    /// A new link: the AI agent's are always marked Learned; a person's (administrator or the
    /// project's manager) never are; anyone else is refused.
    /// </summary>
    procedure CheckCanInsertSourceLink(var Link: Record "Thyme Project Source Link")
    begin
        if IsAIAgent() then begin
            Link.Learned := true;
            exit;
        end;
        if not CanEditProjectSourceLinks(Link."Job No.") then
            Error(NotAllowedToWriteSourceLinksErr, Link."Job No.");
        Link.Learned := false;
    end;

    /// <summary>
    /// A changed link: the AI agent only changes learned links (they stay learned); a person who
    /// may edit the project's links adopts the link (no longer learned).
    /// </summary>
    procedure CheckCanModifySourceLink(var Link: Record "Thyme Project Source Link")
    begin
        if IsAIAgent() then begin
            CheckLearnedLink(Link);
            Link.Learned := true;
            exit;
        end;
        if not CanEditProjectSourceLinks(Link."Job No.") then
            Error(NotAllowedToWriteSourceLinksErr, Link."Job No.");
        Link.Learned := false;
    end;

    procedure CheckCanDeleteSourceLink(Link: Record "Thyme Project Source Link")
    begin
        if IsAIAgent() then begin
            CheckLearnedLink(Link);
            exit;
        end;
        if not CanEditProjectSourceLinks(Link."Job No.") then
            Error(NotAllowedToWriteSourceLinksErr, Link."Job No.");
    end;

    /// <summary>
    /// True if the caller may change the resource's connected accounts (its GitHub username):
    /// a Thyme administrator, or the person themselves (the resource's time sheet owner).
    /// Uses the owner as stored, so changing the owner in the same edit can't grant access.
    /// </summary>
    procedure CanEditConnectedAccounts(ResourceNo: Code[20]): Boolean
    begin
        if IsThymeAdmin() then
            exit(true);
        exit(IsOwnResource(ResourceNo));
    end;

    /// <summary>
    /// As CanEditConnectedAccounts(ResourceNo), for a resource already read from the database and
    /// with IsThymeAdmin() worked out once (the resources API asks this for every row).
    /// </summary>
    procedure CanEditConnectedAccounts(Resource: Record Resource; CallerIsThymeAdmin: Boolean): Boolean
    begin
        if CallerIsThymeAdmin then
            exit(true);
        exit((Resource."Time Sheet Owner User ID" <> '') and (UpperCase(Resource."Time Sheet Owner User ID") = CurrentUserCode()));
    end;

    procedure CheckCanEditConnectedAccounts(ResourceNo: Code[20])
    begin
        if not CanEditConnectedAccounts(ResourceNo) then
            Error(NotAllowedToEditConnectedAccountsErr, ResourceNo);
    end;

    /// <summary>
    /// True if the caller may change the plan (resource planning lines, i.e. Thyme's Plan grid,
    /// and what goes with it): exactly the users with permission to write Job Planning Lines.
    /// Being a Thyme administrator or the AI agent doesn't count on its own, so Thyme never offers
    /// a change BC would then refuse. The same for every project and resource, so the projects
    /// and resources APIs work it out once per call (canEditPlan).
    /// </summary>
    procedure CanEditPlan(): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        exit(JobPlanningLine.WritePermission());
    end;

    /// <summary>
    /// Raises NotAllowedErr (the caller's own message, e.g. for day notes) unless CanEditPlan().
    /// </summary>
    procedure CheckCanEditPlan(NotAllowedErr: Text)
    begin
        if not CanEditPlan() then
            Error(NotAllowedErr);
    end;

    /// <summary>The link as stored must be a learned one (checked on the stored row, not the new values).</summary>
    local procedure CheckLearnedLink(Link: Record "Thyme Project Source Link")
    var
        Stored: Record "Thyme Project Source Link";
    begin
        if not Stored.Get(Link."Job No.", Link."Line No.") then
            Error(AgentOnlyLearnedLinksErr, Link."Job No.", Link."Line No.");
        if not Stored.Learned then
            Error(AgentOnlyLearnedLinksErr, Link."Job No.", Link."Line No.");
    end;

    local procedure IsOwnResource(ResourceNo: Code[20]): Boolean
    var
        Resource: Record Resource;
    begin
        if ResourceNo = '' then
            exit(false);
        if not Resource.Get(ResourceNo) then
            exit(false);
        exit((Resource."Time Sheet Owner User ID" <> '') and (Resource."Time Sheet Owner User ID" = CurrentUserCode()));
    end;

    local procedure HasThymePermissionSet(RoleId: Code[20]): Boolean
    var
        UserPermissions: Codeunit "User Permissions";
        CurrentModule: ModuleInfo;
        SystemScope: Option System,Tenant;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);
        exit(UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), RoleId, SystemScope::System, CurrentModule.Id()));
    end;

    /// <summary>
    /// The caller's user name as stored in the Code[50] user ID fields. Never blank, so a
    /// filter on it can't match a time sheet or resource that has no owner or approver.
    /// </summary>
    local procedure CurrentUserCode(): Code[50]
    var
        NoUserTok: Label '<NO USER>', Locked = true;
    begin
        if UserId() = '' then
            exit(NoUserTok);
        exit(CopyStr(UpperCase(UserId()), 1, 50));
    end;
}
