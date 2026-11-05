/// <summary>
/// Custom API page for AI agent heartbeats. The agent creates its record once and PATCHes
/// it on every poll, sending its own lastSeenAt (so the record always changes); BC stamps
/// lastSeenAt with the server time either way. Thyme reads it to show
/// whether the agent is online and to disable requests while it isn't.
///
///   GET   .../agentHeartbeats                         (Thyme: every agent, newest lastSeenAt wins)
///   POST  .../agentHeartbeats  { "agentName": "POPPIE", "status": "Idle" }
///   PATCH .../agentHeartbeats({id})  { "lastSeenAt": "<now>", "status": "Working on 1 request" }  (If-Match)
///
/// Readable by every Thyme user; only the AI agent (THYME AI AGENT) can write.
///
/// Endpoint: /api/knowall/thyme/v1.0/companies({companyId})/agentHeartbeats
/// </summary>
page 50115 "Thyme Agent Heartbeats API"
{
    APIGroup = 'thyme';
    APIPublisher = 'knowall';
    APIVersion = 'v1.0';
    EntityName = 'agentHeartbeat';
    EntitySetName = 'agentHeartbeats';
    EntityCaption = 'Agent Heartbeat';
    EntitySetCaption = 'Agent Heartbeats';
    PageType = API;
    SourceTable = "Thyme Agent Heartbeat";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Extensible = false;

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
                field(agentName; Rec."Agent Name")
                {
                    Caption = 'Agent Name';
                }
                // The agent sends its own time so every PATCH changes the record; BC replaces it
                // with the server time on insert and modify.
                field(lastSeenAt; Rec."Last Seen At")
                {
                    Caption = 'Last Seen At';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(version; Rec.Version)
                {
                    Caption = 'Version';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteHeartbeat();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteHeartbeat();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RecordSecurity: Codeunit "Thyme Record Security";
    begin
        RecordSecurity.CheckCanWriteHeartbeat();
        exit(true);
    end;
}
