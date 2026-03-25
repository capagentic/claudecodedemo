// ============================================================
// FILE:         SiteRegisterController.cls
// ============================================================
// PURPOSE:
//   Apex controller for the Salesforce Customer/Experience Site
//   self-registration page. Validates submitted credentials and
//   creates a new portal user linked to a pre-configured Account,
//   then logs the user in or redirects to a confirmation page.
//
// BUSINESS REQUIREMENT:
//   To be confirmed
//
// CHANGE HISTORY:
//   Date          Author              Description
//   ----------    ----------------    ----------------------------
//   2026-03-25    Unknown             Initial creation
//
// CONSIDERATIONS:
//   - Security/compliance: PORTAL_ACCOUNT_ID is hardcoded as a
//     static literal — rotate or parameterise this value before
//     deploying to production. Passwords are handled in-memory
//     only and never persisted by this class; however, they are
//     passed in plaintext to Site.createPortalUser and Site.login,
//     so HTTPS must be enforced at the Site level.
//   - The Account owner must be present in the role hierarchy for
//     portal user creation to succeed (see Salesforce Customer
//     Portal Setup documentation).
//   - If no password is supplied, Site.createPortalUser generates
//     a random one and emails it to the user — the registration
//     flow then redirects to SiteRegisterConfirm rather than
//     performing an immediate login.
//   - lastName is a required User field; callers must ensure the
//     User object is populated appropriately before submission, or
//     Salesforce will default it to the username value.
//   - Technical debt: PORTAL_ACCOUNT_ID should be sourced from a
//     Custom Metadata Type or Custom Setting rather than a hardcoded
//     constant to support environment-specific deployments.
// ============================================================

/**
 * Controller for the Experience/Community Site self-registration page.
 * Handles credential validation, portal user creation, and post-registration
 * navigation (immediate login or confirmation-page redirect).
 */
public with sharing class SiteRegisterController {

    // The Account under which new portal Contacts are created.
    // NOTE: The Account owner must be in the role hierarchy for this to work.
    // TODO: Replace with a Custom Metadata / Custom Setting lookup before go-live.
    private static Id PORTAL_ACCOUNT_ID = '001x000xxx35tPN';

    public SiteRegisterController () {
    }

    // ---------------------------------------------------------
    // Page properties — bound to the Visualforce registration form
    // ---------------------------------------------------------

    /** The unique Salesforce username for the new portal user. */
    public String username {get; set;}

    /** Email address of the registering user. */
    public String email {get; set;}

    /** Password chosen by the user. Whitespace is trimmed on set. */
    public String password {get; set {password = value == null ? value : value.trim(); } }

    /** Re-entered password for confirmation. Whitespace is trimmed on set. */
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }

    /** Display nickname shown in the community. Whitespace is trimmed on set. */
    public String communityNickname {get; set { communityNickname = value == null ? value : value.trim(); } }

    // ---------------------------------------------------------
    // Private helpers
    // ---------------------------------------------------------

    /**
     * Returns true when password and confirmPassword match exactly.
     * A null password is considered valid here because Site.createPortalUser
     * will generate a random password when none is provided.
     */
    private boolean isValidPassword() {
        return password == confirmPassword;
    }

    // ---------------------------------------------------------
    // Actions
    // ---------------------------------------------------------

    /**
     * Validates the submitted form, creates a portal user, and navigates
     * the user to their next destination:
     *   - If a password was supplied → logs the user in immediately.
     *   - If no password was supplied → redirects to SiteRegisterConfirm
     *     so the user can check their email for a system-generated password.
     *
     * Returns null (stays on the current page) when validation fails or
     * user creation is unsuccessful.
     */
    public PageReference registerUser() {

        // Abort early if the two password fields do not match.
        if (!isValidPassword()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.site.passwords_dont_match);
            ApexPages.addMessage(msg);
            return null;
        }

        // Build a minimal User record. Note: lastName is required by Salesforce;
        // ensure the calling page populates it, otherwise the platform defaults
        // it to the username value.
        User u = new User();
        u.Username = username;
        u.Email = email;
        u.CommunityNickname = communityNickname;

        String accountId = PORTAL_ACCOUNT_ID;

        // Attempt to create the portal user. Returns the new User Id on success,
        // or null if creation failed (e.g. duplicate username, missing fields).
        String userId = Site.createPortalUser(u, accountId, password);

        if (userId != null) {
            if (password != null && password.length() > 1) {
                // Password provided — log the user in and redirect to the
                // post-login start page defined on the Site configuration.
                return Site.login(username, password, null);
            } else {
                // No password provided — a random one was emailed to the user.
                // Redirect to the confirmation page so they know to check email.
                PageReference page = System.Page.SiteRegisterConfirm;
                page.setRedirect(true);
                return page;
            }
        }

        // User creation failed silently; stay on the registration page.
        return null;
    }
}