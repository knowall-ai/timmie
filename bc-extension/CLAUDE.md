# Thyme BC Extension - Claude Code Instructions

## Project Overview

This is a Business Central (BC) AL extension that provides custom API endpoints for the Thyme time tracking app. The standard BC API v2.0 has limited fields, so this extension exposes additional data.

## Key Files

- `app.json` - Extension manifest (ID ranges 50100-50199)
- `src/api/ThymeProjectsAPI.Page.al` - Projects API (page 50100)
- `src/api/ThymeJobTasksAPI.Page.al` - Job Tasks API (page 50101)
- `src/api/ThymeTimeSheetAPI.Page.al` - Time Sheets API (page 50102)
- `src/api/ThymeTimeSheetLineAPI.Page.al` - Time Sheet Line API (page 50103)
- `src/api/ThymeTimeSheetDetailAPI.Page.al` - Time Sheet Detail API (page 50106)
- `src/api/ThymeResourcesAPI.Page.al` - Resources API (page 50104)
- `src/api/ThymeTimeEntriesAPI.Page.al` - Time Entries API (page 50105)
- `src/api/ThymeJobPlanningLinesAPI.Page.al` - Job Planning Lines API (page 50107)
- `src/api/ThymeResourceUnitsOfMeasureAPI.Page.al` - Resource Units of Measure API (page 50108)
- `src/api/ThymeTimesheetReviewsAPI.Page.al` - Timesheet Reviews API (page 50109, table 50100)
- `src/api/ThymeTimesheetReviewLinesAPI.Page.al` - Timesheet Review Lines API (page 50110, table 50101)
- `src/api/ThymeTimeSuggestionsAPI.Page.al` - Time Suggestions API (page 50111, table 50102)
- `src/api/ThymeSuggestionRequestsAPI.Page.al` - Suggestion Requests API: ask the agent for suggestions now (page 50114, table 50104, status enum 50105)
- `src/api/ThymeAgentHeartbeatsAPI.Page.al` - Agent Heartbeats API: when the AI agent was last seen (page 50115, table 50105)
- `src/api/ThymeProjectNotesAPI.Page.al` - Project Notes API: Business Central's own Notes on a project (Record Links of type Note), newest first; filter by `jobNo`; POST adds one (page 50123, temporary table 50112, codeunit 50108 `Thyme Project Notes`)
- `src/api/ThymeProjectSourceLinksAPI.Page.al` - Project Source Links API: GitHub repos, DevOps projects and repos, meeting keywords and attendee domains per project, read by the AI agent to map time (page 50116, table 50106, type enum 50106); `src/page/ThymeProjectSourceLinks.Page.al` is the ListPart on the Project Card (page 50117, page extension 50101 `src/pageextension/ThymeJobCard.PageExt.al`); codeunit 50105 deletes a project's links with it
- `src/api/ThymeDayNotesAPI.Page.al` - Day Notes API: notes on particular days for the company or one person, e.g. "Company Off-Site", optionally with no project work that day (page 50122, table 50111)
- `src/api/ThymePlanReviewsAPI.Page.al` - Plan Reviews API: AI reviews of a person's or a project's week of planning lines (page 50118, table 50107, subject enum 50107)
- `src/api/ThymePlanReviewLinesAPI.Page.al` - Plan Review Lines API: a plan review's findings (page 50119, table 50108), with the `applyChanges` action; `src/codeunit/ThymePlanReviewApply.Codeunit.al` applies a finding's changes to the planning lines in one transaction (codeunit 50107)
- `src/api/ThymePlanReviewChangesAPI.Page.al` - Plan Review Changes API: planning-line changes a finding proposes, applied from Thyme (page 50120, table 50109)
- `src/api/ThymePlanReviewRequestsAPI.Page.al` - Plan Review Requests API: ask the agent to review a subject-week now (page 50121, table 50110, status enum 50108)
- `src/api/ThymeTimesheetReviewRequestsAPI.Page.al` - Timesheet Review Requests API: ask the agent to review a time sheet again now (page 50124, table 50113, status enum 50109); owner, approver, Thyme admins and the agent read and create, only the agent changes
- `src/api/ThymeSetupAPI.Page.al` - Thyme Setup API, single record (page 50112, table 50103 `Thyme Setup`)
- `src/page/ThymeSetup.Page.al` - Thyme Setup card (page 50113)
- `src/tableextension/ThymeResource.TableExt.al` - Resource billable target fields 50100-50101 and weekly capacity / flexible working days fields 50102-50104, GitHub username field 50105 (table extension 50100)
- `src/pageextension/ThymeResourceCard.PageExt.al` - Thyme group on the Resource Card (page extension 50100)
- `src/enum/` - Review verdict/severity and suggestion source/confidence/status and suggestion request status enums (50100-50105), project source type (50106), plan review subject and plan review request status (50107-50108), timesheet review request status (50109)
- `src/permissionset/` - `THYME AI AGENT` (50100), `THYME USER` (50101) and `THYME ADMIN` (50102); add new tables/pages to these
- `src/codeunit/ThymeConnectedAccounts.Codeunit.al` - GitHub username normalisation, and the resources API's `setGitHubUsername` action, which writes it after the row-level check using the indirect Resource modify permission THYME USER grants (codeunit 50106)
- `src/codeunit/ThymeTimeSheetActions.Codeunit.al` - Time Sheet approval workflow actions (codeunit 50100)
- `src/codeunit/ThymeInstall.Codeunit.al` / `ThymeUpgrade.Codeunit.al` - Create the Thyme Setup record on install / upgrade (codeunits 50101, 50102)
- `src/codeunit/ThymeCompanyInitialize.Codeunit.al` - Creates the Thyme Setup record in new companies (codeunit 50103)
- `src/codeunit/ThymeProjectCustomer.Codeunit.al` - Sets a project's Sell-to customer for the projects API and keeps its Bill-to customer, by skipping BC's Bill-to validation with a manually bound subscriber (codeunit 50109)
- `src/codeunit/ThymeRecordSecurity.Codeunit.al` - Row-level security for reviews, review lines, suggestions, suggestion requests, project source links, plan review requests, timesheet review requests, who may change a person's GitHub username and who may change the plan (`CanEditPlan`: exactly `JobPlanningLine.WritePermission()`, no admin or agent shortcut; used by day notes and exposed as `canEditPlan` on projects and resources), plus the shared time sheet admin check (codeunit 50104). The API pages call it in OnOpenPage (filters in FilterGroup 2) and in their insert/modify/delete triggers. Note: `FilterGroup(-1)` (cross-column OR) is NOT applied on API page reads, so OR conditions must be expressed with AND-only filters (see the `Hidden From User Filter` FlowFields).

