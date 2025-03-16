Here is a set of rules to guide an LLM when implementing multi-tenancy from scratch in a Ruby on Rails application, drawing on the provided sources:

**I. Multi-Tenant Data Modeling:**

*   **Default to a single, shared database unless there's an exceptional need for database per user or separate schemas**. The single database approach with tenant identification is the most common.
*   **Identify the top-level tenant model.** The source recommends using "Organization" as a general term. Other options like "Account", "Team", "Company", "Tenant", or "Workspace" might be considered, but "Organization" is preferred for its generality, allowing for the later addition of Teams and Workspaces within it.
*   **Associate every database table (except possibly the users table) with the top-level tenant (e.g., Organization) by adding an `organization_id` column**.
*   **Scope all database reads and writes to a specific `organization_id`**. This is crucial for data isolation between tenants.
*   **Use loose enforcement for enforcing the association:**
    *   **Loose Enforcement:** Keep `id` as the primary key and add `organization_id` as a separate indexed foreign key. Implement an access layer in the code that requires providing `organization_id` for each query to prevent accidental unscoped queries.
*   **Model user association with organizations through a Membership model**. This model should include:
    *   `user_id` (foreign key to the User model)
    *   `organization_id` (foreign key to the Organization model, cannot be null)
    *   `role` (to define the user's access level within the organization).
    *   `invited_by_id` (optional foreign key to the User model who sent the invitation).
*   **Assign items (resources) within an organization to a user's Membership, not directly to the User**. This allows assigning items to users even before they accept an invitation. Remember that these items should still belong to an organization via `organization_id`.
*   **For new user sign-up, create a User, an Organization, and a Membership linking them together**.
*   **For inviting a user to an existing organization, create a new Membership linked to the Organization with `user_id` set to null initially.** Use fields like `invitationId`, `invitationExpiresAt`, and `invitedEmail` in the Membership model to manage the invitation process. When the user signs up using the invitation link, create the User and associate it with the existing Membership.
*   **To revoke a user's access to an organization, either set `membership.user_id` to null or delete the Membership record entirely**. Consider keeping the Membership with a null `user_id` if you need to track past access.

**II. User Management and Access Models:**

*   **Choose the Linear access model for how users interact with organizations**. A single user account can have access to multiple organizations, and a user can have multiple accounts each with different organization access. Recommended for most B2B startups as it combines the flexibility of both other models.
*   **Treat personal accounts as just Organizations with a single user**. This simplifies implementation and allows for easy upgrades to business accounts.
*   **Implement Role-Based Access Control (RBAC) using the `role` field in the Membership model**. Store the user's `role` in the session to avoid frequent database lookups. Define permissions for each `role` and enforce these permissions on both the client and server.

**III. User Login Sessions:**

*   **Implement "concurrent user sessions" for the best user experience**, allowing users to be simultaneously logged into multiple organizations with multiple identities without needing to log out.
*   **Store the following in the user session:**
    *   `accessible_orgs: Array<{orgId: string, role: string}>`: A list of all organizations the user has a membership to, along with their role in each. This should be synced across all the user's devices/sessions.
    *   `loggedInOrgsOnThisDevice: Array<{orgId: string}>`: A list of organizations the user is currently actively logged into on the current device. This should not be synced across devices.
*   **On the first login on a device:**
    *   Set `accessible_orgs` to the list of all their organization memberships.
    *   Set `loggedInOrgsOnThisDevice` to the same list, but filtered by organizations that permit access with the current login method (e.g., email/password or social login).
*   **Allow users to log into additional organizations through an "organization switcher":**
    *   Add the new `org_id` to `accessible_orgs` (if it's not already there) and to `loggedInOrgsOnThisDevice`.
*   **Enforce that each device must independently log in to the organizations it wants to access** by not syncing `loggedInOrgsOnThisDevice`.

**IV. General Implementation Considerations:**

*   **Include the `organization_id` everywhere it's relevant, including in URLs** (e.g., `/org/[orgId]/projects/[projectId]`), query inputs, and mutation inputs. While it might seem less aesthetically pleasing, it avoids extra database calls to determine the current organization and user role. Consider alternative URL strategies like custom subdomains or domains as well.
*   **Billing and subscriptions should belong to the Organization**. Store billing-related information (e.g., `billing_email`, `stripe_customer_id`) on the Organization model. Track per-user charges by counting the Memberships within an organization.
*   **Manage settings at three levels:**
    *   Organization settings stored on the Organization model.
    *   User settings per organization stored on the Membership model (e.g., notifications).
    *   Global user settings stored on the User model (e.g., dark mode).
*   **For analytics in multi-tenant systems, utilize the concept of "groups" provided by most analytics providers**. Map the `Organization` to the "group" and associate user events with the corresponding `organization_id` (or "groupId"). This enables accurate organization-level analytics.
*   **Consider advanced features like Organization Types** (e.g., households vs. businesses) and **Parent/Child Organizations** if your application's domain requires it.
*   **When developing, prioritize building "teams" (or the chosen top-level tenant functionality) from day one** as adding it later can be complex and painful.

By following these rules, an LLM can be guided to implement a robust and well-structured multi-tenant Ruby on Rails application from scratch. Remember that these guidelines are based on the provided sources and may need to be adapted based on the specific requirements of the application being built.
