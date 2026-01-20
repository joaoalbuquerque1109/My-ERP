export type TenantProfile = "PRIVATE" | "PUBLIC";

export type TenantModule = {
  code: string;
  label: string;
  profile: TenantProfile;
};
