<p align="center">
  <img src="images/hero.svg" alt="Thyme BC Extension" width="100%">
</p>

<p align="center">
  <a href="https://github.com/knowall-ai/thyme">Thyme App</a> •
  <a href="https://thyme.knowall.ai">Website</a> •
  <a href="https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api">BC API Docs</a>
</p>

---

Custom Business Central API endpoints for the [Thyme](https://github.com/knowall-ai/thyme) time tracking app.

## Why This Extension?

The standard BC API v2.0 `/projects` endpoint only returns 4 fields:
- `id`, `number`, `displayName`, `lastModifiedDateTime`

This extension exposes additional fields needed by Thyme:
- Customer name and number
- Person responsible
- Project status and dates
- Job tasks
- Time sheets with approval status (Open, Submitted, Approved, Rejected)
- Resources with capacity information and per-person billable targets
- Posted time entries from Job Ledger
- AI timesheet reviews and AI time-entry suggestions (stored by this extension)

## API Endpoints

Once deployed, the APIs are available at:

```
.../api/knowall/thyme/v1.0/companies({companyId})/projects
.../api/knowall/thyme/v1.0/companies({companyId})/jobTasks
.../api/knowall/thyme/v1.0/companies({companyId})/timeSheets
.../api/knowall/thyme/v1.0/companies({companyId})/timeSheetLines
.../api/knowall/thyme/v1.0/companies({companyId})/timeSheetDetails
.../api/knowall/thyme/v1.0/companies({companyId})/resources
.../api/knowall/thyme/v1.0/companies({companyId})/timeEntries
.../api/knowall/thyme/v1.0/companies({companyId})/jobPlanningLines
.../api/knowall/thyme/v1.0/companies({companyId})/resourceUnitsOfMeasure
.../api/knowall/thyme/v1.0/companies({companyId})/timesheetReviews
.../api/knowall/thyme/v1.0/companies({companyId})/timesheetReviewLines
.../api/knowall/thyme/v1.0/companies({companyId})/timeSuggestions
.../api/knowall/thyme/v1.0/companies({companyId})/suggestionRequests
.../api/knowall/thyme/v1.0/companies({companyId})/projectSourceLinks
.../api/knowall/thyme/v1.0/companies({companyId})/planReviews
.../api/knowall/thyme/v1.0/companies({companyId})/planReviewLines
.../api/knowall/thyme/v1.0/companies({companyId})/planReviewChanges
.../api/knowall/thyme/v1.0/companies({companyId})/planReviewRequests
.../api/knowall/thyme/v1.0/companies({companyId})/timesheetReviewRequests
.../api/knowall/thyme/v1.0/companies({companyId})/agentHeartbeats
.../api/knowall/thyme/v1.0/companies({companyId})/dayNotes
.../api/knowall/thyme/v1.0/companies({companyId})/thymeSetup
```

For user information, use BC's standard Automation API:
```
.../api/microsoft/automation/v2.0/companies({companyId})/users
```

Base URL: `https://api.businesscentral.dynamics.com/v2.0/{tenant}/{environment}`

### Projects API

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `number` | Job No. |
| `description` | Project description |
| `sellToCustomerNo` | Sell-to customer number: who the work is for (the end client when the work comes through a partner). Changing it keeps the Bill-to customer and its terms, dimensions and planning line prices (BC's own validation would reset them); refused once the project has invoiced (Sale) entries |
| `sellToCustomerName` | Sell-to customer name. Read-only |
| `billToCustomerNo` | Bill-to customer number: who pays (the partner, for partner work) |
| `billToCustomerName` | Bill-to customer name |
| `personResponsible` | Project manager |
| `status` | Planning, Quote, Open, Completed |
| `startingDate` | Project start date |
| `endingDate` | Project end date |
| `currencyCode` | Currency of the project's prices (Job "Currency Code"); blank = the company's local currency (LCY). Read-only |
| `canEditSourceLinks` | True if the caller may add, change and remove the project's linked sources (a Thyme administrator or the project's manager). Read-only, per caller |
| `canEditPlan` | True if the caller may change the plan: has permission to write Job Planning Lines (being a Thyme administrator doesn't count on its own). Read-only, per caller, the same on every row |
| `lastModifiedDateTime` | Last modified timestamp |

### Job Tasks API

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `jobNo` | Parent job number |
| `jobTaskNo` | Task number |
| `description` | Task description |
| `jobTaskType` | Posting, Heading, Total, Begin-Total, End-Total |
| `lastModifiedDateTime` | Last modified timestamp |

### Time Sheets API

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `number` | Time sheet number |
| `startingDate` | Week starting date |
| `endingDate` | Week ending date |
| `resourceNo` | Resource number |
| `ownerUserId` | Owner user ID |
| `approverUserId` | Approver user ID |
| `openExists` | True if any line is Open |
| `submittedExists` | True if any line is Submitted |
| `rejectedExists` | True if any line is Rejected |
| `approvedExists` | True if any line is Approved |
| `lastModifiedDateTime` | Last modified timestamp |

**Bound Actions:**
- `POST /timeSheets({id})/Microsoft.NAV.submit` - Submit for approval
- `POST /timeSheets({id})/Microsoft.NAV.approve` - Approve time sheet
- `POST /timeSheets({id})/Microsoft.NAV.reject` - Reject time sheet
- `POST /timeSheets({id})/Microsoft.NAV.reopen` - Reopen for editing

### Time Sheet Lines API

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `timeSheetNo` | Parent time sheet number |
| `lineNo` | Line number |
| `timeSheetStartingDate` | Time sheet starting date |
| `type` | Resource, Job, Absence, Assembly Order, Service |
| `jobNo` | Job number (if type=Job) |
| `jobTaskNo` | Job task number (if type=Job) |
| `description` | Line description |
| `totalQuantity` | Total hours (sum of details) |
| `status` | Open, Submitted, Rejected, Approved |
| `approvedBy` | User who approved |
| `approvalDate` | Date approved |
| `posted` | Whether posted to ledger |
| `lastModifiedDateTime` | Last modified timestamp |

**Bound Actions:**
- `POST /timeSheetLines({id})/Microsoft.NAV.approve` - Approve line
- `POST /timeSheetLines({id})/Microsoft.NAV.reject` - Reject line
- `POST /timeSheetLines({id})/Microsoft.NAV.reopen` - Reopen for editing

### Time Sheet Details API

Daily hour entries for each time sheet line. One record per day with hours.

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `timeSheetNo` | Parent time sheet number |
| `timeSheetLineNo` | Parent line number |
| `date` | Date for this entry |
| `type` | Resource, Job, Absence, etc. |
| `resourceNo` | Resource number |
| `jobNo` | Job number |
| `jobTaskNo` | Job task number |
| `quantity` | Hours worked |
| `postedQuantity` | Hours already posted |
| `status` | Open, Submitted, Rejected, Approved |
| `posted` | Whether posted to ledger |
| `lastModifiedDateTime` | Last modified timestamp |

**Usage:** To log 4 hours on Jan 8 for a job:
```
POST /timeSheetDetails
{ "timeSheetNo": "TS00001", "timeSheetLineNo": 10000, "date": "2026-01-08", "quantity": 4 }
```

### Resources API

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `number` | Resource No. |
| `name` | Resource name |
| `searchName` | Search name for lookup |
| `type` | Person or Machine |
| `capacity` | Weekly hours capacity (FlowField) |
| `unitCost` | Cost per unit |
| `unitPrice` | Price per unit |
| `baseUnitOfMeasure` | Hour/Day units |
| `resourceGroupNo` | Resource group code |
| `blocked` | Whether resource is blocked |
| `privacyBlocked` | Privacy blocked flag |
| `countryRegionCode` | The person's Country/Region Code (blank = the company's), used by the plan review for public holidays. Read-only |
| `useTimeSheet` | Time sheet enabled |
| `timeSheetOwnerUserId` | Time sheet owner user ID |
| `timeSheetApproverUserId` | Time sheet approver user ID |
| `billableTargetPercent` | Person's billable target, 0-100 (only meaningful when `billableTargetSet` is `true`) |
| `billableTargetSet` | Whether the person has their own billable target; when `false`, use `defaultBillableTargetPercent` from `thymeSetup` |
| `weeklyCapacityHours` | Hours the person works per week (only meaningful when `weeklyCapacitySet` is `true`) |
| `weeklyCapacitySet` | Whether the person has their own weekly capacity; when `false`, use hours per day x 5 |
| `flexibleWorkingDays` | Whether the person works their weekly capacity on any days rather than fixed weekdays |
| `githubUsername` | The person's GitHub login, so the AI agent knows whose GitHub activity is whose (blank = not set) |
| `canEditConnectedAccounts` | Read-only, per caller: whether the caller may change `githubUsername` |
| `canEditPlan` | Read-only, per caller: whether the caller may change the plan (see `projects`) |
| `lastDateModified` | Last date modified |
| `lastModifiedDateTime` | Last modified timestamp |

**Billable targets:** `billableTargetSet` tells "not set" apart from a real 0% target.
Setting `billableTargetPercent` (including `0`) also sets `billableTargetSet` to `true`;
setting `billableTargetSet` to `false` clears the person's target so the company default applies.
Values outside 0-100 are rejected.
```
PATCH /resources({id})          { "billableTargetPercent": 60 }      // own target of 60%
PATCH /resources({id})          { "billableTargetSet": false }       // back to the company default
```

**Weekly capacity:** works like the billable target. Setting `weeklyCapacityHours` (including `0`)
also sets `weeklyCapacitySet` to `true`; setting `weeklyCapacitySet` to `false` clears it so Thyme
falls back to hours per day x 5. An explicit `0` keeps the person listed but not counted (for
example an AI agent). Values outside 0-168 are rejected.
```
PATCH /resources({id})          { "weeklyCapacityHours": 15, "flexibleWorkingDays": true }  // 2 days a week, any days
PATCH /resources({id})          { "weeklyCapacityHours": 0 }         // listed, not counted
PATCH /resources({id})          { "weeklyCapacitySet": false }       // back to hours per day x 5
```

**GitHub username:** a Thyme administrator (THYME ADMIN or *Time Sheet Admin.*) can set anyone's;
a person can set their own (the resource whose *Time Sheet Owner User ID* is them). Use the
`setGitHubUsername` action, which works without permission to modify resources (most people don't
have it). A profile URL or `@login` is accepted and stored as the login; anything that isn't a valid
GitHub login (letters, digits and single hyphens, no leading or trailing hyphen, at most 39
characters) is rejected. There is no Azure DevOps field: a person's DevOps user is their
Microsoft 365 sign-in, which comes from the time sheet owner.
```
POST /resources({id})/Microsoft.NAV.setGitHubUsername   { "githubUsername": "alex-contoso" }
POST /resources({id})/Microsoft.NAV.setGitHubUsername   { "githubUsername": "" }   // clear it
```

### Time Entries API

| Field | Description |
|-------|-------------|
| `id` | System GUID |
| `entryNo` | Ledger entry number |
| `jobNo` | Parent job number |
| `jobTaskNo` | Task number |
| `postingDate` | Entry posting date |
| `type` | Entry type (Resource) |
| `number` | Resource/item number |
| `description` | Entry description |
| `quantity` | Hours/units |
| `unitCost` | Cost per unit (LCY) |
| `totalCost` | Total cost (LCY) |
| `unitPrice` | Price per unit (LCY) |
| `totalPrice` | Total price (LCY) |
| `currencyCode` | Project currency of the entry; blank = LCY |
| `unitCostProjectCurrency` | Cost per unit, in the project currency |
| `totalCostProjectCurrency` | Total cost, in the project currency |
| `unitPriceProjectCurrency` | Price per unit, in the project currency |
| `totalPriceProjectCurrency` | Total price, in the project currency |
| `workTypeCode` | Work type classification |
| `entryType` | Usage or Sale |
| `documentNo` | Source document number |
| `lastModifiedDateTime` | Last modified timestamp |

**Note:** Time Entries are filtered to Resource-type entries only (employee time tracking).

### Currencies

A project can be priced in a currency other than the company's (the Job's **Currency Code**).
BC then keeps each amount in two currencies, and the endpoints expose both:

