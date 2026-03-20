// AWS IAM Data Loader for Neo4j
// Updated for latest AWS IAM API and Neo4j Cypher features
// Supports PermissionsBoundary, Tags, inline policies, RoleLastUsed, etc.

// Note: Update the file path below to match your environment
// For Windows, use file:///C:/path/to/account_auth.json
// For Unix/Linux, use file:///path/to/account_auth.json

// LOAD MANAGED POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.Policies[*]') YIELD value as row
CALL {
    WITH row
    MERGE (p:IAM_Policy {
        arn: row.Arn,
        name: row.PolicyName,
        id: row.PolicyId
    })
    SET p.path = row.Path,
        p.description = row.Description,
        p.createDate = row.CreateDate,
        p.updateDate = row.UpdateDate,
        p.isAttachable = row.IsAttachable,
        p.attachmentCount = row.AttachmentCount,
        p.permissionsBoundaryUsageCount = row.PermissionsBoundaryUsageCount
} IN TRANSACTIONS OF 1000 ROWS;

// LOAD GROUPS
CALL apoc.load.json("file:///path/to/account_auth.json", '.GroupDetailList[*]') YIELD value as row
CALL {
    WITH row
    MERGE (g:IAM_Group {
        arn: row.Arn,
        name: row.GroupName,
        id: row.GroupId
    })
    SET g.path = row.Path,
        g.createDate = row.CreateDate
} IN TRANSACTIONS OF 1000 ROWS;

// LOAD USERS
CALL apoc.load.json("file:///path/to/account_auth.json", '.UserDetailList[*]') YIELD value as row
CALL {
    WITH row
    MERGE (u:IAM_User {
        arn: row.Arn,
        name: row.UserName,
        id: row.UserId
    })
    SET u.path = row.Path,
        u.createDate = row.CreateDate
} IN TRANSACTIONS OF 1000 ROWS;

// LOAD ROLES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
CALL {
    WITH row
    MERGE (r:IAM_Role {
        arn: row.Arn,
        name: row.RoleName,
        id: row.RoleId
    })
    SET r.path = row.Path,
        r.createDate = row.CreateDate,
        r.description = row.Description,
        r.maxSessionDuration = row.MaxSessionDuration,
        r.assumeRolePolicyDocument = row.AssumeRolePolicyDocument
} IN TRANSACTIONS OF 1000 ROWS;

// LOAD INSTANCE PROFILES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*].InstanceProfileList[*]') YIELD value as row
CALL {
    WITH row
    MERGE (ip:IAM_InstanceProfile {
        arn: row.Arn,
        name: row.InstanceProfileName,
        id: row.InstanceProfileId
    })
    SET ip.path = row.Path,
        ip.createDate = row.CreateDate
} IN TRANSACTIONS OF 1000 ROWS;

// RELATE ROLES TO INSTANCE PROFILES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
UNWIND row.InstanceProfileList as ip
MATCH (r:IAM_Role {name: row.RoleName})
MATCH (iprofile:IAM_InstanceProfile {name: ip.InstanceProfileName})
MERGE (iprofile)-[:ASSOCIATED_WITH]->(r);

// LOAD USER INLINE POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.UserDetailList[*]') YIELD value as row
UNWIND row.UserPolicyList as policy
MATCH (u:IAM_User {name: row.UserName})
MERGE (p:IAM_InlinePolicy {
    name: policy.PolicyName,
    document: policy.PolicyDocument,
    type: 'User'
})
MERGE (u)-[:HAS_INLINE_POLICY]->(p);

// LOAD GROUP INLINE POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.GroupDetailList[*]') YIELD value as row
UNWIND row.GroupPolicyList as policy
MATCH (g:IAM_Group {name: row.GroupName})
MERGE (p:IAM_InlinePolicy {
    name: policy.PolicyName,
    document: policy.PolicyDocument,
    type: 'Group'
})
MERGE (g)-[:HAS_INLINE_POLICY]->(p);

// LOAD ROLE INLINE POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
UNWIND row.RolePolicyList as policy
MATCH (r:IAM_Role {name: row.RoleName})
MERGE (p:IAM_InlinePolicy {
    name: policy.PolicyName,
    document: policy.PolicyDocument,
    type: 'Role'
})
MERGE (r)-[:HAS_INLINE_POLICY]->(p);

// LOAD USER ATTACHED MANAGED POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.UserDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
MATCH (u:IAM_User {name: row.UserName})
MATCH (p:IAM_Policy {name: policy.PolicyName})
MERGE (u)-[:HAS_MANAGED_POLICY]->(p);

// LOAD GROUP ATTACHED MANAGED POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.GroupDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
MATCH (g:IAM_Group {name: row.GroupName})
MATCH (p:IAM_Policy {name: policy.PolicyName})
MERGE (g)-[:HAS_MANAGED_POLICY]->(p);

// LOAD ROLE ATTACHED MANAGED POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
MATCH (r:IAM_Role {name: row.RoleName})
MATCH (p:IAM_Policy {name: policy.PolicyName})
MERGE (r)-[:HAS_MANAGED_POLICY]->(p);

