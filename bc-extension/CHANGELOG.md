# Changelog

Notable changes to the Thyme BC Extension. Versions match `app.json`.

## 1.27.0.4

### Fixed

- `sellToCustomerName` on `projects` is now the customer's current name, looked up by
  `sellToCustomerNo`. Business Central copies the customer's name onto a project when it's set and
  doesn't refresh it after the customer is renamed, so projects for one customer could return
  different, older names. No project data changes.

## 1.27.0.3

### Added

- `sellToCustomerNo` and `sellToCustomerName` on `projects`: the project's Sell-to customer, Business
  Central's standard field for who the work is for. With partner work, Sell-to is the end client and
  Bill-to (`billToCustomerNo`) the partner who pays, so the client no longer has to be in the
  project's name. `sellToCustomerName` is read-only.
- Changing `sellToCustomerNo` keeps the project's Bill-to customer (codeunit 50109
  `Thyme Project Customer`). BC's own Sell-to validation also validates Bill-to, which copies the new
  customer's contact, payment terms, price groups and default dimensions onto the project and
  re-prices its planning lines, losing prices set by hand; setting Bill-to back repeats it. The
  codeunit runs BC's Sell-to validation, with its checks (refused once the project has invoiced (Sale)
  ledger entries), and skips the Bill-to validation through a manually bound subscriber, so only the
  Sell-to fields change. Posted entries and time sheets aren't touched. A project with no Bill-to
  customer gets the Sell-to customer as Bill-to, as in BC, and clearing the Sell-to customer is BC's
  own validation, which clears the Bill-to customer too (a project with a Bill-to but no Sell-to
  customer can't be invoiced). Send `billToCustomerNo` only to change
  the Bill-to customer: BC then applies that customer's terms and re-prices the planning lines.
- `THYME USER` can run the codeunit; changing a project still needs Business Central's own
  permission to modify projects.

## 1.26.0.0

### Added

- `timesheetReviewRequests` (page 50124, table 50113 `Thyme Timesheet Review Request`, status
  enum 50109): ask the agent to review a time sheet again now (*Ask Poppie to look again* in
  Thyme), instead of waiting for the time sheet to be resubmitted. Works like
  `planReviewRequests`: `POST { "timeSheetNo" }` creates a `Requested` request (`requestedBy` /
  `requestedAt` set by BC), one open (`Requested` or `Running`) request per time sheet (a second is
  rejected, including by re-opening one), the agent claims it (`Running`), reports `progress` and
  finishes it as `Done` or `Failed` (`errorMessage`); `startedAt` / `finishedAt` are stamped if blank.
  Filter by `timeSheetNo` and `status`.
- Who can do what: the same people who see the time sheet's reviews (its owner and approver, Thyme
  administrators and the AI agent) read requests for it and can create one; only the AI agent changes
  or deletes a request. `THYME USER` has direct read and only indirect insert (`Ri`), so requests are
  created only through the API page and its check; `THYME AI AGENT` has full access.

## 1.25.0.1

### Added

- `projectNotes` API (page 50123, temporary table 50112, codeunit 50108 `Thyme Project Notes`): a
  project's Notes, the same ones as the Notes factbox on the Project card in Business Central
  (Record Links of type Note), newest first, with who wrote each and when.
  `GET /projectNotes?$filter=jobNo eq 'PR00010'` lists them (the `jobNo` filter is required);
  `POST /projectNotes { "jobNo", "note" }` adds one as the signed-in user, so it shows in Business
  Central too. Anyone who can read the project can read and add its notes; they aren't changed or
  deleted through the API. `THYME USER` can run the page and codeunit (the codeunit has the indirect
  Record Link permission).

## 1.24.0.0

### Added

