import type { NextRequest } from "next/server";

import type { TenantProfile } from "@/lib/tenants/types";

export function getTenantProfileFromRequest(
  request: NextRequest
): TenantProfile | null {
  const profile = request.headers.get("x-tenant-profile");

  if (profile === "PUBLIC" || profile === "PRIVATE") {
    return profile;
  }

  return null;
}