| Endpoint | Project currency | Local currency (LCY) |
|----------|------------------|----------------------|
| `jobPlanningLines` | `unitCost`, `totalCost`, `unitPrice`, `totalPrice` | `unitCostLCY`, `totalCostLCY`, `unitPriceLCY`, `totalPriceLCY` |
| `timeEntries` | `unitCostProjectCurrency`, `totalCostProjectCurrency`, `unitPriceProjectCurrency`, `totalPriceProjectCurrency` | `unitCost`, `totalCost`, `unitPrice`, `totalPrice` |

The older field names keep their original meaning for compatibility, which is why the unsuffixed
names differ between the two endpoints. Both endpoints, and `projects`, return `currencyCode`
(blank = LCY). Never add amounts from different columns together.

### Timesheet Reviews API

AI reviews of a time sheet. Written by an AI agent (insert/modify/delete), read by Thyme.
Unlike the other endpoints, this data is stored in the extension's own table.

| Field | Description |
|-------|-------------|
| `id` | System GUID (read-only) |
| `entryNo` | Auto-assigned entry number (read-only) |
| `timeSheetNo` | Time sheet reviewed (required) |
| `versionStamp` | Latest `lastModifiedDateTime` across the time sheet's lines and details when reviewed (required) |
| `verdict` | `Approve`, `Check` or `Query` (defaults to `Check`) |
| `summary` | Review summary (up to 2048 characters) |
| `reviewer` | Who wrote the review, e.g. the agent's name |
| `reviewedAt` | When reviewed (defaults to now) |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

