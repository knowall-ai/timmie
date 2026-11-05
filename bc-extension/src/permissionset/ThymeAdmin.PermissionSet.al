/// <summary>
/// For Thyme administrators: everything in THYME USER, plus changing the company-wide
/// Thyme settings (the default billable target) through the thymeSetup API or the
/// Thyme Setup page. Per-person billable targets are Resource fields, so editing them
/// needs modify permission on Resource from the standard D365 permission sets.
/// Thyme administrators may also write AI plan reviews, their findings and proposed changes
/// (CheckCanWritePlanReviews): indirect only, so through the plan review API pages.
/// </summary>
permissionset 50102 "THYME ADMIN"
{
    Assignable = true;
    Caption = 'Thyme Admin';
    IncludedPermissionSets = "THYME USER";

    Permissions =
        tabledata "Thyme Setup" = RIM,
        tabledata "Thyme Plan Review" = imd,
        tabledata "Thyme Plan Review Line" = imd,
        tabledata "Thyme Plan Review Change" = imd,
        page "Thyme Setup" = X;
}
