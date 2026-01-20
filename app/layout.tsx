import type { ReactNode } from "react";

import "./globals.css";

export const metadata = {
  title: "My-ERP",
  description: "ERP híbrido multi-tenant (PRIVATE/PUBLIC).",
};

type RootLayoutProps = {
  children: ReactNode;
};

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
