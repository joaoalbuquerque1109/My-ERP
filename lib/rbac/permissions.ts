export const Permissions = {
  BillingRead: "billing.read",
  BillingWrite: "billing.write",
  BudgetRead: "budget.read",
  BudgetWrite: "budget.write",
  HrRead: "hr.read",
  HrWrite: "hr.write",
} as const;

export type PermissionCode = (typeof Permissions)[keyof typeof Permissions];
