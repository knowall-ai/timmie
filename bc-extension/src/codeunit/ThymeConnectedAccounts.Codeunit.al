/// <summary>
/// A person's connected accounts on their resource: their GitHub username, so the AI agent knows
/// whose GitHub activity is whose. (Their Azure DevOps user is their Microsoft 365 sign-in, which
/// the agent gets from the resource's time sheet owner, so it isn't stored.)
///
/// What's entered is normalised before it's stored: a GitHub profile URL or an @mention becomes
/// the login. Who may change it is checked by "Thyme Record Security" (a Thyme administrator for
/// anyone, a person for their own resource).
///
/// SetGitHubUsername is what the resources API's setGitHubUsername action calls. People often
/// have no permission to modify resources at all (the standard D365 permission sets give that to
/// few), so it writes the field through this codeunit's Permissions property, using the indirect
/// modify permission on Resource that THYME USER grants, after the row-level check. (Indirect
/// means only objects that declare it, like this one, can use it.) It modifies
/// without running the Resource's OnModify trigger, so nothing else (here or in other tables)
/// is touched.
/// </summary>
codeunit 50106 "Thyme Connected Accounts"
{
    Permissions = tabledata Resource = rm;

    var
        InvalidGitHubUsernameErr: Label '"%1" is not a valid GitHub username. Use the login from the person''s GitHub profile: letters, digits and single hyphens, not starting or ending with a hyphen, at most 39 characters.', Comment = '%1 = the value entered';
        GitHubUsernameCharsTok: Label 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-', Locked = true;
        GitHubHostTok: Label 'github.com/', Locked = true;
        WwwTok: Label 'www.', Locked = true;
        HttpsTok: Label 'https://', Locked = true;
        HttpTok: Label 'http://', Locked = true;

    /// <summary>
    /// Sets a resource's GitHub username (blank clears it). Errors if the caller may not change
    /// it or the value isn't a valid login; then nothing is changed.
    /// </summary>
    procedure SetGitHubUsername(ResourceNo: Code[20]; GitHubUsername: Text)
    var
        Resource: Record Resource;
        RecordSecurity: Codeunit "Thyme Record Security";
        NewGitHubUsername: Text;
    begin
        RecordSecurity.CheckCanEditConnectedAccounts(ResourceNo);
        // Normalise first, so a profile URL longer than the field still fits
        NewGitHubUsername := NormaliseGitHubUsername(GitHubUsername);
        Resource.Get(ResourceNo);
        Resource.Validate("Thyme GitHub Username", CopyStr(NewGitHubUsername, 1, MaxStrLen(Resource."Thyme GitHub Username")));
        Resource.Modify(false);
    end;

    /// <summary>
    /// A GitHub login from what was entered: trimmed, without a leading @ or a github.com profile
    /// URL around it. Blank stays blank. Errors unless it is a valid login (letters, digits and
    /// single hyphens, no leading or trailing hyphen, 1 to 39 characters).
    /// </summary>
    procedure NormaliseGitHubUsername(Value: Text): Text
    var
        Entered: Text;
    begin
        Entered := Value.Trim();
        Value := StripGitHubProfileUrl(Entered);
        if Value = '' then
            exit('');
        Value := Value.TrimEnd('/').TrimStart('@');
        if (Value = '') or (StrLen(Value) > 39) or (DelChr(Value, '=', GitHubUsernameCharsTok) <> '') or
           Value.StartsWith('-') or Value.EndsWith('-') or Value.Contains('--')
        then
            Error(InvalidGitHubUsernameErr, Entered);
        exit(Value);
    end;

    /// <summary>
    /// The part after "github.com/" when the value is a GitHub profile URL (https://, http://,
    /// www. or no scheme), otherwise the value unchanged. Only a URL that starts with the GitHub
    /// host counts, so another host that merely contains "github.com/" isn't mistaken for one.
    /// </summary>
    local procedure StripGitHubProfileUrl(Value: Text): Text
    var
        Rest: Text;
    begin
        Rest := Value;
        if LowerCase(Rest).StartsWith(HttpsTok) then
            Rest := CopyStr(Rest, StrLen(HttpsTok) + 1)
        else
            if LowerCase(Rest).StartsWith(HttpTok) then
                Rest := CopyStr(Rest, StrLen(HttpTok) + 1);
        if LowerCase(Rest).StartsWith(WwwTok) then
            Rest := CopyStr(Rest, StrLen(WwwTok) + 1);
        if LowerCase(Rest).StartsWith(GitHubHostTok) then
            exit(CopyStr(Rest, StrLen(GitHubHostTok) + 1));
        exit(Value);
    end;
}