**Usage:** Latest review for a time sheet:
```
GET /timesheetReviews?$filter=timeSheetNo eq 'TS00001'&$orderby=reviewedAt desc&$top=1
```
If the time sheet's lines or details have changed since `versionStamp`, the review is stale.
Deleting a review also deletes its review lines.

**Who can see reviews:** a review and its lines are returned only to the time sheet's owner and
approver, Thyme administrators and the AI agent (see [Row-level security](#row-level-security)).
Only the AI agent or a Thyme administrator can create, change or delete them.

### Timesheet Review Lines API

Individual findings within a review.

| Field | Description |
|-------|-------------|
| `id` | System GUID (read-only) |
| `reviewEntryNo` | Parent review's `entryNo` (required) |
| `lineNo` | Line number (assigned in steps of 10000 if 0 or omitted) |
| `timeSheetNo` | Time sheet number (filled from the review if omitted; must match it) |
| `timeSheetLineNo` | Time sheet line the finding is about (`0` = whole time sheet) |
| `severity` | `Info`, `Warning` or `Issue` |
| `note` | Finding text (up to 500 characters) |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

### Time Suggestions API

AI time-entry suggestions. Written by an AI agent, read and accepted/dismissed in Thyme.

| Field | Description |
|-------|-------------|
| `id` | System GUID (read-only) |
| `entryNo` | Auto-assigned entry number (read-only) |
| `resourceNo` | Resource the time is suggested for (required) |
| `date` | Date of the suggested time (required) |
| `quantity` | Hours |
| `jobNo` | Suggested job |
| `jobTaskNo` | Suggested job task (within `jobNo`) |
| `description` | Suggested line description |
| `source` | `Calendar`, `GitHub`, `DevOps` or `Other` |
| `sourceRef` | Source reference, e.g. meeting ID or pull request ID |
| `sourceUrl` | Link to the source |
| `evidence` | Short reasoning, e.g. "attended 11:31-12:02" |
| `confidence` | `High`, `Medium` or `Low` |
| `status` | `Pending` (default), `Accepted` or `Dismissed` |
| `timeSheetNo` | Time sheet the suggestion was accepted into |
| `timeSheetLineNo` | Time sheet line the suggestion was accepted into |
| `createdBy` | Who created the suggestion |
| `createdAt` | When created (defaults to now) |
| `actionedAt` | When accepted or dismissed (stamped automatically if left blank) |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

**Usage:** Pending suggestions for a resource's week:
```
GET /timeSuggestions?$filter=resourceNo eq 'R0010' and date ge 2026-01-05 and date le 2026-01-11 and status eq 'Pending'
```
A second suggestion with the same `resourceNo`, `source`, `sourceRef` and `date` is rejected,
so re-runs should `PATCH` the existing one (suggestions with a blank `sourceRef` are not checked).

**Who can see suggestions:** a suggestion is returned to, and can be changed by, only the
resource's time sheet owner (the user it's for), Thyme administrators and the AI agent. A user
can't create a suggestion for, or move one to, a resource whose time sheets they don't own.

### Suggestion Requests API

Ask the AI agent to generate time suggestions for a resource's week now, instead of waiting
for its scheduled runs (for example for a past week, or someone the schedule doesn't cover).
Thyme creates a request and polls it; the agent claims it, reports progress and finishes it.

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `entryNo` | Entry number (read-only) |
| `resourceNo` | Resource the suggestions are for |
| `fromDate` / `toDate` | Period to look at, at most 7 days; `fromDate` can't be in the future |
| `status` | `Requested` (always, on create), `Running`, `Done` or `Failed` |
| `progress` | What the agent is doing now, e.g. "Checking calendar for Tue 6 Oct" (≤ 250) |
| `createdCount` / `updatedCount` | Suggestions the run created and updated (set by the agent when done) |
| `errorMessage` | Why a `Failed` request failed, in words the requester can act on |
| `requestedBy` / `requestedAt` | Who asked and when (set by BC, read-only) |
| `startedAt` / `finishedAt` | Stamped when the agent claims it and when it finishes, if blank |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

**Usage:**
```
POST /suggestionRequests  { "resourceNo": "R0010", "fromDate": "2026-01-05", "toDate": "2026-01-11" }
GET  /suggestionRequests?$filter=resourceNo eq 'R0010' and fromDate eq 2026-01-05 and toDate eq 2026-01-11&$orderby=requestedAt desc&$top=1
GET  /suggestionRequests?$filter=status eq 'Requested'&$orderby=requestedAt     (agent: waiting requests)
```
Only one open (`Requested` or `Running`) request per resource and period is allowed. A second
is rejected, including by re-opening one with `PATCH`, so poll the open one instead. The agent claims a request with `PATCH` and the
row's ETag, so two pollers can't both run it.

**Who can request:** the resource's time sheet owner (for themselves), its time sheet approver,
Thyme administrators and the AI agent. The `resources` endpoint has a read-only
`canRequestSuggestions` flag that answers this for the caller, so Thyme can hide the button.
Only the AI agent can change or delete a request. An approver who requests suggestions for
someone sees the request's progress and counts, but not the suggestions themselves: those stay
visible only to the person they are for (and administrators), because they can include that
person's meeting subjects and other activity they haven't chosen to log yet.

### Agent Heartbeats API

When each AI agent was last seen, so Thyme can show whether it's online and disable
*Request suggestions* while it isn't (Thyme treats more than 5 minutes as offline).

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `agentName` | The agent (primary key), e.g. `POPPIE` |
| `lastSeenAt` | Stamped by BC with the server time on every insert and PATCH (whatever is sent) |
| `status` | What the agent is doing, e.g. "Idle", "Working on 1 request", "Paused" (≤ 250) |
| `version` | Optional agent version |

Every Thyme user can read it; only the AI agent (`THYME AI AGENT`) can create, change or delete.
The agent sends its own `lastSeenAt` with each `PATCH` so the record always changes.

### Project Source Links API

Which work belongs to a project: GitHub repos, Azure DevOps projects and repos, meeting subject keywords
and external attendee domains, optionally with the task to log that time against. The AI agent
reads them to map activity to projects when it suggests time entries (they replace the
`projects[]` rules in its config file). Thyme shows and edits them on the project page; in BC
they are the *Thyme Linked Sources* part on the Project Card.

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `jobNo` | Project (Job No.) |
| `lineNo` | Line number, assigned on insert. Read-only |
| `type` | `GitHubRepo`, `DevOpsProject`, `DevOpsRepo`, `MeetingKeyword` or `AttendeeDomain` |
| `value` | What to match (≤ 250), normalised on save, see below |
| `jobTaskNo` | Optional task; must be a Posting task of the project |
| `useMonthlyBlock` | Log against the posting task named after the month ("Block 7 - October"). With `jobTaskNo`, that task is the fallback until the month's block exists; without one, unticked lets the agent detect monthly blocks |
| `learned` | True when the AI agent added the link from approved time. Read-only |
| `createdBy`, `createdAt` | Who added the link and when. Read-only |

Values are normalised, so the agent matches them the same way however they were entered:

| Type | Accepts | Stored as |
|------|---------|-----------|
| `GitHubRepo` | `owner/repo`, `owner/*` (every repo of the owner), `owner/prefix-*`, or a URL such as `https://github.com/contoso/app/pull/12` | `contoso/app` (lower case) |
| `DevOpsProject` | `organisation/project`, a URL such as `https://dev.azure.com/contoso/Contoso%20App/_workitems` (or `https://contoso.visualstudio.com/Contoso App`), or just the project name | `contoso/Contoso App` (a bare name stays as typed) |
| `DevOpsRepo` | `organisation/project/repo` or `https://dev.azure.com/contoso/Contoso App/_git/app-api` | `contoso/Contoso App/app-api` |
| `MeetingKeyword` | A word or phrase in the meeting subject (at least 3 characters); a leading `Meeting: ` is dropped | As entered |
| `AttendeeDomain` | `contoso.com` or an attendee's address `someone@contoso.com` | `contoso.com` |

A DevOps repo link beats its project's link: pull requests in that repo (and work items linked
to them) go to the repo's project; other work in the DevOps project goes to the project link.

The same type and value can be linked to a project only once (case-insensitive); the same value
on two projects is allowed and makes the agent ask which one.

```
GET  /projectSourceLinks?$filter=jobNo eq 'PR00010'
POST /projectSourceLinks  { "jobNo": "PR00010", "type": "GitHubRepo", "value": "https://github.com/contoso/app", "jobTaskNo": "100" }
```

Every Thyme user can read every link. Thyme administrators and the project's manager (its
*Project Manager*, or the time sheet owner of its *Person Responsible* resource) can create,
change and delete them, in Thyme or in BC; anyone else gets an error. The AI agent
(`THYME AI AGENT`) can create links, which are always marked `learned`, and change or delete
only learned links. A person who edits a learned link adopts it (`learned` becomes false).
Deleting a project deletes its links.