## API Configuration

```
APIGroup = 'thyme'
APIPublisher = 'knowall'
APIVersion = 'v1.0'
```

Endpoints available at:
```
/api/knowall/thyme/v1.0/companies({id})/projects
/api/knowall/thyme/v1.0/companies({id})/jobTasks
/api/knowall/thyme/v1.0/companies({id})/timeSheets
/api/knowall/thyme/v1.0/companies({id})/timeSheetLines
/api/knowall/thyme/v1.0/companies({id})/timeSheetDetails
/api/knowall/thyme/v1.0/companies({id})/resources
/api/knowall/thyme/v1.0/companies({id})/timeEntries
/api/knowall/thyme/v1.0/companies({id})/jobPlanningLines
/api/knowall/thyme/v1.0/companies({id})/resourceUnitsOfMeasure
/api/knowall/thyme/v1.0/companies({id})/timesheetReviews
/api/knowall/thyme/v1.0/companies({id})/timesheetReviewLines
/api/knowall/thyme/v1.0/companies({id})/timeSuggestions
/api/knowall/thyme/v1.0/companies({id})/suggestionRequests
/api/knowall/thyme/v1.0/companies({id})/agentHeartbeats
/api/knowall/thyme/v1.0/companies({id})/projectSourceLinks
/api/knowall/thyme/v1.0/companies({id})/projectNotes
/api/knowall/thyme/v1.0/companies({id})/dayNotes
/api/knowall/thyme/v1.0/companies({id})/planReviews
/api/knowall/thyme/v1.0/companies({id})/planReviewLines
/api/knowall/thyme/v1.0/companies({id})/planReviewChanges
/api/knowall/thyme/v1.0/companies({id})/planReviewRequests
/api/knowall/thyme/v1.0/companies({id})/timesheetReviewRequests
/api/knowall/thyme/v1.0/companies({id})/thymeSetup
```

For user information, use BC's standard Automation API:
```
/api/microsoft/automation/v2.0/companies({id})/users
```

## Development Commands

- **Download symbols**: `Ctrl+Shift+P` → "AL: Download Symbols"
- **Build**: `Ctrl+Shift+B`
- **Deploy to sandbox**: `F5`

## CI/CD Deployment

GitHub Actions workflows deploy to BC Online (SaaS):

- `.github/workflows/deploy-sandbox.yml` - Triggered on push to `main`
- `.github/workflows/deploy-production.yml` - Triggered on release

**Important**: BC Online requires different functions than BC on-premises containers:
- Use `Publish-PerTenantExtensionApps` (not `Publish-BcContainerApp`)
- Use `Download-Artifacts` to get `alc.exe` for compilation
- Download symbols via BC Online dev API, not `Compile-AppInBcContainer`
- **Always bump the version in `app.json`** when making changes - BC won't update if version is unchanged

Secrets needed per environment:
- `BC_TENANT_ID` - Azure AD tenant ID
- `BC_CLIENT_ID` - App registration client ID
- `BC_CLIENT_SECRET` - App registration client secret

## Related Repositories

- [Thyme App](https://github.com/knowall-ai/thyme) - The main time tracking app
- Issue: https://github.com/knowall-ai/thyme/issues/41

## Testing

Use the `business-central-sandbox` MCP server to test custom endpoints after deployment.
