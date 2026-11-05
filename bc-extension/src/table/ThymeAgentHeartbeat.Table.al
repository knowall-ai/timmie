/// <summary>
/// When an AI agent was last seen, so Thyme can tell people whether the agent is online
/// before they ask it for something (e.g. a suggestion request). One record per agent,
/// written by the agent on every poll; Last Seen At is stamped by BC, so the agent's clock
/// doesn't matter.
/// </summary>
table 50105 "Thyme Agent Heartbeat"
{
    Caption = 'Thyme Agent Heartbeat';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Agent Name"; Code[50])
        {
            Caption = 'Agent Name';
        }
        field(2; "Last Seen At"; DateTime)
        {
            Caption = 'Last Seen At';
        }
        // e.g. "Idle", "Working on 1 request", "Paused"
        field(3; Status; Text[250])
        {
            Caption = 'Status';
        }
        field(4; Version; Text[50])
        {
            Caption = 'Version';
        }
    }

    keys
    {
        key(PK; "Agent Name")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Agent Name");
        "Last Seen At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        "Last Seen At" := CurrentDateTime();
    end;
}