### Day Notes API

Notes on particular days, e.g. "Company Off-Site", for the whole company or one person. Thyme
shows them on the Plan grid; the AI agent's plan review reads them.

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `entryNo` | Entry number (read-only) |
| `noteDate` | The day (required) |
| `resourceNo` | Blank = the whole company; otherwise just that person |
| `note` | The note (required, ≤ 100), e.g. "Company Off-Site" |
| `noProjectWork` | The day isn't available for project work (capacity 0 that day), e.g. an off-site or a holiday |
| `createdBy` / `createdAt` | Who added the note and when (set by BC, read-only) |
| `modifiedBy` / `modifiedAt` | Who last changed it and when (set by BC, read-only) |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

**Usage:**
```
GET  /dayNotes?$filter=noteDate ge 2026-10-19 and noteDate le 2026-11-15
POST /dayNotes  { "noteDate": "2026-10-22", "note": "Company Off-Site", "noProjectWork": true }
POST /dayNotes  { "noteDate": "2026-10-23", "resourceNo": "R0010", "note": "Client workshop" }
```

Every Thyme user can read day notes. People who may change the plan (permission to write Job
Planning Lines) can create, change and delete them; anyone else, including a Thyme administrator
or the AI agent without that permission, gets "You don't have permission to change day notes." The read-only `canEditPlan`
flag on `projects` and `resources` answers this for the caller.

