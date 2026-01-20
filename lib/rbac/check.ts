import type { PermissionCode } from "./permissions";

type AccessContext = {
  permissionCodes: PermissionCode[];
};

export function hasPermission(
  context: AccessContext,
  permission: PermissionCode
): boolean {
  return context.permissionCodes.includes(permission);
}