- `applyChanges` bound action on `planReviewLines`
  (`POST /planReviewLines({id})/Microsoft.NAV.applyChanges`, no body): applies all of a finding's
  proposed changes to the Resource planning lines in one transaction (codeunit 50107
  `Thyme Plan Review Apply`), so Thyme's *Apply change* is all or nothing. Only a user who may change
  the plan (`canEditPlan`) can apply. The review, the finding, its changes and the affected projects
  are locked and the changes read once; a finding that changes the same cell twice is refused.
  Every cell is checked first: it must be empty or hold exactly one Budget line in the resource's
  base unit, and still hold the change's `currentHours`; then each cell is re-checked and gets its
  `proposedHours` (0 deletes the line, an empty cell gets a new Budget line), written to exactly the
  line the check found and confirmed afterwards (a line added meanwhile counts as the plan
  changing). Any error rolls the lot back.
- `jobPlanningLines` takes an update lock on the line's project when it inserts, modifies or
  deletes a line, the same lock `applyChanges` takes, so the two change a project's plan one at a
  time.
- `appliedAt` / `appliedBy` on `planReviewLines` (read-only, fields 9-10 on table 50108): stamped
  when the finding's changes are applied, so Thyme can show it as applied. THYME USER gains indirect
  modify on findings for the stamp.

## 1.23.0.0

### Added

