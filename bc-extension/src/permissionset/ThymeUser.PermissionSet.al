/// <summary>
/// For Thyme web app users: run the Thyme API pages, read AI timesheet reviews,
/// accept or dismiss AI time suggestions, ask the agent for suggestions now (suggestion
/// requests; who for is checked per resource), see whether the agent is online, read the company's default billable target,
/// and read projects' linked sources (changing them is checked per project: Thyme administrators and the project's manager),
/// and set their own GitHub username through the resources API's setGitHubUsername action.
/// Every Thyme user reads day notes; changing them is checked in code (people who may change the plan:
/// permission to write Job Planning Lines).
/// Base-app data such as time sheets and resources still comes from the standard D365
/// permission sets. To change the default billable target, use THYME ADMIN.
/// Every Thyme user reads a project's Notes (Business Central's own) and adds to them, through the
/// projectNotes API, as anyone who can read the project can on the Project card.
/// Every Thyme user reads AI plan reviews (with their findings and proposed changes) and plan review
/// requests, and can create a request (checked in code: people who may change the plan).
/// Thyme users read timesheet review requests for time sheets they own or approve and can create one
/// for those time sheets (checked in code), to ask the agent to review a time sheet again.
/// </summary>
permissionset 50101 "THYME USER"
{
    Assignable = true;
    Caption = 'Thyme User';

    Permissions =
        table "Thyme Timesheet Review" = X,
        table "Thyme Timesheet Review Line" = X,
        table "Thyme Time Suggestion" = X,
        table "Thyme Setup" = X,
        table "Thyme Suggestion Request" = X,
        table "Thyme Agent Heartbeat" = X,
        table "Thyme Plan Review" = X,
        table "Thyme Plan Review Line" = X,
        table "Thyme Plan Review Change" = X,
        table "Thyme Plan Review Request" = X,
        table "Thyme Timesheet Review Request" = X,
        table "Thyme Project Source Link" = X,
        table "Thyme Day Note" = X,
        table "Thyme Project Note" = X,
        tabledata "Thyme Timesheet Review" = R,
        tabledata "Thyme Timesheet Review Line" = R,
        tabledata "Thyme Time Suggestion" = RM,
        tabledata "Thyme Setup" = R,
        tabledata "Thyme Suggestion Request" = RI,
        tabledata "Thyme Agent Heartbeat" = R,
        tabledata "Thyme Plan Review" = R,
        // Direct read; indirect modify only, so codeunit "Thyme Plan Review Apply" can stamp a finding
        // Applied after applying its changes (which needs permission to change the plan).
        tabledata "Thyme Plan Review Line" = Rm,
        tabledata "Thyme Plan Review Change" = R,
        // Direct read; insert only indirect, so requests are created only through the
        // planReviewRequests API page, whose insert trigger checks CanEditPlan.
        tabledata "Thyme Plan Review Request" = Ri,
        // The same for timesheet review requests: insert only through the timesheetReviewRequests
        // API page, whose insert trigger checks the caller owns or approves the time sheet.
        tabledata "Thyme Timesheet Review Request" = Ri,
        tabledata "Thyme Project Source Link" = RIMD,
        // Direct read only; insert, modify and delete are indirect, so day notes can only be written
        // through the dayNotes API page, whose triggers check CanEditPlan (not, say, a config package).
        tabledata "Thyme Day Note" = Rimd,
        // Indirect only: lets codeunit "Thyme Connected Accounts" save a person's own GitHub
        // username after its row-level check; it gives no direct right to change resources.
        tabledata Resource = m,
        page "Thyme Projects API" = X,
        page "Thyme Job Tasks API" = X,
        page "Thyme Time Sheet API" = X,
        page "Thyme Time Sheet Line API" = X,
        page "Thyme Time Sheet Detail API" = X,
        page "Thyme Resources API" = X,
        page "Thyme Time Entries API" = X,
        page "Thyme Job Planning Lines API" = X,
        page "Thyme Resource UoM API" = X,
        page "Thyme Timesheet Reviews API" = X,
        page "Thyme TS Review Lines API" = X,
        page "Thyme Time Suggestions API" = X,
        page "Thyme Setup API" = X,
        page "Thyme Suggestion Requests API" = X,
        page "Thyme Agent Heartbeats API" = X,
        page "Thyme Plan Reviews API" = X,
        page "Thyme Plan Review Lines API" = X,
        page "Thyme Plan Review Changes API" = X,
        page "Thyme Plan Review Requests API" = X,
        page "Thyme TS Review Requests API" = X,
        page "Thyme Project Source Links API" = X,
        page "Thyme Project Notes API" = X,
        page "Thyme Project Source Links" = X,
        page "Thyme Day Notes API" = X,
        codeunit "Thyme Time Sheet Actions" = X,
        codeunit "Thyme Record Security" = X,
        codeunit "Thyme Connected Accounts" = X,
        codeunit "Thyme Source Link Events" = X,
        codeunit "Thyme Plan Review Apply" = X,
        // Sets a project's Sell-to customer for the projects API, keeping its Bill-to customer
        codeunit "Thyme Project Customer" = X,
        // Reads and adds the project Notes (Record Links) behind the projectNotes API, with its own
        // indirect Record Link permission, so no direct right to Record Links is needed
        codeunit "Thyme Project Notes" = X;
}
