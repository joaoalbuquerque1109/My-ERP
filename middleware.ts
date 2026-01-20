import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

import { getTenantProfileFromRequest } from "@/lib/auth/session";

const PUBLIC_ROUTES = new Set<string>(["/forbidden"]);

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const tenantProfile = getTenantProfileFromRequest(request);

  if (PUBLIC_ROUTES.has(pathname)) {
    return NextResponse.next();
  }

  if (!tenantProfile) {
    return NextResponse.redirect(new URL("/forbidden", request.url));
  }

  if (tenantProfile === "PUBLIC" && pathname.startsWith("/private")) {
    return NextResponse.redirect(new URL("/forbidden", request.url));
  }

  if (tenantProfile === "PRIVATE" && pathname.startsWith("/public")) {
    return NextResponse.redirect(new URL("/forbidden", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/public/:path*", "/private/:path*", "/forbidden"],
};