// LOAD USER GROUP MEMBERSHIPS
CALL apoc.load.json("file:///path/to/account_auth.json", '.UserDetailList[*]') YIELD value as row
UNWIND row.GroupList as groupName
MATCH (u:IAM_User {name: row.UserName})
MATCH (g:IAM_Group {name: groupName})
MERGE (u)-[:MEMBER_OF]->(g);

// LOAD PERMISSIONS BOUNDARIES FOR USERS
CALL apoc.load.json("file:///path/to/account_auth.json", '.UserDetailList[*]') YIELD value as row
WHERE row.PermissionsBoundary IS NOT NULL
MATCH (u:IAM_User {name: row.UserName})
MERGE (pb:IAM_PermissionsBoundary {
    type: row.PermissionsBoundary.PermissionsBoundaryType,
    arn: row.PermissionsBoundary.PermissionsBoundaryArn
})
MERGE (u)-[:HAS_PERMISSIONS_BOUNDARY]->(pb);

// LOAD PERMISSIONS BOUNDARIES FOR ROLES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
WHERE row.PermissionsBoundary IS NOT NULL
MATCH (r:IAM_Role {name: row.RoleName})
MERGE (pb:IAM_PermissionsBoundary {
    type: row.PermissionsBoundary.PermissionsBoundaryType,
    arn: row.PermissionsBoundary.PermissionsBoundaryArn
})
MERGE (r)-[:HAS_PERMISSIONS_BOUNDARY]->(pb);

// LOAD TAGS FOR USERS
CALL apoc.load.json("file:///path/to/account_auth.json", '.UserDetailList[*]') YIELD value as row
UNWIND row.Tags as tag
MATCH (u:IAM_User {name: row.UserName})
MERGE (t:IAM_Tag {key: tag.Key, value: tag.Value})
MERGE (u)-[:HAS_TAG]->(t);

// LOAD TAGS FOR ROLES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
UNWIND row.Tags as tag
MATCH (r:IAM_Role {name: row.RoleName})
MERGE (t:IAM_Tag {key: tag.Key, value: tag.Value})
MERGE (r)-[:HAS_TAG]->(t);

// LOAD TAGS FOR INSTANCE PROFILES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*].InstanceProfileList[*]') YIELD value as row
UNWIND row.Tags as tag
MATCH (ip:IAM_InstanceProfile {name: row.InstanceProfileName})
MERGE (t:IAM_Tag {key: tag.Key, value: tag.Value})
MERGE (ip)-[:HAS_TAG]->(t);

// LOAD ROLE LAST USED
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
WHERE row.RoleLastUsed IS NOT NULL
MATCH (r:IAM_Role {name: row.RoleName})
MERGE (rlu:IAM_RoleLastUsed {
    lastUsedDate: row.RoleLastUsed.LastUsedDate,
    region: row.RoleLastUsed.Region
})
MERGE (r)-[:LAST_USED]->(rlu);

// LOAD POLICY ACTIONS AND RESOURCES FROM MANAGED POLICIES
CALL apoc.load.json("file:///path/to/account_auth.json") YIELD value as row
UNWIND row.Policies as p
UNWIND p.PolicyVersionList as v
WHERE v.IsDefaultVersion = true
WITH p, v
CALL apoc.convert.fromJsonMap(v.Document) YIELD value as doc
UNWIND doc.Statement as stmt
WITH p, stmt
UNWIND stmt.Action as action
MATCH (pol:IAM_Policy {name: p.PolicyName})
MERGE (a:IAM_PolicyAction {action: action})
MERGE (pol)-[:HAS_ACTION]->(a)
WITH pol, stmt
WHERE stmt.Resource IS NOT NULL
UNWIND stmt.Resource as resource
MERGE (res:IAM_PolicyResource {resource: resource})
MERGE (pol)-[:HAS_RESOURCE]->(res);

// LOAD SERVICES THAT CAN ASSUME ROLES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
CALL apoc.convert.fromJsonMap(row.AssumeRolePolicyDocument) YIELD value as doc
UNWIND doc.Statement as stmt
WHERE stmt.Effect = 'Allow'
WITH stmt, row
UNWIND keys(stmt.Principal) as key
WHERE key = 'Service'
WITH row, stmt.Principal[key] as serviceName
MATCH (r:IAM_Role {name: row.RoleName})
MERGE (s:AWS_Service {name: serviceName})
MERGE (s)-[:CAN_ASSUME_ROLE]->(r);

// LOAD AWS PRINCIPALS THAT CAN ASSUME ROLES
CALL apoc.load.json("file:///path/to/account_auth.json", '.RoleDetailList[*]') YIELD value as row
CALL apoc.convert.fromJsonMap(row.AssumeRolePolicyDocument) YIELD value as doc
UNWIND doc.Statement as stmt
WHERE stmt.Effect = 'Allow'
WITH stmt, row
UNWIND keys(stmt.Principal) as key
WHERE key = 'AWS'
WITH row, stmt.Principal[key] as principalArn
MATCH (r:IAM_Role {name: row.RoleName})
MERGE (pr:IAM_Principal {arn: principalArn})
MERGE (pr)-[:CAN_ASSUME_ROLE]->(r);