- AI plan reviews: the agent reviews the plan (Resource planning lines, i.e. Thyme's Plan grid)
  one subject-week at a time, a person's week (`Resource`) or a project's week (`Project`), and
  Thyme shows the verdict on the Plan grid.
  - `planReviews` (page 50118, table 50107 `Thyme Plan Review`, subject enum 50107): verdict
    (Approve, Check, Query), summary, reviewer and `planHash`, the SHA-256 of the subject-week's
    planning lines when reviewed (`PENDING` while the agent writes the findings), so Thyme can
    tell a review is out of date. `weekStart` must be a Monday.
  - `planReviewLines` (page 50119, table 50108): the findings, each with a severity, the check
    that raised it, and optionally the day, project and resource it is about.
  - `planReviewChanges` (page 50120, table 50109): changes a finding proposes to planning-line
    cells, in hours (`currentHours` → `proposedHours`, a multiple of 0.25; 0 removes the cell),
    applied together with Thyme's *Apply change*. A change must be in the review's week and for
    its resource or project.
  - Deleting a review deletes its findings and changes; deleting a finding deletes its changes.
    Once a review has findings or changes, its subject and week can't be changed.
- `planReviewRequests` (page 50121, table 50110, status enum 50108): ask the agent to review a
  subject-week now. Works like `suggestionRequests`: one open request per subject-week, the agent
  claims it (`Running`), reports `progress` and finishes it as `Done` or `Failed`.
- Who can do what: every Thyme user reads plan reviews, findings, changes and requests. Only the AI
  agent or a Thyme administrator writes reviews, findings and changes (`CheckCanWritePlanReviews`;
  `THYME ADMIN` grants indirect insert, modify and delete, so administrators write them only through the API pages).
  Only people who may change the plan (permission to write Job Planning Lines; no Thyme
  administrator or AI agent shortcut) can request a review; only the AI agent changes or deletes a
  request.
- Thyme uses `canEditPlan` (1.22.0.0) on `projects` and `resources` to show *Apply change* and
  *Ask Poppie to re-review* only to people who may use them.
- `countryRegionCode` on `resources` (read-only): the person's Country/Region Code (blank = the
  company's), so the plan review checks public holidays for the right country.

## 1.22.0.0

### Added

- `dayNotes` endpoint (page 50122, table 50111 `Thyme Day Note`): notes on particular days, e.g.
  "Company Off-Site", for the whole company (blank `resourceNo`) or one person, shown on Thyme's
  Plan grid. `noProjectWork` marks the day as unavailable for project work (capacity 0), so Thyme
  counts hours planned on it as over capacity and the AI agent's plan review treats it like a
  public holiday. BC stamps `createdBy`/`createdAt` and `modifiedBy`/`modifiedAt`.
- Every Thyme user can read day notes. People who may change the plan (permission to write Job
  Planning Lines) can create, change and delete them; anyone else, including a Thyme administrator
  or the AI agent without that permission, gets "You don't have permission to change day notes."
- `canEditPlan` on `projects` and `resources` (read-only, per caller): whether the caller may
  change the plan, so Thyme shows the day-note edit controls only to people who may use them.

## 1.21.0.1

### Added

- Per-person GitHub username on Resource: "Thyme GitHub Username" (field 50105, Text[39]), so the
  AI agent knows whose GitHub pull requests and issues are whose, in every company, without its
  own config. Validated as a GitHub login (letters, digits and single hyphens, no leading or
  trailing hyphen); a profile URL or `@login` is stored as the login. (A person's Azure DevOps user
  is their Microsoft 365 sign-in, so it isn't stored.)
- `githubUsername` on `resources`, plus `canEditConnectedAccounts` (read-only, per caller).
- Who can change it: a Thyme administrator for anyone, and a person for their own resource (the
  one whose Time Sheet Owner User ID is them), checked in the field's OnValidate (codeunit 50104).
- `setGitHubUsername` bound action on `resources`: sets it without permission to modify resources
  (codeunit 50106 writes the field after the check, using an indirect modify permission on Resource that THYME USER now grants), so people can set
  their own from Thyme.
- GitHub Username in the Thyme group on the Resource Card.

## 1.20.0.2

### Added

- `projectSourceLinks` endpoint (page 50116, table 50106 `Thyme Project Source Link`, enum 50106):
  a project's linked sources, i.e. the GitHub repos, Azure DevOps projects and repos, meeting keywords and
  attendee domains whose time belongs to it, each optionally with a posting task and *Use Monthly
  Block*. The AI agent reads them to map activity to projects, replacing the `projects[]` rules
  in its config file, per company. Values are normalised on save (a GitHub URL becomes
  `owner/repo`, `owner/*` for a whole owner; a DevOps URL becomes `organisation/project`, or
  `organisation/project/repo` for a `DevOpsRepo` link; an e-mail address becomes its domain).
- Every Thyme user can read them. Thyme administrators and the project's manager (*Project
  Manager*, or the time sheet owner of the *Person Responsible*) can change them. The AI agent can
  add links it learned from approved time (`learned` = true) and change or remove only those.
- *Thyme Linked Sources* part on the Project Card (page 50117, page extension 50101), so the
  links can be edited in BC too.
- `canEditSourceLinks` on `projects` (read-only, per caller), so Thyme shows the edit controls only
  to people who may use them.
- Deleting a project deletes its linked sources (codeunit 50105).

## 1.19.0.0

### Added

- Per-person weekly capacity on Resource: "Thyme Weekly Capacity (Hours)" (field 50102, 0-168)
  and "Thyme Weekly Capacity Set" (field 50103), so part-timers are measured against the hours
  they actually work. "Not set" falls back to hours per day x 5; an explicit 0 keeps the person
  listed in Thyme but leaves them out of team capacity, completion and targets (for example AI
  agents). Entering hours sets the flag; clearing the flag resets the hours.
- "Thyme Flexible Working Days" (field 50104): the person works their weekly capacity on any
  days rather than fixed weekdays, so Thyme and the timesheet review judge the week as a whole.
- `weeklyCapacityHours`, `weeklyCapacitySet` and `flexibleWorkingDays` on `resources`, editable
  via PATCH with the same Resource permissions as the billable target. All three show in the
  Thyme group on the Resource Card.

### Fixed

- `billableTargetPercent` outside 0-100 is now rejected through the API too (MinValue/MaxValue
  only applied on pages); the same check guards `weeklyCapacityHours` (0-168).

## 1.18.0.0

### Added

- `suggestionRequests` endpoint (page 50114, table 50104 `Thyme Suggestion Request`, enum 50105):
  ask the AI agent to generate time suggestions for a resource and period (at most 7 days, not
  in the future) now, instead of waiting for its scheduled runs. Thyme creates the request and
  polls it; the agent claims it (`Running`), reports `progress`, and finishes it as `Done` with
  `createdCount`/`updatedCount` or `Failed` with an `errorMessage`. One open request per
  resource and period.
- Who can request: the resource's time sheet owner and approver, Thyme administrators and the AI
  agent. They can also read those requests. Only the AI agent can change or delete one.
- `canRequestSuggestions` on `resources` (read-only, per caller), so Thyme can show the
  *Request suggestions* button only to people who may use it.
- `agentHeartbeats` endpoint (page 50115, table 50105 `Thyme Agent Heartbeat`): when each AI
  agent was last seen (stamped by BC), its status text and version. Every Thyme user can read it,
  so Thyme can show whether the agent is online and disable requests while it isn't. Only the AI
  agent writes it.

### Unchanged on purpose

- Suggestions themselves stay visible only to the person they're for, administrators and the
  AI agent. An approver who requests them for someone sees the request's progress and counts,
  not the suggestions.

## 1.15.0.1

### Security

- Row-level security on `timesheetReviews`, `timesheetReviewLines` and `timeSuggestions`. A review
  and its lines are visible only to the time sheet's owner and approver, Thyme administrators
  (*Time Sheet Admin.* in User Setup, or the `THYME ADMIN` permission set) and the AI agent
  (`THYME AI AGENT`). A suggestion is visible to, and changeable by, only its resource's time
  sheet owner, administrators and the AI agent. Records outside the caller's scope are left out
  of lists and `$filter` results, and return 404 by `id`.
- Only the AI agent or a Thyme administrator can create, change or delete reviews and review
  lines. A user can't create a suggestion for, or move one to, a resource they don't own.
- New `Thyme Record Security` codeunit (50104) holds these rules. The time sheet admin check
  used when creating time sheets through the API now comes from it too, so both stay in step.
- `SUPER` on its own no longer sees other users' reviews and suggestions through the API.
  Assign `THYME ADMIN` or *Time Sheet Admin.* to anyone who should.

## 1.14.0.1

### Added

- `currencyCode` on `projects` (the Job's Currency Code; blank = local currency), read-only.
- Project-currency amounts on `timeEntries`: `unitCostProjectCurrency`, `totalCostProjectCurrency`,
  `unitPriceProjectCurrency` and `totalPriceProjectCurrency`, plus `currencyCode`. The existing
  `unitCost`, `totalCost`, `unitPrice` and `totalPrice` stay in local currency (LCY).
- Local-currency amounts on `jobPlanningLines`: `unitCostLCY`, `totalCostLCY`, `unitPriceLCY` and
  `totalPriceLCY` (read-only), plus `currencyCode`. The existing cost and price fields stay in the
  project currency.

### Fixed

- Planning lines created through `jobPlanningLines` on a project in another currency were priced
  in local currency but labelled with the project currency (BC only copies the project's currency
  onto a line when it's inserted, after the API has priced it). The currency is now set as soon as
  `jobNo` is applied, so the line is priced in the project currency.

This lets Thyme show a project priced in another currency (for example EUR in a GBP company) in
that currency, instead of labelling its prices with the company currency.

## 1.13.0.0

### Added

- Per-person billable target on Resource (`Thyme Billable Target %` with a `Thyme Billable Target Set`
  flag so "not set" is distinct from 0%), shown in a Thyme group on the Resource Card and exposed on
  the `resources` endpoint as `billableTargetPercent` and `billableTargetSet` (editable, 0-100).
- `Thyme Setup` single-record table and page with the company `Default Billable Target %` (75 by default),
  exposed on the new `thymeSetup` endpoint (read and update).
- `THYME ADMIN` permission set for changing Thyme Setup; `THYME USER` can read it.

## 1.12.0.0

### Added

- `timesheetReviews` and `timesheetReviewLines` endpoints for storing AI timesheet reviews
  (verdict, summary, and per-line findings). Deleting a review deletes its lines.
- `timeSuggestions` endpoint for AI time-entry suggestions (Pending, Accepted, Dismissed),
  with duplicate protection on resource, source, source reference and date.
- `THYME AI AGENT` and `THYME USER` permission sets for the extension's new tables.