### Plan Reviews API

AI reviews of the plan (Resource planning lines, as on Thyme's Plan grid), one per
**subject-week**: a person's week (`subjectType` `Resource`, `subjectNo` = resource) or a
project's week (`Project`, `subjectNo` = project). Written by the AI agent; Thyme shows them on
the Plan grid.

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `entryNo` | Entry number (read-only) |
| `subjectType` | `Resource` or `Project` |
| `subjectNo` | Resource No. or Job No. |
| `weekStart` | The Monday the week starts on |
| `planHash` | Lowercase hex SHA-256 of the subject-week's planning lines when reviewed; `PENDING` while the agent is still writing the findings |
| `verdict` | `Approve` ("Looks good"), `Check` ("Worth a check", the default) or `Query` ("Needs changes") |
| `summary` | Summary (≤ 2048) |
| `reviewer` | Who reviewed, e.g. "Poppie" |
| `reviewedAt` | When (defaults to now) |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

**Plan hash:** for each planning line of the subject-week (`type` Resource, quantity > 0) build
`jobNo|jobTaskNo|resourceNo|planningDate(YYYY-MM-DD)|hours`, hours rounded to 2 decimals and
written with exactly 2 (`7.25`, `0.50`); sort ascending, join with `\n` and hash the UTF-8. An empty
week hashes the empty string. A review whose `planHash` differs from the current one is out of date.

**Findings** (`planReviewLines`): `reviewEntryNo`, `lineNo` (assigned in steps of 10000 if 0),
`severity` (`Info`, `Warning`, `Issue`), `check` (`ROUNDING`, `OVER_CAPACITY`, `BILLABLE_TARGET`,
`CALENDAR`, `BUDGET_BURN`, `PLAN_SHAPE`, `OUTSIDE_PROJECT_DATES` or `OTHER`), and optionally
`planningDate` (a day in the review's week; blank = the whole week), `jobNo`, `resourceNo`, plus
`note` (≤ 500).

**Proposed changes** (`planReviewChanges`): `reviewEntryNo`, `reviewLineNo` (the finding),
`changeNo` (assigned 1, 2, 3... if 0), `jobNo`, `jobTaskNo`, `resourceNo`, `planningDate`,
`currentHours` (what the cell held when the agent looked) and `proposedHours` (a multiple of 0.25;
0 = remove the cell's planning lines). A change must be on a day of the review's week and, for a
resource-week, for that resource (for a project-week, that project).

**Applying a finding** (Thyme's *Apply change*): `POST /planReviewLines({id})/Microsoft.NAV.applyChanges`
with no body applies all of the finding's changes in one transaction, or none. Only a user who may
change the plan (`canEditPlan`: permission to write Job Planning Lines) can. The review, the finding,
its changes and each affected project are locked, and the changes are read once. A finding that
changes the same cell twice is refused. Every cell (project, task, resource and day; Resource lines
with a quantity) is checked first: it must be empty or hold exactly one Budget line in the
resource's base unit of measure, and its hours must still be `currentHours` (within 0.005). Each
cell is checked again just before it's written. Then each cell gets `proposedHours`: 0 deletes the line, an existing line gets the new quantity, and an empty cell
gets a new Budget line. Quantities are converted with Thyme's rule: if the resource has an `HOUR`
unit of measure whose factor isn't 1, the base unit is a day of that many hours (or 1/factor when
below 1); otherwise it's an hour. The finding's read-only `appliedAt` / `appliedBy` are stamped.
Any error rolls everything back:

| Problem | Error |
|---------|-------|
| The caller may not change the plan (`canEditPlan` is false) | `You don't have permission to change the plan.` |
| The finding has no changes | `Finding <lineNo> of plan review <entryNo> has no changes to apply.` |
| Two of the finding's changes are for the same cell | `Edit this cell by hand: the finding changes the same cell twice.` |
| A cell has more than one planning line | `Edit this cell by hand: <resource> has <n> planning lines on <date> for project <job>, task <task>.` |
| A cell's one line isn't a Budget line | `Edit this cell by hand: the planning line for <resource> on <date> for project <job>, task <task> is a <line type> line, not a Budget line.` |
| A cell's line is in a unit other than the resource's base unit | `Edit this cell by hand: the planning line for <resource> on <date> for project <job>, task <task> uses unit <code>.` |
| A cell's hours differ from `currentHours` by 0.005 or more, or the cell changed between the check and the write | `The plan changed since Poppie looked. Ask her to re-review.` |

```
GET /planReviews?$filter=subjectType eq 'Resource' and weekStart ge 2026-10-19 and weekStart le 2026-11-09
GET /planReviews?$filter=subjectType eq 'Resource' and subjectNo eq 'R0010' and weekStart eq 2026-10-19&$orderby=reviewedAt desc&$top=1
GET /planReviewLines?$filter=reviewEntryNo eq 42
GET /planReviewChanges?$filter=reviewEntryNo eq 42
POST /planReviewLines({id})/Microsoft.NAV.applyChanges
```

Deleting a review deletes its findings and changes; deleting a finding deletes its changes. Once a
review has findings or changes, its `subjectType`, `subjectNo` and `weekStart` can't be changed.
Every Thyme user can read plan reviews, findings and changes (there is no row-level security
on them); only the AI agent or a Thyme administrator can write them (an administrator through
these API pages only: `THYME ADMIN` grants indirect insert, modify and delete).

### Plan Review Requests API

Ask the AI agent to review a subject-week now (*Ask Poppie to re-review* in Thyme), instead of
waiting for its Thursday sweep. Works like `suggestionRequests`.

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `entryNo` | Entry number (read-only) |
| `subjectType` / `subjectNo` / `weekStart` | The subject-week, as on `planReviews` (`weekStart` a Monday) |
| `status` | `Requested` (always, on create), `Running`, `Done` or `Failed` |
| `progress` | What the agent is doing now (≤ 250) |
| `errorMessage` | Why a `Failed` request failed (≤ 250) |
| `requestedBy` / `requestedAt` | Who asked and when (set by BC, read-only) |
| `startedAt` / `finishedAt` | Stamped when the agent claims it and when it finishes, if blank |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

```
POST /planReviewRequests  { "subjectType": "Resource", "subjectNo": "R0010", "weekStart": "2026-10-19" }
GET  /planReviewRequests?$filter=status eq 'Requested'&$orderby=requestedAt     (agent: waiting requests)
```
Only one open (`Requested` or `Running`) request per subject-week; a second is rejected,
including by re-opening one with `PATCH`. Every Thyme user can read requests. People who may
change the plan (permission to write Job Planning Lines; being a Thyme administrator or the AI
agent doesn't count on its own) can create them (`canEditPlan` on `projects` and `resources` answers this for the caller); only the
AI agent can change or delete one.

### Timesheet Review Requests API

Ask the AI agent to review a time sheet again now (*Ask Poppie to look again* in Thyme), instead
of waiting for the time sheet to be resubmitted. Works like `planReviewRequests`.

| Field | Description |
|-------|-------------|
| `id` | SystemId (GUID) |
| `entryNo` | Entry number (read-only) |
| `timeSheetNo` | The time sheet to review (Time Sheet Header No.) |
| `status` | `Requested` (always, on create), `Running`, `Done` or `Failed` |
| `progress` | What the agent is doing now (≤ 250) |
| `errorMessage` | Why a `Failed` request failed (≤ 250) |
| `requestedBy` / `requestedAt` | Who asked and when (set by BC, read-only) |
| `startedAt` / `finishedAt` | Stamped when the agent claims it and when it finishes, if blank |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

```
POST /timesheetReviewRequests  { "timeSheetNo": "TS00042" }
GET  /timesheetReviewRequests?$filter=timeSheetNo eq 'TS00042'&$orderby=requestedAt desc&$top=1   (Thyme: latest request)
GET  /timesheetReviewRequests?$filter=status eq 'Requested'&$orderby=requestedAt                  (agent: waiting requests)
```
Only one open (`Requested` or `Running`) request per time sheet; a second is rejected, including
by re-opening one with `PATCH`. The time sheet's owner and approver, Thyme administrators and the
AI agent (the people who see its reviews) can read and create requests for it; only the AI agent
can change or delete one. The agent writes the new review to `timesheetReviews` as usual.

### Row-level security

The reviews, review lines, suggestions, suggestion requests and timesheet review requests endpoints only return records the caller may see.
Records outside that scope are left out of lists and `$filter` results, and `GET`, `PATCH` or
`DELETE` by `id` returns 404, as if the record didn't exist.

| Caller | Reviews and review lines | Suggestions | Suggestion requests | Timesheet review requests |
|--------|--------------------------|-------------|---------------------|---------------------------|
| AI agent (`THYME AI AGENT`) | All; can write | All; can write | All; can write | All; can write |
| Thyme administrator: *Time Sheet Admin.* in User Setup, or `THYME ADMIN` | All; can write (needs table permission) | All; can write (needs table permission) | All; can create | All; can create |
| Time sheet owner or approver | Reviews of time sheets they own or approve, whatever their status; read only | Suggestions for resources whose time sheets they own; can change those (approvers: none) | Requests for resources whose time sheets they own or approve; can create | Requests for time sheets they own or approve; can create |
| Anyone else | None | None | None | None |

The permission sets count whether they are assigned directly or through a security group.
`SUPER` on its own does not bypass these rules, so give a superuser who should see everything
`THYME ADMIN` or *Time Sheet Admin.* The owner and approver are read live from the time sheet,
and the suggestion owner from the resource card, so reassigning them takes effect immediately.
Reviews of time sheets that no longer exist (for example after archiving) are visible only to
administrators and the AI agent. The rules live in the `Thyme Record Security` codeunit (50104).

### Thyme Setup API

Company-wide Thyme settings: a single record that can be read and updated, but not created or deleted.

| Field | Description |
|-------|-------------|
| `id` | System GUID (read-only) |
| `defaultBillableTargetPercent` | Billable target, 0-100, for people without their own target (defaults to 75) |
| `lastModifiedDateTime` | Last modified timestamp (read-only) |

**Usage:**
```
GET   /thymeSetup                  // returns one record
PATCH /thymeSetup({id})            { "defaultBillableTargetPercent": 70 }
```
The record is created on install, on upgrade and when a company is initialised. If it is ever
missing, `GET` returns an empty list for read-only callers until a user with write permission
(`THYME ADMIN`) opens the Thyme Setup page or calls `GET /thymeSetup`, which creates it.
Updating it needs the `THYME ADMIN` permission set.

### Users (Standard BC API)

For user information, use BC's built-in [Automation API](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/api/dynamics_user_get):

```
GET /api/microsoft/automation/v2.0/companies({companyId})/users
```

Returns `userSecurityId`, `userName`, `displayName`, `state`, `expiryDate`, `contactEmail`.

**Usage:** Match the user's `userName` to a Resource's `timeSheetOwnerUserId` field.

## Development Setup

### Prerequisites

1. [VS Code](https://code.visualstudio.com/)
2. [AL Language extension](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al)
3. Access to a Business Central sandbox environment

### Download Symbols

1. Open the project in VS Code
2. Press `Ctrl+Shift+P` → "AL: Download Symbols"
3. Enter your BC sandbox credentials

### Build

Press `Ctrl+Shift+B` to build the `.app` file.

### Deploy via GitHub Actions (Recommended)

The repo includes CI/CD workflows for both environments:

| Workflow | Trigger | Target |
|----------|---------|--------|
| `deploy-sandbox.yml` | Push to `main` | Sandbox (Contoso Ltd) |
| `deploy-production.yml` | Release published | Production (KnowAll Ltd) |

**GitHub Environments Required:**

Create two environments in Settings → Environments:

1. **Sandbox** - No protection rules
2. **Production** - Add required reviewers for safety

**Secrets (per environment):**

| Secret | Description |
|--------|-------------|
| `BC_TENANT_ID` | Your Azure AD tenant ID |
| `BC_CLIENT_ID` | Azure AD app registration client ID |
| `BC_CLIENT_SECRET` | Azure AD app registration client secret |

**Azure AD App Setup:**

1. Register an app in Azure AD
2. Grant API permissions: `Dynamics 365 Business Central` → `API.ReadWrite.All` and `Automation.ReadWrite.All`
3. Add redirect URI: `https://businesscentral.dynamics.com/OAuthLanding.htm`
4. Create a client secret
5. In BC Admin Center → Microsoft Entra Apps → Authorize the app
6. **Critical**: In Business Central → search "Microsoft Entra applications" → add the app with permission sets `D365 AUTOMATION` and `EXTEN. MGT. - ADMIN`

**Permission sets for the stored data:** the reviews, suggestions and Thyme Setup live in this extension's own tables, which the standard D365 permission sets don't cover. Assign:

| Permission set | Assign to | Grants |
|----------------|-----------|--------|
| `THYME AI AGENT` | The AI agent's Microsoft Entra application | Full access to reviews, review lines, suggestions, suggestion requests, its heartbeat, plan reviews (with findings and changes), plan review requests and timesheet review requests; reads day notes, and changes them (through `dayNotes`) only if it also has permission to write Job Planning Lines (includes `THYME USER`) |
| `THYME USER` | Thyme users | Read reviews and review lines; read and update suggestions; read and create suggestion requests; read agent heartbeats; read plan reviews, their findings and changes; read and create plan review requests (checked in code); read and create timesheet review requests for time sheets they own or approve (checked in code); read day notes, and change them through `dayNotes` with permission to write Job Planning Lines; read the default billable target; run the Thyme API pages |
| `THYME ADMIN` | Thyme administrators | Everything in `THYME USER`, plus changing the default billable target (Thyme Setup) and seeing every user's reviews and suggestions; writing plan reviews, their findings and changes through the plan review APIs (indirect permission) |

Users with `THYME USER` only see reviews of time sheets they own or approve and their own
suggestions; see [Row-level security](#row-level-security).

See [docs/INSTALLATION.adoc](docs/INSTALLATION.adoc) for detailed setup instructions.

### Deploy via VS Code

1. Configure `launch.json` with your sandbox environment name
2. Press `F5` to publish directly to sandbox

### Deploy to Production

1. Build the `.app` file
2. Go to BC Admin Center → Extensions → Upload Extension
3. Or use PowerShell: `Publish-NAVApp`

## Project Structure

```
thyme-bc-extension/
├── app.json                                    # Extension manifest
├── src/
│   ├── api/
│   │   ├── ThymeProjectsAPI.Page.al            # Projects endpoint (page 50100)
│   │   ├── ThymeJobTasksAPI.Page.al            # Job Tasks endpoint (page 50101)
│   │   ├── ThymeTimeSheetAPI.Page.al           # Time Sheets (page 50102)
│   │   ├── ThymeTimeSheetLineAPI.Page.al       # Time Sheet Lines (page 50103)
│   │   ├── ThymeResourcesAPI.Page.al           # Resources endpoint (page 50104)
│   │   ├── ThymeTimeEntriesAPI.Page.al         # Time Entries endpoint (page 50105)
│   │   ├── ThymeTimeSheetDetailAPI.Page.al     # Time Sheet Details (page 50106)
│   │   ├── ThymeJobPlanningLinesAPI.Page.al    # Job Planning Lines (page 50107)
│   │   ├── ThymeResourceUnitsOfMeasureAPI.Page.al # Resource Units of Measure (page 50108)
│   │   ├── ThymeTimesheetReviewsAPI.Page.al    # Timesheet Reviews (page 50109)
│   │   ├── ThymeTimesheetReviewLinesAPI.Page.al # Timesheet Review Lines (page 50110)
│   │   ├── ThymeTimeSuggestionsAPI.Page.al     # Time Suggestions (page 50111)
│   │   ├── ThymeSetupAPI.Page.al               # Thyme Setup (page 50112)
│   │   ├── ThymeProjectSourceLinksAPI.Page.al  # Project Source Links (page 50116)
│   │   ├── ThymePlanReviewsAPI.Page.al         # Plan Reviews (page 50118)
│   │   ├── ThymePlanReviewLinesAPI.Page.al     # Plan Review Lines (page 50119)
│   │   ├── ThymePlanReviewChangesAPI.Page.al   # Plan Review Changes (page 50120)
│   │   ├── ThymePlanReviewRequestsAPI.Page.al  # Plan Review Requests (page 50121)
│   │   ├── ThymeTimesheetReviewRequestsAPI.Page.al # Timesheet Review Requests (page 50124)
│   │   └── ThymeDayNotesAPI.Page.al            # Day Notes (page 50122)
│   ├── page/
│   │   ├── ThymeSetup.Page.al                  # Thyme Setup card (page 50113)
│   │   └── ThymeProjectSourceLinks.Page.al     # Linked sources part on the Project Card (page 50117)
│   ├── table/                                  # Review, review line, suggestion, Thyme Setup, requests, heartbeats, source links (tables 50100-50106), plan reviews, lines, changes, requests (tables 50107-50110), day notes (table 50111), timesheet review requests (table 50113)
│   ├── tableextension/                         # Resource billable target and capacity fields (50100)
│   ├── pageextension/                          # Thyme group on the Resource Card (50100), linked sources on the Project Card (50101)
│   ├── enum/                                   # Verdict, severity, suggestion, request status, source type, plan review subject and request status, timesheet review request status enums (enums 50100-50109)
│   ├── permissionset/                          # THYME AI AGENT, THYME USER, THYME ADMIN (50100-50102)
│   └── codeunit/
│       ├── ThymeTimeSheetActions.Codeunit.al   # Approval workflow actions (codeunit 50100)
│       ├── ThymeInstall.Codeunit.al            # Creates Thyme Setup on install (codeunit 50101)
│       ├── ThymeUpgrade.Codeunit.al            # Creates Thyme Setup on upgrade (codeunit 50102)
│       ├── ThymeRecordSecurity.Codeunit.al     # Row-level security for reviews and suggestions, source link edit rights (codeunit 50104)
│       ├── ThymeProjectSourceLinkEvents.Codeunit.al # Deletes a project's source links with it (codeunit 50105)
│       └── ThymeCompanyInitialize.Codeunit.al  # Creates Thyme Setup in new companies (codeunit 50103)
└── .vscode/
    ├── launch.json                             # Debug configuration
    └── settings.json                           # Editor settings
```

## Documentation

- [Installation Guide](docs/INSTALLATION.adoc) - Complete setup instructions
- [Deployment Guide](docs/DEPLOYMENT.adoc) - Sandbox, production, and versioning
- [Solution Design](docs/SOLUTION_DESIGN.adoc) - Architecture and API design
- [Troubleshooting](docs/TROUBLESHOOTING.adoc) - Common issues and solutions
- [Testing](docs/TESTING.adoc) - How to test the API
- [Changelog](CHANGELOG.md) - Release notes

## Related

- [Thyme Time Tracking App](https://github.com/knowall-ai/thyme)
- [Issue #41 - BC API Limitation](https://github.com/knowall-ai/thyme/issues/41)
- [Microsoft BC Custom API Docs](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api)
